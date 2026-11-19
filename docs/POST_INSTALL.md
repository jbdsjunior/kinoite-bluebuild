# Runbook de Instalação e Operação (`kinoite-amd` / `kinoite-cuda`)

Guia operacional para particionamento LUKS2/Btrfs, desbloqueio seguro TPM 2.0, BIOS CPPC, montagens Rclone, manutenção e recuperação.

---

## 1. Instalação e Desbloqueio TPM 2.0 (PCR 7 + 14)

### 1.1 Particionamento e BIOS Recomendados

No instalador do Fedora (Anaconda), selecione o particionamento com **"Criptografar meus dados"** (LUKS2) ativada e sem swap em disco; o sistema provisiona **32 GB de ZRAM `zstd`** via `60-zram-policy.conf` (`vm.swappiness=150`).

Na BIOS da placa-mãe **Gigabyte X570 AORUS PRO WIFI**, mantenha **Secure Boot** e **AMD fTPM** ativos e verifique se **AMD Cool'n'Quiet / PSS Support**, **CPPC** e **CPPC Preferred Cores** estão habilitados para que o kernel ative o driver `amd-pstate-epp` no Ryzen 9 5950X.

### 1.2 Configurar Desbloqueio Seguro TPM 2.0 (Hardware fTPM + PIN)

Execute o utilitário integrado de provisionamento (a partição LUKS raiz é detectada automaticamente):

```bash
# Provisionamento interativo (pergunta se deseja cadastrar PIN de segurança):
sudo kinoite-setup-tpm

# Ou defina explicitamente com PIN (Recomendado - 2 Fatores: Hardware fTPM + PIN):
sudo kinoite-setup-tpm --pin

# Modo desatendido sem PIN (apenas chave de hardware fTPM bound a PCR 7 + 14):
sudo kinoite-setup-tpm --no-pin
```

*(Opcional: para especificar explicitamente um dispositivo, utilize `sudo kinoite-setup-tpm /dev/nvme0n1p3 --pin`)*.

> [!NOTE]
> **Pós-Atualização de Firmware (UEFI) ou Chave MOK:** Se atualizar o firmware da placa-mãe ou inscrever novas chaves MOK, digite a senha manual no primeiro boot e re-execute `sudo kinoite-setup-tpm --pin` (ou `--no-pin`), que recria o slot TPM de forma idempotente.

---

## 2. Transição para a Imagem Customizada (`bootc`)

A transição a partir de uma instalação limpa do Fedora Kinoite upstream segue um protocolo de **duas etapas**:

1. **Bootstrap inicial:** baixa a imagem OCI customizada e provisiona as chaves públicas Cosign e a política de verificação.
2. **Imposição criptográfica estrita (pós-boot):** trava o deployment no modo assinado (`ostree-image-signed`), exigindo assinatura Cosign válida em qualquer atualização subsequente.

```bash
# --- Etapa 1: Transição inicial no Fedora upstream ---
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
# OU para estação com NVIDIA CUDA headless:
sudo bootc switch ghcr.io/jbdsjunior/kinoite-cuda:latest

systemctl reboot

# --- Etapa 2: Ativação da assinatura estrita (executar após boot na imagem) ---
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest
# OU para estação com NVIDIA CUDA headless:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-cuda:latest
```

### 2.1 Inscrição da Chave MOK (`kinoite-cuda` com Secure Boot)

Ao utilizar `kinoite-cuda` com **UEFI Secure Boot ativo**, inscreva o certificado MOK do build no primeiro setup:

```bash
sudo mokutil --import /etc/pki/akmods/certs/akmods-ublue.der
systemctl reboot
```

Na tela azul do **MOK Manager**, selecione **Enroll MOK** → **Continue** → **Yes**, informe a senha temporária e reinicie. Valide depois com `nvidia-smi`.

---

## 3. Manutenção e Auditoria do Sistema (`kinoite-optimize`)

O utilitário integrado (alias `sys-optimize`) opera em dois modos:

| Modo | Comando | Comportamento |
| :--- | :--- | :--- |
| **Manutenção segura** | `sudo kinoite-optimize` | Sincroniza sysctl/tmpfiles (limpando resíduos legados do host), aplica NoCOW `+C`, executa balance/TRIM Btrfs, desfragmenta imagens de VM (`>5000` extents), limpa imagens Podman órfãs/runtimes Flatpak sem uso/thumbnails > 30 dias (preservando contêineres parados e volumes) e roda a auditoria final. |
| **Auditoria somente leitura** | `sudo kinoite-optimize --audit` | Executa exclusivamente a auditoria dos 5 pilares, sem alterar o sistema. |
| **Ajuda** | `kinoite-optimize --help` | Lista modos e avisos de segurança. |

Os 5 pilares da auditoria canônica:

1. Supply Chain, chaves Cosign e assinatura criptográfica (`ublue` MOK / Secure Boot).
2. Memória ZRAM, writeback NVMe, Btrfs NoCOW (`+C`) e fila NVMe (`256 KiB`).
3. Aceleração de GPU (AMD RADV/DRM) e isolamento headless NVIDIA (zero nós DRM NVIDIA).
4. Resiliência do kernel (`SysRq=1`), linha de boot limpa, `cpufreq` e proteção `sulogin`.
5. Timers recorrentes (4h/semanais/mensal), exclusão Baloo e higiene de estado mutável.

Atalhos úteis no terminal ([60-kinoite-aliases.sh](../files/desktop/etc/profile.d/60-kinoite-aliases.sh)):
- `sysup`: `sudo bootc upgrade`.
- `rollback`: `sudo bootc rollback`.
- `status-libvirt`: `systemctl status virtqemud.socket`.
- `status-rclone` / `logs-rclone`: monitoramento de serviços Rclone do usuário.
- `setup-tpm`: `sudo kinoite-setup-tpm`.

---

## 4. IA Local e Virtualização

- **IA Local (`kinoite-cuda`):** A RTX 3080 Ti opera exclusivamente em modo headless para CUDA/PyTorch/LLMs em contêineres via NVIDIA CDI (`/var/run/cdi/nvidia.yaml`) e `memlock unlimited` para `--mlock` no host. A RX 6600 XT permanece isolada para Wayland, Vulkan RADV e VA-API.
- **Virtualização KVM:** A pilha enxuta instala `qemu-kvm`, `libvirt-daemon-kvm`, `edk2-ovmf`, `swtpm`, **GNOME Boxes** e **virt-manager** (ativação sob demanda via sockets `virtqemud`), com permissão local sem senha para o grupo `wheel` e NoCOW `+C` nas pastas de discos de VM.

---

## 5. Montagens FUSE de Nuvem (Rclone)

Os remotes montam fora da home em `/run/user/$UID/cloud/<Remote>` com cache VFS em `~/.cache/rclone` (`0700`, NoCOW `+C`):

```bash
rclone config
systemctl --user enable --now rclone@GoogleDrive.service
systemctl --user enable --now rclone@OneDrive.service
```

Os diretórios em `/run/user/` são excluídos da indexação do KDE Baloo (`baloofilerc`).

---

## 6. Limpeza de Resíduos Legados Após Upgrade de Versões Anteriores

Ao atualizar uma máquina que rodava versões anteriores deste repositório, arquivos mutáveis gravados em `/etc`, `/var` ou `/boot` podem permanecer no host. Após reiniciar na nova imagem:

1. Execute `sudo kinoite-optimize` para remover automaticamente os symlinks antigos de `/etc/sysctl.d/90-{kernel,memory-fs,network}-tuning.conf`, o marcador `/var/lib/kinoite-boot-init-v4-done` e os overrides Flatpak obsoletos (`ai.jan.Jan`, `com.visualstudio.code`, `com.google.Chrome`, `org.mozilla.firefox`).
2. Se desejar limpeza total de resíduos manuais antigos:
   ```bash
   sudo rm -f /etc/cdi/amdgpu.yaml /boot/grub2/user.cfg
   ```
3. Caso tenha sido herdado algum karg antigo do host (`initcall_blacklist=simpledrm_platform_driver_init`), remova-o apenas se ainda aparecer em `/proc/cmdline` após o reboot:
   ```bash
   sudo rpm-ostree kargs --delete-if-present=initcall_blacklist=simpledrm_platform_driver_init
   ```
4. Opcionalmente, verifique chaves MOK antigas sem uso com `mokutil --list-enrolled` e apps Flatpak locais duplicados (`org.gnome.Papers`, `org.gnome.DejaDup`, `com.ranfdev.DistroShelf`).

---

## 7. Rollback, Recuperação e Padrões da Imagem

```bash
# Reverter para o deployment anterior
sudo bootc rollback && systemctl reboot

# Reverter para o Fedora Kinoite upstream oficial
sudo bootc switch quay.io/fedora/fedora-kinoite:latest

# Logs de atualização automática
journalctl -u bootc-fetch-apply-updates.service -u flatpak-system-update.service -n 50 --no-pager
```

- **SysRq REISUB (`kernel.sysrq = 1`):** Em caso de congelamento grave, segure `Alt + SysRq` e digite pausadamente `R` → `E` → `I` → `S` → `U` → `B`.
- **Bloqueio de Console (`sulogin`):** Configure `sudo passwd root` e opcionalmente `sudo grub2-setpassword` para exigir autenticação em modos `rescue`/`emergency` e edição do GRUB.

| Área | Padrão aplicado | Como reverter / ajustar |
| :--- | :--- | :--- |
| SSH | `PermitRootLogin no`, apenas chave (`50-kinoite-hardening.conf`) | Criar `/etc/ssh/sshd_config.d/99-local.conf` e reiniciar `sshd` |
| DNS | `systemd-resolved` com Control D `p2`, `DNSOverTLS=opportunistic`, `DNSSEC=no`, `MulticastDNS=no` | Drop-in em `/etc/systemd/resolved.conf.d/` |
| Firewall | Zona `tailscale` (`ACCEPT`) para `tailscale0` | `sudo firewall-cmd --permanent --delete-zone=tailscale` |
| Atualizações | `bootc upgrade` (staged sem reboot automático) e Flatpak (system + user) a cada 4h em AC (`10m` após boot); Podman diário | `sudo systemctl edit bootc-fetch-apply-updates.timer` |
| Energia e GRUB | `tuned-ppd` integrado ao Plasma e GRUB `menu_auto_hide` nativos do Fedora 45 | Slider de energia do Plasma / `grub2-editenv` |
| KDE | Breeze Dark, clique simples, `Placement=Centered` nativo no KWin, blur, Konsole Tokyo Night, Baloo sem `rclone` | Preferências do sistema (`~/.config/` prevalece sobre `/etc/xdg/`) |
| Btrfs Scrub | `kinoite-btrfs-scrub.timer` mensal em AC (`Nice=19`, `idle`) em `/var/home` | `sudo systemctl disable --now kinoite-btrfs-scrub.timer` |
| Flatpaks | Override `global` (temas/fontes + `FREETYPE_PROPERTIES`) e `com.brave.Browser` (`plasma-browser-integration`) | `flatpak override --reset` ou Flatseal |
| GPU / Periféricos | `primary-render` dinâmico por `DRIVERS=="amdgpu"` em [70-peripherals.rules](../files/base/usr/lib/udev/rules.d/70-peripherals.rules); ADB/Fastboot restritos por interface USB | Override local em `/etc/udev/rules.d/` |
