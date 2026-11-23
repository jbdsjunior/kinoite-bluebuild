# Runbook de Instalação e Operação (`kinoite-amd` / `kinoite-cuda`)

Guia operacional para particionamento LUKS2/Btrfs, desbloqueio seguro TPM 2.0, manutenção e montagens Rclone.

---

## 1. Instalação e Desbloqueio TPM 2.0 (PCR 7 + 14)

### 1.1 Particionamento Recomendado

No instalador do Fedora (Anaconda), selecione o particionamento automático ou personalizado com a opção **"Criptografar meus dados"** (LUKS2) ativada.
Não crie partição de swap em disco; o sistema provisiona automaticamente **32 GB de ZRAM `zstd`** via `60-zram.conf` (`vm.swappiness=150`).

### 1.2 Configurar Desbloqueio Seguro TPM 2.0 (Dois Fatores: Hardware fTPM + PIN)

Execute o utilitário integrado de provisionamento (a partição LUKS raiz é detectada automaticamente):

```bash
# Provisionamento interativo (pergunta se deseja cadastrar PIN de segurança):
sudo kinoite-setup-tpm

# Ou defina explicitamente com PIN (Recomendado - 2 Fatores: Hardware fTPM + PIN):
sudo kinoite-setup-tpm --pin

# Modo desatendido sem PIN (apenas chave de hardware fTPM bound a PCR 7 + 14):
sudo kinoite-setup-tpm --no-pin
```

*(Opcional: caso queira especificar explicitamente um dispositivo, utilize `sudo kinoite-setup-tpm /dev/nvme0n1p3 --pin`)*.

> [!TIP]
> **Proteção Física de Dois Fatores (PIN + PCR 7/14):** Com a opção `--pin`, o disco só é descriptografado pelo TPM se o usuário digitar o PIN no teclado durante a inicialização. Com `--no-pin`, o fTPM descriptografa o disco automaticamente em ~1s mantendo a tela de login padrão do usuário. Em ambos os modos, a integridade do firmware e bootloader é verificada via PCR 7 + 14, impedindo acesso a dados se o NVMe for fisicamente removido.

> [!NOTE]
> **Pós-Atualização de Firmware (UEFI) ou Chave MOK:** Se atualizar o firmware da placa-mãe ou inscrever novas chaves MOK, digite a senha manual no primeiro boot e re-execute o comando (`sudo kinoite-setup-tpm --pin` ou `--no-pin`), que recria o slot TPM de forma idempotente.

---

## 2. Transição para a Imagem Customizada (`bootc`)

A transição a partir de uma instalação limpa do Fedora Kinoite upstream segue um protocolo de **duas etapas**:

1. **Bootstrap inicial (sem imposição de política prévia):** A instalação limpa do Fedora Kinoite upstream ainda não possui as chaves públicas do seu repositório no GHCR nem a política de verificação configurada. O primeiro switch baixa a imagem OCI customizada e provisiona as chaves públicas Cosign (`/etc/pki/containers/kinoite-*.pub`), a política de contêineres (`/etc/containers/policy.json`) e os registros (`/etc/containers/registries.d/`).
2. **Imposição criptográfica estrita (pós-boot):** Após reiniciar na imagem customizada, o sistema já dispõe das chaves e da política. O comando com `--enforce-container-sigpolicy` trava o deployment no modo assinado (`ostree-image-signed`), exigindo assinatura Cosign válida em qualquer atualização subsequente.

```bash
# --- Etapa 1: Transição inicial no Fedora upstream ---

# Para estação AMD pura:
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest

# OU para estação com NVIDIA CUDA headless (AMD display + NVIDIA compute):
sudo bootc switch ghcr.io/jbdsjunior/kinoite-cuda:latest

systemctl reboot

# --- Etapa 2: Ativação da assinatura estrita (executar após boot na imagem) ---

# Para estação AMD pura:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# OU para estação com NVIDIA CUDA headless:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-cuda:latest
```

### 2.1 Inscrição e Permanência da Chave MOK (`kinoite-cuda` com Secure Boot)

Ao utilizar a imagem CUDA (`kinoite-cuda`) em placas-mãe com **UEFI Secure Boot ativo**, os módulos do driver proprietário NVIDIA (`nvidia.ko`, `nvidia-uvm.ko`) exigem a inscrição do certificado Machine Owner Key (MOK) do build:

1. **Importar o Certificado MOK no Host (Apenas no Primeiro Setup):**
   ```bash
   sudo mokutil --import /etc/pki/akmods/certs/akmods-ublue.der
   ```
   *Defina uma senha temporária de sua escolha apenas para autorizar o cadastro na reinicialização.*

2. **Confirmar na Tela Azul do MOK Manager (UEFI):**
   * Reinicie o computador (`systemctl reboot`).
   * A tela azul do **MOK Manager** aparecerá antes do boot.
   * Selecione **Enroll MOK** -> **Continue** -> **Yes** -> digite a senha da etapa 1 e confirme com **Reboot**.

3. **Permanência no Hardware:**
   * O certificado fica gravado na NVRAM protegida da placa-mãe de forma permanente. Atualizações de imagem ou kernel não solicitam nova confirmação.
   * Verificação: `nvidia-smi`.

---

## 3. Manutenção e Auditoria do Sistema (`kinoite-optimize`)

O utilitário integrado (também disponível via alias `sys-optimize`) opera em dois modos distintos:

| Modo | Comando | Comportamento |
| :--- | :--- | :--- |
| **Manutenção completa** | `sudo kinoite-optimize` | Executa as 6 fases: tmpfiles/NoCOW, saúde e reclaim do Btrfs, desfragmentação e compactação `.qcow2` de discos de VM, retenção do journald/thumbnails, higiene de contêineres Podman e a auditoria final. |
| **Auditoria somente leitura** | `sudo kinoite-optimize --audit` | Executa exclusivamente a auditoria dos 6 pilares, sem alterar o sistema. |
| **Ajuda** | `kinoite-optimize --help` | Lista modos e avisos de segurança. |

Os 6 pilares da auditoria canônica:

1. Supply Chain, chaves Cosign e assinatura criptográfica.
2. Resiliência de pacotes e ausência de downgrade (deriva upstream).
3. Armazenamento Btrfs NoCOW e gestão de memória/ZRAM.
4. Aceleração de GPU, Vulkan e Wayland zero-copy.
5. Resiliência de boot (GRUB limpo, SysRq REISUB, `sulogin`).
6. Governança de timers de manutenção e armazenamento.

Atalhos adicionais no terminal (`60-shell-aliases.sh`):
- `sysup`: `sudo bootc upgrade`.
- `rollback`: `sudo bootc rollback`.
- `status-rclone` / `logs-rclone`: monitoramento de serviços Rclone do usuário.
- `setup-tpm`: `sudo kinoite-setup-tpm`.

---

## 4. IA Local e Contêineres ROCm (CDI)

A estação suporta aceleração total na **RX 6600 XT** através de duas camadas já integradas:

1. **Host (`llamafile`, `llama.cpp`, GGUF) via Vulkan 1.4 (`radv`):**
   ```bash
   ./seu-modelo.llamafile --gpu vulkan -ngl 99
   ```
   *(SELinux já está configurado para execução local sem ajustes manuais)*.

2. **Contêineres ROCm/HIP (Ollama, PyTorch) via CDI (`/etc/cdi/amdgpu.yaml`):**
   ```bash
   podman run -d --device amd.com/gpu=all --ipc=host -v ollama:/root/.ollama:Z -p 11434:11434 --name ollama docker.io/ollama/ollama:rocm
   ```

---

## 5. Montagens FUSE de Nuvem (Rclone)

Os remotes montam automaticamente fora da home em `/run/user/$UID/cloud/<Remote>` com cache VFS persistente em `~/.cache/rclone` (`0700`, NoCOW `+C`):

```bash
# 1. Configurar remotes (ex: GoogleDrive ou OneDrive)
rclone config

# 2. Ativar e iniciar serviço do usuário
systemctl --user enable --now rclone@GoogleDrive.service
systemctl --user enable --now rclone@OneDrive.service

# 3. Reconectar caso o token expire
rclone config reconnect GoogleDrive:
```

- **Higiene:** Os diretórios remotos são montados em `/run/user/` (excluídos do indexador Baloo), o `rclone@.service` bloqueia diretórios `.Trash-*` e `.Trash` na montagem e o `kinoite-optimize` remove eventuais pastas `.Trash-*` residuais.

---

## 6. Rollback e Recuperação de Emergência

```bash
# Reverter para a imagem do deployment anterior
sudo bootc rollback
systemctl reboot

# Reverter para o Fedora Kinoite upstream oficial
sudo bootc switch quay.io/fedora/fedora-kinoite:latest

# Inspecionar logs de atualização automática em background
journalctl -u bootc-fetch-apply-updates.service -n 50 --no-pager
```

- **SysRq REISUB (`kernel.sysrq = 1`):** Em caso de congelamento gráfico, segure `Alt + SysRq` e digite pausadamente `R` → `E` → `I` → `S` → `U` → `B` para descarregar caches Btrfs e reiniciar com segurança.

---

## 7. Segurança de Bootloader e Console (Zero Unauthenticated Recovery)

Para garantir que terceiros com acesso físico não possam editar a linha do kernel (`init=/bin/bash` ou parâmetros não autorizados):

1. **Configurar Senha de Proteção no GRUB:**
   ```bash
   sudo grub2-setpassword
   ```
   *Efeito:* O GRUB continuará inicializando o sistema normalmente, mas exigirá o usuário `root` e a senha definida caso alguém pressione a tecla `e` para editar os parâmetros de boot.

2. **Garantir Credencial de Emergência (`sulogin`):**
   ```bash
   sudo passwd root
   ```
   *Efeito:* Garante que, se o sistema entrar em modo `emergency` ou `rescue` (por exemplo, após falha crítica de disco), o shell de manutenção só possa ser acessado mediante digitação de senha, alinhado ao padrão de segurança física *Zero Unauthenticated Recovery*.

---

## 8. Comportamentos Padrão da Imagem (o que muda em relação ao Fedora upstream)

Estes padrões são aplicados pela própria imagem e não exigem ação no pós-instalação — mas você precisa conhecê-los antes de depurar um comportamento inesperado.

| Área | Padrão aplicado | Como reverter |
| :--- | :--- | :--- |
| DNS | `systemd-resolved` com Control D P2 (bloqueio de malware/ads) + `DNSOverTLS=opportunistic` (compatível com Tailscale MagicDNS), DNSSEC desativado de propósito | `/etc/systemd/resolved.conf.d/60-dns.conf` + `sudo systemctl restart systemd-resolved` |
| Firewall | Zona `tailscale` (target `ACCEPT`) para a interface `tailscale0` | `sudo firewall-cmd --permanent --delete-zone=tailscale` |
| Atualizações | `bootc update` e Flatpak (sistema e usuário) a cada 30 minutos (1 min após o boot/login), aguardando rede online (`nm-online`) | `sudo systemctl edit bootc-fetch-apply-updates.timer` |
| KDE | Centralização de novas janelas (`Placement=Centered` + script `kinoite-window-center` em `kwinrc`) e Konsole translúcido (`Kinoite.profile`) | Preferências do sistema (configuração de usuário prevalece sobre `/etc/xdg`) |

### 8.1 Detecção Dinâmica de GPUs (Agnóstica a Slot PCI)

A imagem não depende mais de endereços PCI estáticos: os vínculos gráficos e de computação são resolvidos dinamicamente pelo driver do kernel (`amdgpu` / `nvidia`):

| Elemento | Mecanismo dinâmico | Arquivo |
| :--- | :--- | :--- |
| Symlink `primary-render` | Regra `udev` por `DRIVERS=="amdgpu"` | [`files/base/usr/lib/udev/rules.d/70-hardware.rules`](../files/base/usr/lib/udev/rules.d/70-hardware.rules) |
| CDI AMD (ROCm/HIP) | Mapeia `/dev/dri/renderD128`, `/dev/dri/card0` e `/dev/kfd` (CDI não aceita symlink `hostPath`) | [`files/rocm/etc/cdi/amdgpu.yaml`](../files/rocm/etc/cdi/amdgpu.yaml) |
| Auditoria (Pilar 4) | Varre `/sys/class/drm/renderD*/device/driver` para `amdgpu` e `nvidia` | [`files/base/usr/bin/kinoite-optimize`](../files/base/usr/bin/kinoite-optimize) |

Caso seja necessário forçar um nó específico durante uma auditoria manual, sobrescreva com `AMD_RENDER_PATH=... NVIDIA_RENDER_PATH=... kinoite-optimize --audit`.

### 8.2 Estabilidade UEFI/BIOS (AMD X570 + Ryzen 9 5950X)

Em plataformas AM4 X570 com processadores Zen 3 (`Ryzen 9 5950X`), recomenda-se configurar na UEFI/BIOS (*Advanced → AMD CBS → CPU Common Options*) **`Power Supply Idle Control` = `Typical Current Idle`** para evitar quedas de tensão em estados C6 de baixa corrente no Linux (sem perda de *single-core boost*). Caso utilize PBO / Curve Optimizer, evite *offsets* negativos agressivos nos núcleos principais.
