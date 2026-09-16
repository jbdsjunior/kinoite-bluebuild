# Guia de Configuração: Atualizações Push Instantâneas via Tailscale (FCM-style)

Este guia documenta o passo a passo completo para configurar o mecanismo de atualização **Push em Tempo Real** do Kinoite BlueBuild utilizando **Tailscale** e **Systemd Socket Activation**.

O sistema opera com **0 MB de RAM e 0% de CPU em repouso**, acordando apenas no instante em que o GitHub Actions conclui a compilação e a assinatura de uma nova imagem do sistema operacional.

---

## Índice

1. [Coexistência com o Método Antigo (Fallback de Segurança)](#1-coexistência-com-o-método-antigo-fallback-de-segurança)
2. [Passo 1: Configuração no Admin Console da Tailscale](#passo-1-configuração-no-admin-console-da-tailscale)
3. [Passo 2: Configuração na Máquina Local (Fedora Kinoite)](#passo-2-configuração-na-máquina-local-fedora-kinoite)
4. [Passo 3: Configuração dos Secrets no GitHub](#passo-3-configuração-dos-secrets-no-github)
5. [Passo 4: Teste e Validação da Esteira](#passo-4-teste-e-validação-da-esteira)
6. [Passo 5: Desativação do Método Antigo (Quando Estiver Pronto)](#passo-5-desativação-do-método-antigo-quando-estiver-pronto)

---

## 1. Coexistência com o Método Antigo (Fallback de Segurança)

> [!IMPORTANT]
> **O método de atualização tradicional NÃO foi desativado nem removido.**
>
> A unidade de timer periódica `bootc-fetch-apply-updates.timer` continua ativa e configurada por padrão em `recipes/common-systemd.yml`.
>
> - **Se o Push funcionar:** O sistema atualiza no exato minuto em que a imagem do GitHub Actions é publicada.
> - **Se o Push falhar ou o dispositivo estiver offline no momento do build:** O timer tradicional (`bootc-fetch-apply-updates.timer`) verifica e baixa a atualização na próxima janela programada (a cada 45 minutos).
>
> Ambos os métodos trabalham harmonicamente sem conflitos de concorrência. Você só deve desativar o timer periódico quando testar e validar o funcionamento completo da solução Push.

---

## Passo 1: Configuração no Admin Console da Tailscale

Para que o GitHub Actions consiga acessar seu dispositivo de forma segura via malha WireGuard sem expor portas para a internet pública, utilizaremos uma máquina efêmera autenticada com tag `tag:ci`.

### 1.1 Definir a Tag na ACL do Tailscale

1. Acesse o [Tailscale Admin Console > Access Controls](https://login.tailscale.com/admin/acls).
2. Adicione a tag `tag:ci` na seção `tagOwners` do seu JSON de ACLs:

```json
{
  "tagOwners": {
    "tag:ci": ["autogroup:admin"]
  }
}
```

3. Clique em **Save**.

### 1.2 Gerar Credenciais de Acesso (OAuth Client Recomendado vs Auth Key)

A Tailscale recomenda oficialmente o uso de **OAuth API Clients** para GitHub Actions, pois eles nunca expiram e criam conexões efêmeras automaticamente sob demanda.

#### Opção A (Recomendada pela Tailscale): OAuth API Client

1. Acesse [Tailscale Admin Console > Settings > OAuth clients](https://login.tailscale.com/admin/settings/oauth) (ou [tailscale.com/s/oauth-clients](https://tailscale.com/s/oauth-clients)).
2. Clique em **Generate OAuth client...**.
3. Configure:
   - **Description:** `GitHub Actions CI Update Trigger`
   - **Scopes:** Em **Devices**, marque **Write** (para criar nós efêmeros na rede).
   - **Tags:** Selecione `tag:ci`.
4. Clique em **Generate client**.
5. Guarde o **Client ID** e o **Client Secret** gerados (`tskey-client-...`).

#### Opção B (Alternativa): Auth Key Efêmera

1. Acesse [Tailscale Admin Console > Settings > Keys](https://login.tailscale.com/admin/settings/keys).
2. Clique em **Generate auth key...**.
3. Marque **Reusable: ON**, **Ephemeral: ON**, **Pre-authorized: ON** e adicione a tag `tag:ci`.
4. _Nota:_ A Tailscale exibirá um aviso no log do GitHub Actions recomendando a migração para OAuth Client, e chaves de autenticação expiram periodicamente (máximo de 90 dias a 1 ano).

---

## Passo 2: Configuração na Máquina Local (Fedora Kinoite)

Incluímos um assistente automatizado que cuida de toda a configuração local.

### Opção A: Executar o comando nativo do sistema (na nova imagem)

```bash
sudo kinoite-setup-push-update
```

### Opção B: Executar pelo repositório clonado (no sistema atual)

```bash
sudo ./scripts/setup-push-update.sh
```

### O que o assistente faz:

1. Gera uma chave criptográfica de 256 bits em `/etc/kinoite-update.secret` com permissão restrita `0400` (leitura apenas pelo root).
2. Detecta a conectividade da Tailscale e seu endereço IP/DNS.
3. Habilita e ativa o socket `kinoite-update-trigger.socket` na porta `58080`.
4. Executa um teste local de autenticação HMAC via loopback.
5. Exibe na tela os valores formatados prontos para copiar para o GitHub.

---

## Passo 3: Configuração dos Secrets no GitHub

No repositório do projeto no GitHub:

1. Acesse **Settings** > **Secrets and variables** > **Actions**.
2. Na seção **Repository secrets**, clique em **New repository secret** e adicione as 3 variáveis:

| Nome do Secret                           | Valor                               | Exemplo / Descrição                                                        |
| :--------------------------------------- | :---------------------------------- | :------------------------------------------------------------------------- |
| **`TS_OAUTH_CLIENT_ID`** _(Recomendado)_ | Client ID do OAuth Tailscale        | Obtido em Settings > OAuth clients. Não expira.                            |
| **`TS_OAUTH_SECRET`** _(Recomendado)_    | Client Secret do OAuth Tailscale    | `tskey-client-...`. Não expira e elimina avisos no CI.                     |
| **`TAILSCALE_AUTHKEY`** _(Alternativa)_  | `tskey-auth-...`                    | Chave efêmera manual (expira periodicamente).                              |
| **`UPDATE_HMAC_SECRET`**                 | Chave de 64 caracteres hexadecimais | O valor gerado em `/etc/kinoite-update.secret` (mostrado pelo assistente). |
| **`UPDATE_RECEIVER_URL`**                | `http://<IP-TAILSCALE>:58080`       | URL do seu dispositivo na rede Tailscale, ex: `http://100.x.y.z:58080`.    |

> [!NOTE]
> Você pode usar o par **OAuth** (`TS_OAUTH_CLIENT_ID` e `TS_OAUTH_SECRET`) **OU** a chave **`TAILSCALE_AUTHKEY`**.
> Se utilizar o OAuth Client, nenhum aviso será gerado no GitHub Actions e você não precisará renovar chaves periodicamente.
> Se os secrets não estiverem configurados, o passo de notificação é pulado com segurança sem quebrar o build.

---

## Passo 4: Teste e Validação da Esteira

### 4.1 Teste Manual Local via Terminal

Você pode disparar um teste diretamente de outra máquina na sua rede Tailscale (ou localmente):

```bash
SECRET=$(sudo cat /etc/kinoite-update.secret)
TIMESTAMP=$(date +%s)
PAYLOAD="{\"timestamp\": $TIMESTAMP, \"test\": true}"
SIG=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | cut -d' ' -f2)

curl -i -X POST http://127.0.0.1:58080 \
  -H "Content-Type: application/json" \
  -H "X-Signature: $SIG" \
  -H "X-Timestamp: $TIMESTAMP" \
  -d "$PAYLOAD"
```

**Resposta esperada:** `HTTP/1.1 200 OK` e notificação instantânea do KDE Plasma no canto da tela!

### 4.2 Monitorar os Logs do Receptor em Tempo Real

```bash
journalctl -u "kinoite-update-trigger@*" -f
```

### 4.3 Teste Integrado com o GitHub Actions

1. No GitHub, acesse a aba **Actions**.
2. Selecione o workflow **build-amd**.
3. Clique em **Run workflow** na branch `main`.
4. Acompanhe a execução do job `Notify Tailscale Device (Push)`:
   - Ele conecta à sua Tailnet em poucos segundos.
   - Envia a requisição autenticada com HMAC-SHA256 para `http://<seu-ip>:58080`.
   - Seu desktop recebe a notificação visual e aciona o download do `bootc`.

---

## Passo 5: Desativação do Método Antigo (Quando Estiver Pronto)

Somente após validar que o fluxo do GitHub Actions entrega as notificações push com sucesso, você pode opcionalmente desligar o timer de polling a cada 45 minutos.

### Para desativar o timer periódico antigo:

```bash
sudo systemctl disable --now bootc-fetch-apply-updates.timer
```

### Para reativar o timer a qualquer momento (caso precise):

```bash
sudo systemctl enable --now bootc-fetch-apply-updates.timer
```

### Como verificar o status dos dois métodos:

```bash
# Verificar o receptor Push (deve estar 'active (listening)' com 0 MB de memória):
systemctl status kinoite-update-trigger.socket

# Verificar o timer periódico antigo:
systemctl status bootc-fetch-apply-updates.timer
```
