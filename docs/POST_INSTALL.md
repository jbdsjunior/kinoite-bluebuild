# Runbook de Instalação e Operação (`kinoite-amd` / `kinoite-dual`)

Guia operacional para particionamento LUKS2/Btrfs, desbloqueio seguro TPM 2.0, manutenção e montagens Rclone.

---

## 1. Instalação e Desbloqueio TPM 2.0 (PCR 7)

### 1.1 Particionamento Recomendado

No instalador do Fedora (Anaconda), selecione o particionamento automático ou personalizado com a opção **"Criptografar meus dados"** (LUKS2) ativada.
Não crie partição de swap em disco; o sistema provisiona automaticamente **32 GB de ZRAM `zstd`** via `60-zram-policy.conf` (`vm.swappiness=150`).

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

# OU para estação Dual-GPU (AMD display + NVIDIA compute):
sudo bootc switch ghcr.io/jbdsjunior/kinoite-dual:latest

systemctl reboot

# --- Etapa 2: Ativação da assinatura estrita (executar após boot na imagem) ---

# Para estação AMD pura:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# OU para estação Dual-GPU:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-dual:latest
```

### 2.1 Inscrição e Permanência da Chave MOK (`kinoite-dual` com Secure Boot)

Ao utilizar a imagem Dual-GPU (`kinoite-dual`) em placas-mãe com **UEFI Secure Boot ativo**, os módulos do driver proprietário NVIDIA (`nvidia.ko`, `nvidia-uvm.ko`) exigem a inscrição do certificado Machine Owner Key (MOK) do build:

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
| **Manutenção completa** | `sudo kinoite-optimize` | Executa as 8 fases: sysctl, tmpfiles/NoCOW, saúde e reclaim do Btrfs, desfragmentação de discos de VM, retenção do journald, higiene de Flatpak/contêineres, higiene de kargs/deployments e a auditoria final. |
| **Auditoria somente leitura** | `sudo kinoite-optimize --audit` | Executa exclusivamente a auditoria dos 6 pilares, sem alterar o sistema. |
| **Ajuda** | `kinoite-optimize --help` | Lista modos e avisos de segurança. |

> [!WARNING]
> A fase 7 remove kargs de tuning que não sejam baseline upstream (`amd_pstate=active`, `nowatchdog`, `preempt=full`, etc.) e reaplica os blocklists do flavor dual. Se houver alteração, o comando avisa que **um reboot é necessário**. Prefira `--audit` quando quiser apenas inspecionar.

Os 6 pilares da auditoria canônica:

1. Supply Chain, chaves Cosign e assinatura criptográfica.
2. Resiliência de pacotes e ausência de downgrade (deriva upstream).
3. Armazenamento Btrfs NoCOW e gestão de memória/ZRAM.
4. Aceleração de GPU, Vulkan e Wayland zero-copy.
5. Resiliência de boot (GRUB limpo, SysRq REISUB, `sulogin`).
6. Governança de timers de manutenção e armazenamento.

Atalhos adicionais no terminal (`60-kinoite-aliases.sh`):
- `sysup`: `sudo bootc update`.
- `rollback`: `sudo bootc rollback`.
- `status-rclone` / `logs-rclone`: monitoramento de serviços Rclone do usuário.
- `setup-tpm`: `sudo kinoite-setup-tpm`.

---

## 4. IA Local e Contêineres ROCm (CDI)

A estação suporta aceleração total na **RX 6600 XT** através de duas camadas já integradas:

1. **Host (`llamafile`, `llama.cpp`, GGUF) via Vulkan 1.4 (`radv`):**
   ```bash
   ./seu-modelo.llamafile --gpu vulkan -ngl 99 --mlock
   ```
   *(SELinux e limites de memlock ilimitados já estão provisionados nativamente)*.

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

- **Higiene:** Os diretórios remotos são montados em `/run/user/` (excluídos do indexador Baloo) e o Dolphin/KIO está pré-configurado para exclusão direta na nuvem sem poluição de pastas locais `.Trash-*`.

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

## 7. Inicialização Silenciosa e Elegante (Zero-Touch GRUB Auto-Hide)

O Fedora Kinoite utiliza o mecanismo **GRUB Menu Auto-Hide** com transição *flicker-free* via tema Plymouth BGRT (o logotipo da placa-mãe AORUS permanece estático até a tela de login/desbloqueio sem cortes de tela preta).

### 7.1 Provisionamento 100% Nativo na Imagem

Como o Fedora Kinoite (`bootc`/`rpm-ostree`) mantém permanentemente múltiplos deployments (sistema ativo + rollback), o GRUB é configurado em modo forçado (`menu_auto_hide=2` + `user.cfg`) através da unidade systemd [`kinoite-boot-init.service`](../files/system/usr/lib/systemd/system/kinoite-boot-init.service):

- Grava `menu_auto_hide=2`, `boot_success=1` e `boot_indeterminate=0`.
- Grava `set timeout=0` e `set timeout_style=hidden` em `/boot/grub2/user.cfg`.
- Opera de forma zero-touch no primeiro boot.

Caso deseje verificar o status do ambiente GRUB no host:

```bash
sudo grub2-editenv - list | grep menu_auto_hide
```

### 7.2 Salvaguardas de Segurança e Rollback Automático

- **Fallback Automático (`grub-boot-success.timer`):** O timer de sessão do usuário aguarda 2 minutos de desktop estável para confirmar o boot. Se o sistema falhar ao inicializar ou desligar abruptamente, o GRUB **automaticamente reexibe o menu com as opções de rollback no próximo boot**.
- **Acesso Manual ao Menu:** Para forçar a exibição do menu do GRUB a qualquer momento, ligue o computador mantendo pressionada a tecla **`Shift`** ou tocando repetidamente em **`Esc`** ou **`F8`**.
- **Reverter para Menu Sempre Visível:** Caso deseje que o menu volte a aparecer sempre:
  ```bash
  sudo grub2-editenv - unset menu_auto_hide
  sudo rm -f /boot/grub2/user.cfg
  ```

### 7.3 Bloqueio de Bootloader e Console (Zero Unauthenticated Recovery)

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
| SSH | `PermitRootLogin no`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `MaxAuthTries 3`, `X11Forwarding no` (`/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`) | Criar `/etc/ssh/sshd_config.d/99-local.conf` com as diretivas desejadas (drop-ins são lidos em ordem alfabética) e `sudo systemctl restart sshd` |
| DNS | `systemd-resolved` com Control D (bloqueio de malware/ads) + DNS-over-TLS obrigatório, DNSSEC desativado de propósito | `/etc/systemd/resolved.conf.d/60-dns-overrides.conf` + `sudo systemctl restart systemd-resolved` |
| Firewall | Zona `tailscale` (target `ACCEPT`) para a interface `tailscale0` | `sudo firewall-cmd --permanent --delete-zone=tailscale` |
| Atualizações | `bootc update` a cada 45 min após o boot, Flatpak (sistema e usuário) e `podman auto-update` na mesma cadência | `sudo systemctl edit bootc-fetch-apply-updates.timer` |
| GRUB | Auto-hide forçado (`menu_auto_hide=2`, `timeout=0`) com rollback automático em falha de boot | Seção 7.2 |
| KDE | `SingleClick=true`, Breeze Dark, fontes nativas do Plasma 6, `breezerc` sem bordas, blur no KWin, Konsole translúcido e Baloo sem indexar `rclone`/`/run/user` | Preferências do sistema (configuração de usuário prevalece sobre `/etc/xdg`) |
| Btrfs Scrub | `kinoite-btrfs-scrub.timer` mensal em AC (`Nice=19`, `idle`) em `/var/home` | `sudo systemctl disable --now kinoite-btrfs-scrub.timer` |
| Energia (`tuned`) | Perfil `throughput-performance` aplicado no primeiro boot via `kinoite-boot-init.service` | `tuned-adm profile balanced` ou slider de energia do Plasma |
| OOMD (`user-.slice`) | `ManagedOOMMemoryPressure=kill` (70%) e `ManagedOOMSwap=kill` em `60-kinoite-oomd.conf` | Drop-in em `/etc/systemd/system/user-.slice.d/` |
| Flatpaks | Override `global` (GTK/fontconfig/kdeglobals, Electron Wayland, `LIBVA_DRIVER_NAME=radeonsi`), Firefox Wayland e Jan GPU/ROCm | `flatpak override --reset` ou Flatseal |
| Kargs | `kinoite-optimize` (fase 7) remove tuning não-upstream e reaplica os blocklists do dual | `--audit` para inspecionar antes; ajustes manuais não são preservados |

### 8.1 Detecção Dinâmica de GPUs (Agnóstica a Slot PCI)

A imagem não depende mais de endereços PCI estáticos: os vínculos gráficos e de computação são resolvidos dinamicamente pelo driver do kernel (`amdgpu` / `nvidia`):

| Elemento | Mecanismo dinâmico | Arquivo |
| :--- | :--- | :--- |
| Symlink `primary-render` | Regra `udev` por `DRIVERS=="amdgpu"` | [`files/system/usr/lib/udev/rules.d/70-peripherals.rules`](../files/system/usr/lib/udev/rules.d/70-peripherals.rules) |
| CDI AMD (ROCm/HIP) | Mapeia `/dev/dri/primary-render` → `/dev/dri/renderD128` e `/dev/kfd` | [`files/system/etc/cdi/amdgpu.yaml`](../files/system/etc/cdi/amdgpu.yaml) |
| Auditoria (Pilar 4) | Varre `/sys/class/drm/renderD*/device/driver` para `amdgpu` e `nvidia` | [`files/system/usr/bin/kinoite-optimize`](../files/system/usr/bin/kinoite-optimize) |

Caso seja necessário forçar um nó específico durante uma auditoria manual, sobrescreva com `AMD_RENDER_PATH=... NVIDIA_RENDER_PATH=... kinoite-optimize --audit`.
