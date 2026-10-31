# Diretrizes e Invariantes do Sistema (`AGENTS.md`)

Fonte canônica única (*Single Source of Truth*) para agentes que operam no repositório `kinoite-bluebuild`.

---

## 1. Versionamento Git

- **Commit Obrigatório:** Encerrar toda alteração com commit estruturado e árvore limpa (`working tree clean`).
- **Conventional Commits:** `<type>(<scope>): <descrição no presente>` (`feat`, `fix`, `docs`, `refactor`, `chore`) seguido de corpo em bullets detalhando decisões, parâmetros, impacto e arquivos.
- **Staging Estrito:** Adicionar arquivos explicitamente (`git add <arq1> <arq2>`); nunca usar `git add .` cego. Auditar `git status` e `git diff --cached` antes do commit; confirmar árvore limpa após commit e `git push origin <branch>`.

---

## 2. Princípios de Execução & Economia de Tokens

- **Prioridade Absoluta:** Segurança > Performance > Conveniência.
- **KISS & DRY:** Zero redundância com defaults upstream do Fedora, systemd ou kernel. Proibido downgrade de pacotes, daemons legados e configs mortas.
- **Modos de Execução (Otimização Diária vs Mudança Estrutural):**
  - **Fast-Path (Padrão para Otimizações Diárias / Tier 3):** Para demandas rotineiras (pacotes, flags de browser, sysctl pontual, scripts CLI, fixes), NÃO criar artefatos `.md` de plano ou walkthrough. Executar o fluxo ágil: *Diagnosticar -> Implementar (mínimo) -> Validar (sintaxe shell/YAML e integridade) -> Commit e Push -> Resposta concisa*.
  - **Full-Plan (Sob Demanda com `/plan` ou Tier 1 Crítico):** Reservado estritamente para quando o usuário solicitar explicitamente `/plan` no prompt ou para alterações de alto risco (boot/kargs/partições). Criar artefato de plano técnico e aguardar aprovação antes de tocar no código.
- **Lean Output Policy (Economia de Tokens de Resposta):**
  - Zero preâmbulos discursivos ou despedidas prolixas. Respostas diretas e telegráficas.
  - Ao criar artefatos (quando em Full-Plan), nunca re-resumir o conteúdo no chat; apontar apenas o link e decisões abertas.
  - Relatório final conciso: lista de arquivos alterados, status dos testes (`X passados`) e hash do commit.
- **Higiene de Ferramentas:** Proibido ler arquivos grandes inteiros com `read_file`; usar filtros (`grep`, `head`, `tail`) ou delimitar `StartLine`/`EndLine`.
- **Protocolo de Evolução de Invariantes (4 Critérios de Ouro):**
  1. *Evidência Técnica Upstream (Data-Driven);* 2. *Análise de Blast Radius (Anti-Regressão);* 3. *Transação Atômica no Git (código + AGENTS.md sincronizados);* 4. *Rollback Garantido & Comando Instantâneo*.

| Tier de Risco | Escopo | Requisito de Evolução |
| :--- | :--- | :--- |
| **Tier 1 (Crítico / HW & Boot)** | Bootargs, initramfs, /boot, LUKS/TPM, firmware | Rigor máximo: embasamento upstream e validação de estabilidade (`POST_INSTALL.md §6`). |
| **Tier 2 (Médio / SO & Kernel)** | Kargs, sysctl, ZRAM, Btrfs NoCOW, PipeWire | Rigor técnico: validação automatizada (`sysctl`, `systemd-analyze`, testes). |
| **Tier 3 (Ágil / Apps & UX)** | Flags de browser, Rclone, fontes, aliases, timers | Rigor ágil: Fast-Path direto, DRY/KISS e zero legado. |

---

## 3. Hardware Baseline

- **Estação Homologada:** AMD Ryzen 9 5950X (16C/32T, Zen 3, dual-CCD), AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23 / RDNA2), Gigabyte X570 AORUS PRO WIFI, 64 GB DDR4 (4×16 GB), NVMe 1 TB PCIe Gen4 (Btrfs), Fedora Kinoite (`bootc:latest`, Wayland, KDE Plasma 6, Kernel `7.2+`).
- **CPU (Zen 3):** `amd-pstate-epp` nativo com C-states upstream do Fedora.
- **GPU (Navi 23):** Mesa `radv` (Vulkan 1.4), VA-API no KWin/Wayland e contêineres ROCm/HIP via CDI (`/etc/cdi/amdgpu.yaml` com `HSA_OVERRIDE_GFX_VERSION=10.3.0`).
- **Memória (64 GB):** ZRAM `zstd` em 32 GB (`60-zram-policy.conf`) e `DefaultLimitMEMLOCK=infinity` (`60-kinoite-limits.conf`) para alocação direta de modelos GGUF (`--mlock`).
- **Armazenamento (Btrfs):** Atributo NoCOW `+C` estrito via tmpfiles `h` em diretórios de VMs e contêineres (`60-io-tuning-system.conf` e `60-io-tuning-user.conf`).
- **Periféricos:** Headset USB MCHOSE X9, fones BT Baseus Bass EP10 Pro, caixa Tribit XSound Go (quirk cirúrgico em `60-tribit-volume-quirk.conf`), mouses HID VXE e BY Tech (`TAG+="uaccess"` em `70-peripherals.rules`).
- **Firmware & BIOS:** Calibração física documentada em [`docs/POST_INSTALL.md` §6](docs/POST_INSTALL.md#6-calibração-de-bios--gigabyte-x570-aorus-pro-wifi-f39--5950x--64-gb).

---

## 4. Invariantes de Engenharia do Sistema

- **Boot & Kernel Arguments:**
  - Linha de boot limpa upstream (`rhgb quiet root=...`). Proibido kargs redundantes (`preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`, `slab_nomerge`, `page_alloc.shuffle=1`).
  - Única exceção: `btusb.enable_autosuspend=0` em [`recipes/common-kargs.yml`](recipes/common-kargs.yml) e [`60-btusb.conf`](files/system/usr/lib/modprobe.d/60-btusb.conf) (elimina latência de handshake BT).
- **Segurança Física (Padrão Apple - Zero Unauthenticated Recovery):**
  - Proibido geradores ou drop-ins com `SYSTEMD_SULOGIN_FORCE=1` ou bypass de senha em consoles de emergência/resgate. Acesso físico de manutenção exige credencial legítima (`sulogin`).
  - Desbloqueio TPM com autenticação de 2 fatores: Hardware fTPM + PIN (`--tpm2-with-pin=yes`) vinculado a PCR 7 + 14 em [`files/system/usr/bin/kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm).
  - Bloqueio de bootloader via `grub2-setpassword` documentado em [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).
- **Sysctl & Resiliência (`90-kernel-tuning.conf`, `90-memory-fs-tuning.conf`, `90-network-tuning.conf`):**
  - *Kernel:* `printk = 4 4 1 7`, `kptr_restrict=1`, `panic=20` (janela drm_panic QR), `panic_on_oops=1`, `panic_print=33`, `hardlockup_panic=1`, `softlockup_panic=0`, `sysrq=1` (REISUB).
  - *Memória/ZRAM:* ZRAM zstd 32 GB (`min(ram / 2, 32768)` em `60-zram-policy.conf`), `vm.swappiness=150`, `vm.page-cluster=0`, `vm.watermark_scale_factor=125`, `vm.dirty_background_ratio=3`, `vm.dirty_ratio=10`, `vm.vfs_cache_pressure=50`, `fs.inotify.max_user_instances=8192`.
  - *Rede:* TCP BBR + `fq` (`60-bbr.conf`), buffers 32 MB, `tcp_slow_start_after_idle=0`, `tcp_fastopen=3`, `netdev_max_backlog=16384`, `tcp_fin_timeout=15`, `tcp_mtu_probing=1`, `tcp_rfc1337=1`, ICMP redirects bloqueados. Proibido ativar `ip_forward` globalmente.
  - *Proteção TuneD:* Symlinks em `/etc/sysctl.d/` para `/usr/lib/sysctl.d/` via `60-sysctl-protection.conf` blindam os sysctls contra sobrescrita do `tuned-ppd`.
- **Systemd, Resiliência de Logs & Timers de Atualização:**
  - Resiliência Journald ([`60-journald-resilience.conf`](files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf)): `SyncIntervalSec=30s` garante descarga rápida no NVMe Gen4 e elimina perda de logs pré-queda.
  - Boot silencioso e Plymouth contínuo (`60-kinoite-boot-quiet.conf`): `ShowStatus=error`.
  - First-boot provisioning (`kinoite-boot-init.service`): grava `menu_auto_hide=2`, `boot_success=1`, `boot_indeterminate=0` e `/boot/grub2/user.cfg` (`timeout=0`, `timeout_style=hidden`).
  - Timers de atualização (`bootc-fetch-apply-updates`, `flatpak-system-update`, `flatpak-user-update`, `podman-auto-update`, `soar-upgrade-packages`): `OnBootSec=5m`, `OnUnitActiveSec=45m`, idle priority (`Nice=19`, `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`). Sem `Persistent=true` em monotônicos.
  - Timers de manutenção (`kinoite-maintenance.timer`, `kinoite-user-maintenance.timer`): `OnCalendar=weekly`, `RandomizedDelaySec=60min`, `Persistent=true`, idle priority.
- **Armazenamento Btrfs NoCOW:**
  - Atributo `+C` estritamente via diretiva não-recursiva `h` em `60-io-tuning-system.conf` (`/var/lib/libvirt/images`, `/var/lib/containers/storage{,/volumes}`) e `60-io-tuning-user.conf` (`%h/.local/share/{libvirt/images,gnome-boxes/images,containers/storage{,/volumes}}`, `%h/.cache/rclone`, `%h/.local/state/wireplumber`). Proibido diretiva recursiva `H`.
- **Rclone FUSE (`rclone@.service`, `GoogleDrive.env`, `OneDrive.env`):**
  - Flags: `TimeoutStartSec=90s`, `SuccessExitStatus=143`, `--vfs-read-wait 5ms`, `--local-no-check-updated`, `--exclude ".Trash-**"`, sem `network-guard`.
  - Cache VFS: `max-size=15G`, `max-age=24h`, `min-free-space=15G`, `write-back=10s`, `dir-cache-time=24h`, `attr-timeout=1h`, `buffer-size=32M`, `read-ahead=64M`, `read-chunk-streams=4`.
  - Google Drive (`tpslimit=12`, `burst=100`, `chunk_size=64M`), OneDrive (`tpslimit=5`, `burst=10`, `chunk_size=50M`). Exclusão Baloo em `/etc/xdg/baloofilerc` (`[$ei]`).
- **Áudio PipeWire & Bluetooth:**
  - Quantum fixado em `256` @ `48kHz` (~5.3ms, min `256`, max `1024`, taxas `44.1k/48k/88.2k/96k`, `pulse.default.req = 256/48000` em `60-quantum-tuning.conf` e `60-pulse-quantum.conf`).
  - Quirk cirúrgico Tribit XSound Go em `60-tribit-volume-quirk.conf` (`bluez5.enable-hw-volume = false` restrito a `usb:v10D6pB009`).
- **GPU IA, Browsers & Flatpak:**
  - LLMs locais via Vulkan 1.4 RADV (Mesa 26.2). `DefaultLimitMEMLOCK=infinity` em `system.conf.d`, `user.conf.d` e `limits.d`. ACLs `TAG+="uaccess"` em `70-peripherals.rules`.
  - ROCm/HIP isolado via CDI (`/etc/cdi/amdgpu.yaml`). Proibido bibliotecas pesadas no host.
  - Browsers Flatpak (`70-browser-flags.conf`, `chromium-flags.conf`): Wayland nativo (`--ozone-platform=wayland`), DMA-BUF zero-copy, VA-API/KWin. Overrides sincronizados via `60-flatpak-overrides.conf`.
- **Higiene e Hardening Geral:**
  - DNS DoT Control D p2 primário + Cloudflare fallback em `60-dns-overrides.conf` (`DNSOverTLS=yes`, `DNSSEC=no`).
  - SSHD key-only em `50-kinoite-hardening.conf`. Blacklist CIS em `60-security-blacklist.conf`.
  - Swap preventivo OpenCL (`ocl-icd` substituindo `OpenCL-ICD-Loader` via RHBZ #2332429 em `common-tools.yml`).
  - Proibido pacotes legados (`fuse` 2) e repositórios não-oficiais conflitantes (Negativo17 rejeitado em prol do RPM Fusion Freeworld).

---

## 5. CI/CD & Governança

- **Workflows:** `check-updates.yml` (cron cada 2h) verifica digest antes de despachar `build-amd.yml` (timeout 45m). `cleanup.yml` (diário) retém 15 versões no GHCR e 3 dias de runs.
- **Segurança CI:** Actions pinadas por SHA, expressions seguras em `env:`, Dependabot semanal agrupado, segredos estritamente protegidos no `.gitignore`.

---

## 6. Rastreabilidade de Arquivos

| Subsistema | Arquivos de Implementação |
| :--- | :--- |
| **Receitas & Kargs** | [`recipes/recipe-amd.yml`](recipes/recipe-amd.yml), [`recipes/common-*.yml`](recipes/), [`files/dnf/terra.repo`](files/dnf/terra.repo), [`files/dnf/tailscale.repo`](files/dnf/tailscale.repo), [`files/system/usr/lib/modprobe.d/60-btusb.conf`](files/system/usr/lib/modprobe.d/60-btusb.conf) |
| **Sysctl, ZRAM & TuneD** | [`files/system/usr/lib/sysctl.d/90-*.conf`](files/system/usr/lib/sysctl.d/), [`files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`](files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf), [`files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf`](files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf), [`files/system/usr/lib/modules-load.d/60-bbr.conf`](files/system/usr/lib/modules-load.d/60-bbr.conf) |
| **Systemd, Boot & Timers** | [`files/system/usr/lib/systemd/system/`](files/system/usr/lib/systemd/system/), [`files/system/usr/lib/systemd/user/`](files/system/usr/lib/systemd/user/), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf), [`files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf`](files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf) |
| **Btrfs NoCOW & Flatpak** | [`files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`](files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf), [`files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`](files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf), [`files/system/usr/share/user-tmpfiles.d/70-user-dirs.conf`](files/system/usr/share/user-tmpfiles.d/70-user-dirs.conf), [`files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`](files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf), [`files/system/usr/share/flatpak/overrides/`](files/system/usr/share/flatpak/overrides/) |
| **Rclone FUSE & KDE** | [`files/system/usr/lib/systemd/user/rclone@.service`](files/system/usr/lib/systemd/user/rclone@.service), [`files/system/usr/share/rclone/env/*.env`](files/system/usr/share/rclone/env/), [`files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf`](files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf), [`files/system/etc/xdg/`](files/system/etc/xdg/) |
| **Áudio PipeWire & BT** | [`files/system/usr/share/pipewire/pipewire.conf.d/60-quantum-tuning.conf`](files/system/usr/share/pipewire/pipewire.conf.d/60-quantum-tuning.conf), [`files/system/usr/share/pipewire/pipewire-pulse.conf.d/60-pulse-quantum.conf`](files/system/usr/share/pipewire/pipewire-pulse.conf.d/60-pulse-quantum.conf), [`files/system/usr/share/wireplumber/wireplumber.conf.d/60-tribit-volume-quirk.conf`](files/system/usr/share/wireplumber/wireplumber.conf.d/60-tribit-volume-quirk.conf) |
| **GPU IA, Limites & Browsers** | [`files/system/etc/cdi/amdgpu.yaml`](files/system/etc/cdi/amdgpu.yaml), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf), [`files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf), [`files/system/etc/security/limits.d/60-kinoite-limits.conf`](files/system/etc/security/limits.d/60-kinoite-limits.conf), [`files/system/usr/share/browser-configs/chromium-flags.conf`](files/system/usr/share/browser-configs/chromium-flags.conf), [`files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf`](files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf) |
| **Sessão, CLI & Manutenção** | [`files/system/usr/lib/environment.d/60-kinoite-environment.conf`](files/system/usr/lib/environment.d/60-kinoite-environment.conf), [`files/system/etc/fonts/conf.d/64-font-rendering.conf`](files/system/etc/fonts/conf.d/64-font-rendering.conf), [`files/system/etc/profile.d/`](files/system/etc/profile.d/), [`files/system/usr/share/konsole/`](files/system/usr/share/konsole/), [`files/system/usr/share/starship/starship.toml`](files/system/usr/share/starship/starship.toml), [`files/system/usr/bin/kinoite-optimize`](files/system/usr/bin/kinoite-optimize), [`files/system/usr/bin/kinoite-consolidate-user-dirs`](files/system/usr/bin/kinoite-consolidate-user-dirs), [`files/system/usr/bin/kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm), [`files/system/etc/containers/nodocker`](files/system/etc/containers/nodocker) |
| **Segurança, Polkit & Udev** | [`files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`](files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf), [`files/system/usr/lib/modprobe.d/60-security-blacklist.conf`](files/system/usr/lib/modprobe.d/60-security-blacklist.conf), [`files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`](files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf), [`files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`](files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules), [`files/system/etc/libvirt/virtqemud.conf`](files/system/etc/libvirt/virtqemud.conf), [`files/system/usr/lib/udev/rules.d/70-peripherals.rules`](files/system/usr/lib/udev/rules.d/70-peripherals.rules), [`files/system/usr/lib/firewalld/zones/tailscale.xml`](files/system/usr/lib/firewalld/zones/tailscale.xml) |
| **Documentação & CI/CD** | [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), [`README.md`](README.md), [`SECURITY.md`](SECURITY.md), [`.github/workflows/`](.github/workflows/), [`.github/dependabot.yml`](.github/dependabot.yml) |
