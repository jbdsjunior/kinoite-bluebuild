# Guia Oficial: Configuração de OAuth 2.0 Próprio para Google Drive no Rclone

Este documento detalha o procedimento arquitetural e operacional para provisionar, autorizar e manter um **Client ID e Client Secret dedicados** no Google Cloud Platform para montagens FUSE e sincronização do Google Drive via Rclone no Fedora Kinoite.

---

## 1. Por que Criar um Aplicativo Próprio?

| Característica | Client ID Público Padrão (Compartilhado) | Client ID Próprio Publicado (Recomendado) |
| :--- | :--- | :--- |
| **Cota de Requisições** | Compartilhada com milhares de usuários globais | **20.000 requisições / 100s exclusivas** |
| **Erros 403 Rate Limit** | Frequentes (`RATE_LIMIT_EXCEEDED`) sob pico | **Zero erros** de limite de taxa |
| **Latência do Pacer** | Escala para 16s–32s de sono forçado | Latência mínima constante (**10ms**) |
| **Tempo de Exclusão/Listagem** | 30s a 50s por arquivo | **0.00s a 0.39s** (sub-segundo) |
| **Longevidade da Conexão** | **Descontinuação programada pelo Google em 2026** | **Permanente e sob controle do usuário** |
| **Validade do Token** | Permanente (enquanto o client_id público existir) | **Permanente (nunca expira)** com app publicado |

> [!IMPORTANT]
> A documentação oficial do Rclone adverte: o `client_id` público compartilhado embutido no código fonte está em processo de desativação pela Google durante o ano de 2026. A criação do próprio aplicativo é o padrão mandatório para garantir estabilidade e imunidade contra interrupções.

---

## 2. A Armadilha dos 7 Dias e o Status Publicado

No Google Cloud Platform, aplicativos OAuth 2.0 operam em dois estados de publicação:

1. **Status "Testando" (Testing):**
   - O Google restringe o acesso estritamente aos e-mails listados em *Usuários de teste*.
   - Se uma conta não estiver cadastrada, o login falha com `Erro 403: access_denied`.
   - **Limitação de Segurança:** Os *refresh tokens* gerados em modo de teste **expiram obrigatoriamente após 7 dias**, forçando reautenticação periódica no navegador.
2. **Status "Em Produção" (Publicado / Published):**
   - Os *refresh tokens* gerados são **permanentes e nunca expiram**.
   - O Rclone renova o *access token* em segundo plano transparentemente sem nunca interromper o serviço ou abrir o navegador.
   - **Dispensa de Auditoria Burocrática:** Para aplicativos de uso pessoal, desde que **não seja enviado logotipo**, o Google dispensa envio de documentação empresarial ou auditoria manual de segurança.

---

## 3. Passo a Passo: Configuração no Google Cloud Console

Tempo estimado: **3 a 5 minutos**.

### Passo 1: Criação do Projeto e Ativação da API
1. Acesse o [Google Cloud Console](https://console.cloud.google.com/) autenticado na sua conta Google.
2. Na barra superior, clique no seletor de projetos → **Novo Projeto**.
3. Defina o nome como `Rclone-Kinoite` (ou de sua preferência) e clique em **Criar**.
4. No menu lateral de navegação (três barras), acesse **APIs e Serviços → Biblioteca**.
5. Pesquise por **Google Drive API** e clique em **Ativar**.

### Passo 2: Configuração da Identidade (Branding)
1. No menu lateral, acesse **Google Auth Platform** (ou **Tela de permissão OAuth**).
2. Em *Configuração do projeto / Criar branding*, preencha:
   - **Nome do app:** `Rclone Kinoite`
   - **E-mail para suporte do usuário:** Selecione o seu endereço do Gmail.
   - **Logotipo do app:** 👉 **DEIXE EM BRANCO (NÃO envie imagem)**.
     > [!WARNING]
     > Fazer upload de um logotipo obriga o Google a exigir verificação documental da sua organização. Sem logotipo, o aplicativo é aprovado automaticamente para uso pessoal.
   - **Página inicial do aplicativo:** `https://rclone.org`
   - **Política de Privacidade:** `https://rclone.org/privacy/`
   - **Termos de Serviço:** `https://rclone.org/licence/`
   - **Domínios autorizados:** Clique em `+ Adicionar domínio` e insira `rclone.org`.
   - **Dados de contato do desenvolvedor:** Seu endereço de e-mail.
3. Clique em **Salvar e continuar**.

### Passo 3: Escopos de Acesso (Permissões)
1. Acesse **Acesso a dados** (menu lateral) → **Adicionar ou remover escopos**.
2. Filtre e selecione o escopo:
   - `.../auth/drive` *(Ver, editar, criar e excluir todos os seus arquivos do Google Drive)*.
3. Clique em **Atualizar** e depois em **Salvar**.

### Passo 4: Usuários de Teste e Publicação Definitiva
1. Acesse **Público-alvo** *(Audience)* no menu lateral.
2. Em *Tipo de usuário*, confirme que está como **Externo**.
3. Em *Usuários de teste*, clique em **+ Add users**, adicione o seu e-mail do Gmail e salve.
4. No topo da tela em *Status de publicação*, clique no botão **Publicar aplicativo** (*Publish app*) e confirme.  
   *(O status passará de "Testando" para "Em produção", garantindo tokens permanentes).*

### Passo 5: Criação das Credenciais de Desktop
1. Acesse **Clientes** *(Credentials / Clientes)* no menu lateral.
2. Clique no botão **+ Criar cliente** (*Create client*).
3. Em **Tipo de aplicativo**, selecione obrigatoriamente:
   👉 **App para Computador** *(Desktop App)*.
4. Nomeie como `Rclone Desktop` e clique em **Criar**.
5. Uma janela pop-up exibirá as credenciais. Copie e armazene com segurança:
   - **ID do cliente:** (ex.: `123456789-xxxxxxxx.apps.googleusercontent.com`)
   - **Chave secreta do cliente:** (ex.: `GOCSPX-xxxxxxxxxxxx`)

---

## 4. Aplicação e Vinculação no Rclone

No terminal da sua estação Fedora Kinoite:

### 1. Atualizar as chaves no remote `GoogleDrive`
Substitua com suas chaves copiadas:

```bash
rclone config update GoogleDrive client_id "SEU_CLIENT_ID" client_secret "SUA_CHAVE_SECRETA"
```

### 2. Autenticar interativamente via navegador
Execute a reconexão para emitir o novo par de tokens vinculado ao seu projeto:

```bash
rclone config reconnect GoogleDrive:
```

1. O Rclone iniciará um listener local em `http://127.0.0.1:53682/` e abrirá seu navegador padrão.
2. Selecione a sua conta do Google.
3. O Google exibirá a tela de aviso de segurança:
   > *"O Google não verificou este app"* (esperado para apps pessoais próprios).
4. Clique no link pequeno **Avançado** *(Advanced)* no canto inferior esquerdo.
5. Clique em **Acessar Rclone Kinoite (não seguro)**.
6. Na tela seguinte de confirmação de permissões do Google Drive, clique em **Continuar / Permitir**.
7. O navegador exibirá `Success! All done. Please go back to rclone.`

### 3. Reiniciar a unidade de serviço do systemd
Recarregue o daemon do usuário para montar a nova sessão com cota dedicada:

```bash
systemctl --user restart rclone@GoogleDrive.service
```

### 4. Validação operacional
Verifique o status ativo e os tempos de inicialização sub-segundo:

```bash
systemctl --user status rclone@GoogleDrive.service
time ls -la ~/Cloud/GoogleDrive
```

---

## 5. Segurança, Higiene e Proteção de Dados Sensíveis

### Localização e Permissões Locais das Credenciais
- As chaves OAuth e tokens gerados residem exclusivamente no arquivo de configuração do usuário:
  `~/.config/rclone/rclone.conf`
- O sistema e o script `kinoite-optimize` garantem permissões estritas `0600` (`-rw-------`) para o arquivo e `0700` (`drwx------`) para o diretório `~/.config/rclone`, impedindo leitura por outros usuários locais ou processos não privilegiados.

### Proteção no Repositório Git
- O repositório `kinoite-bluebuild` possui regras rigorosas no `.gitignore` impedindo versionamento acidental de chaves:
  ```gitignore
  rclone.conf
  *.token
  *.secret
  .env
  .env.*
  *.local.env
  ```
- **Auditoria de Commits:** Jamais comite `client_id`, `client_secret` ou tokens no Git. Variáveis de ambiente declarativas nos templates do sistema (`/usr/share/rclone/env/GoogleDrive.env`) contêm apenas flags de performance e sintonização de pacer/cache, mantendo credenciais isoladas em arquivos locais.

---

## 6. Compartilhamento do Client ID com Múltiplos Remotes

Se você possuir mais de uma conta Google (ex.: contas secundárias `joeliankipem:` e `flinchillusion:` unificadas sob `UnionDrive:`), você **não precisa criar múltiplos projetos no Google Cloud**:
- O mesmo par de `client_id` e `client_secret` pode ser reutilizado em quantos remotes do Google Drive você desejar dentro do mesmo `rclone.conf`.
- Cada conta executará o comando `rclone config reconnect <nome_do_remote>:` individualmente para autorizar seu respectivo e-mail no navegador.
- Todas as contas passam a compartilhar da sua cota privada de 20.000 requisições / 100s, com desempenho máximo e livre de bloqueios globais.
