# Diretrizes e Invariantes do Sistema (`AGENTS.md`)

Fonte canônica única (*Single Source of Truth*) de regras de engenharia, baseline de hardware e governança para agentes que operam no repositório `kinoite-bluebuild`.

## 1. Versionamento Git (Obrigatório)

- **Commit Obrigatório:** Toda tarefa que adicione, altere ou remova arquivos DEVE ser encerrada com commit Git estruturado e árvore limpa (`working tree clean`).
- **Conventional Commits:** `<type>(<scope>): <descrição sucinta no presente>` (`feat`, `fix`, `docs`, `refactor`, `chore`) seguido de corpo em *bullet points* detalhando decisões, parâmetros, impacto e arquivos.
- **Disciplina de Staging:** Adicionar arquivos explicitamente (`git add <arq1> <arq2>`); proibido `git add .` cego. Auditar `git status` e `git diff --cached` antes do commit, e confirmar `git status` limpo após o commit informando o hash e `git push origin <branch>`.

## 2. Princípios de Execução e Ciclo de Engenharia

- **Prioridade Absoluta:** Segurança > Performance > Conveniência.
- **Decomposição Granular de Demandas:** Nenhuma tarefa complexa deve ser executada como um bloco monolítico. Toda demanda DEVE ser dividida no maior número de tarefas pequenas, atômicas e executáveis possível. Quanto mais tarefas relevantes e bem delimitadas, menor o risco de regressão e mais simples a validação.
- **Ciclo Obrigatório de Execução (7 Fases):** Toda atividade, independentemente de ser conduzida por um ou mais agentes (sem necessidade de forçar cerimônias multiagente desnecessárias), deve seguir estritamente o fluxo contínuo:
  1. **Plan (Planejar):** Definir o objetivo técnico, pesquisar o estado da arte (upstream/web), delimitar arquivos e submeter plano estruturado ao usuário antes de editar código.
  2. **Test (Diagnosticar):** Reproduzir o estado atual, inspecionar logs ou validar hipóteses com dados reais antes de qualquer alteração.
  3. **Implement (Implementar):** Aplicar a mudança mínima necessária (KISS & DRY), sem redundâncias com defaults nativos do Fedora Kinoite (latest upstream), systemd ou kernel.
  4. **Review (Revisar):** Auditar linha a linha o diff gerado (`git diff`), garantindo conformidade estilística, higiene de formatação e zero efeitos colaterais.
  5. **Verify (Validar):** Executar testes automatizados de sintaxe e runtime (`systemd-analyze`, `udevadm test`, `sysctl`, etc.) comprovando a eficácia técnica.
  6. **Remember (Registrar):** Atualizar a memória permanente do repositório (`AGENTS.md`, `README.md`, `docs/POST_INSTALL.md` ou walkthroughs) para que o contexto nunca seja perdido em sessões futuras.
  7. **Improve (Aprimorar):** Finalizar com commit estruturado (`Conventional Commits`), árvore limpa (`working tree clean`) e propor melhorias contínuas incrementais.
- **Design e Resiliência (KISS & DRY):** Zero redundância com defaults nativos do Fedora Kinoite, systemd ou kernel. Proibido downgrade de pacotes, daemons legados ou configurações mortas. Emitir alerta e comando de rollback para alterações críticas. Respostas diretas sem preâmbulos prolixos. Scripts shell estritamente lineares e comentários técnicos concisos em inglês.

### 2.1 Protocolo de Evolução Segura de Invariantes (Guardrails Vivos)

Os invariantes deste repositório representam o baseline protetivo testado e comprovado contra falhas físicas e lógicas conhecidas. Eles operam como **guardrails protetivos vivos**, e não como dogmas estáticos intransponíveis. Quando surgir uma oportunidade de melhoria técnica, correção de bug ou evolução de upstream (Fedora, Kernel, systemd, PipeWire), o invariante pode ser ajustado ou atualizado satisfazendo estritamente os **4 Critérios de Ouro**:

1. **Evidência Técnica & Racional Upstream (Data-Driven):** Comprovação empírica ou fundamentação em documentação oficial upstream (ex.: Fedora Project, Kernel.org, Freedesktop, PipeWire, BlueZ) demonstrando a superioridade técnica ou necessidade do novo ajuste.
2. **Análise de Raio de Impacto (Blast Radius & Anti-Regressão):** Demonstração explícita de que a alteração NÃO reintroduzirá o modo de falha físico ou lógico que motivou o invariante original (ex.: reflexão de sinal em barramento DRAM, C6 lockup, buffer underrun de áudio, corrupção Btrfs).
3. **Transação Atômica no Git:** A alteração do invariante no `AGENTS.md` e a modificação do código/configuração DEVEM ser consolidadas no mesmo commit Git, preservando a sincronia contínua da documentação canônica com a base de código.
4. **Rollback Garantido & Comando Instantâneo:** Fornecimento obrigatório de comando direto para reverter a alteração ao baseline seguro anterior caso ocorra qualquer instabilidade.

#### Taxonomia de Risco para Evolução:

| Tier de Risco | Abrangência | Exigência para Evolução |
| :--- | :--- | :--- |
| **Tier 1 (Crítico / Hardware & Boot)** | Kernel bootargs, initramfs, partição /boot, LUKS/TPM, firmware e limites de hardware | Rigor máximo: embasamento em documentação do kernel/upstream e validação ativa de estabilidade (`rasdaemon`, `stressapptest`, `POST_INSTALL.md §6`). |
| **Tier 2 (Médio / SO & Kernel)** | Linha de boot (kargs), sysctl, ZRAM, Btrfs NoCOW, PipeWire buffers | Rigor técnico: validação automatizada de sintaxe e runtime (`sysctl -p`, `systemd-analyze`, logs de sistema limpos). |
| **Tier 3 (Ágil / Apps & UX)** | Flags de browser, Rclone, fontes, aliases, timers de manutenção | Rigor ágil: evolução contínua alinhada às versões upstream, priorizando DRY/KISS e zero legado. |

## 3. Hardware Baseline e Requisitos da Estação

- **Perfil Homologado:** AMD Ryzen 9 5950X (16C/32T, Zen 3, dual-CCD), AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23 / RDNA2), Gigabyte X570 AORUS PRO WIFI, 64 GB DDR4 (4×16 GB), NVMe 1 TB PCIe Gen4 (Btrfs), Fedora Kinoite (`bootc:latest`, Wayland, KDE Plasma 6, Kernel `7.2+`).
- **Mapeamento de Hardware para Configurações do Repositório:**
  - **CPU (Zen 3):** Linha de boot nativa com escalonador `amd-pstate-epp` e C-states upstream do Fedora.
  - **GPU (Navi 23 / RDNA2):** Mesa `radv` (Vulkan 1.4), aceleração VA-API no KWin/Wayland e contêineres ROCm/HIP via CDI (`/etc/cdi/amdgpu.yaml` com `HSA_OVERRIDE_GFX_VERSION=10.3.0`).
  - **Memória (64 GB):** ZRAM `zstd` provisionado em 32 GB (`60-zram-policy.conf`) e `DefaultLimitMEMLOCK=infinity` (`60-kinoite-limits.conf`) para alocação direta de modelos GGUF (`--mlock`).
  - **Armazenamento (Btrfs):** Atributo NoCOW `+C` estrito via tmpfiles `h` em diretórios de VMs e contêineres (`60-io-tuning-system.conf` e `60-io-tuning-user.conf`).
  - **Periféricos:** Headset USB MCHOSE X9, fones BT Baseus Bass EP10 Pro, caixa Tribit XSound Go (quirk cirúrgico em `60-tribit-volume-quirk.conf`), mouses HID VXE e BY Tech (`TAG+="uaccess"` em `70-peripherals.rules`).
- **Firmware & Calibração de BIOS (Responsabilidade Operacional do Host):**
  - A calibração física de BIOS (tensões elétricas, XMP, temporizações JEDEC, CPPC, IOMMU e Re-Size BAR/SAM) é realizada manualmente pelo operador do host no UEFI Setup e está documentada no runbook [`docs/POST_INSTALL.md` §6](docs/POST_INSTALL.md#6-calibração-de-bios--gigabyte-x570-aorus-pro-wifi-f39--5950x--64-gb).

## 4. Invariantes de Engenharia do Sistema

- **Linha de Boot (Zero Custom Kargs + Exceção `btusb`):**
  - Opera na baseline nativa do Fedora upstream (`rhgb quiet root=...`), onde `amd-pstate-epp` (`CONFIG_X86_AMD_PSTATE_DEFAULT_MODE=3`), SLAB unmerged, DMA lazy (`CONFIG_IOMMU_DEFAULT_DMA_LAZY=y`) e TSC invariant já são nativos.
  - **Única exceção homologada:** `btusb.enable_autosuspend=0` em [`recipes/common-kargs.yml`](recipes/common-kargs.yml) e [`60-btusb.conf`](files/system/usr/lib/modprobe.d/60-btusb.conf) para eliminar latência de handshake Bluetooth.
  - **Anti-Padrões e Parâmetros Nocivos / Desnecessários no Baseline (Salvo evolução fundamentada via §2.1):** `preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`, `slab_nomerge`, `page_alloc.shuffle=1`.
- **Sysctl, Resiliência de Kernel & Proteção TuneD:**
  - Anti-padrão: redeclarar defaults nativos do Fedora/kernel (`dmesg_restrict`, `unprivileged_bpf_disabled`, `vm.max_map_count`, `fs.inotify.max_user_watches`).
  - Resiliência (`90-kernel-tuning.conf`): `kernel.printk = 3 3 1 7` (suprime ruídos e advertências cosméticas de ACPI/firmware no console virtual), `kernel.kptr_restrict=1`, `kernel.panic=10`, `kernel.panic_on_oops=1`, `kernel.hardlockup_panic=1`, `kernel.softlockup_panic=0` (evita reboot prematuro em esperas de I/O de VM/Btrfs) e `kernel.sysrq=1` (REISUB ativo).
  - Memória/ZRAM (`90-memory-fs-tuning.conf` + `60-zram-policy.conf`): ZRAM zstd até 32 GB (`min(ram / 2, 32768)`), `vm.swappiness=150`, `vm.page-cluster=0`, `vm.watermark_scale_factor=125`, `vm.dirty_background_ratio=3`, `vm.dirty_ratio=10`, `vm.vfs_cache_pressure=50`, `fs.inotify.max_user_instances=8192`.
  - Rede (`90-network-tuning.conf` + `60-bbr.conf`): TCP BBR + `fq`, buffers de 32 MB, `tcp_slow_start_after_idle=0`, `tcp_fastopen=3` (cliente + servidor TFO), `netdev_max_backlog=16384`, `tcp_fin_timeout=15`, `tcp_mtu_probing=1`, `tcp_rfc1337=1` e bloqueio de ICMP redirects. Anti-padrão de segurança: habilitar `net.ipv4.ip_forward` ou forwarding IPv6 globalmente.
  - Proteção TuneD (`60-sysctl-protection.conf`): Symlinks em `/etc/sysctl.d/` apontando para `/usr/lib/sysctl.d/` garantem que o `tuned-ppd` (`reapply_sysctl=1`) preserve os sysctls da imagem ao alternar perfis de energia do KDE.
- **Arquitetura `bootc`, First-Boot & Timers de Atualização:**
  - Boot silencioso e Plymouth contínuo (`60-kinoite-boot-quiet.conf` em `system.conf.d`): `ShowStatus=error` suprime mensagens de progresso (`[  OK  ]`) e animações de espera (`[ *** ]`) que vazam para a tela durante a transição do DRM `amdgpu`, mantendo a exibição imediata no console estritamente se ocorrer falha real (`[FAILED]`).
  - First-boot provisioning (`kinoite-boot-init.service`): unidade oneshot segura com `ConditionPathExists=!/var/lib/kinoite-boot-init-v2-done` que grava `menu_auto_hide=2`, `boot_success=1`, `boot_indeterminate=0` e `/boot/grub2/user.cfg` (`timeout=0`, `timeout_style=hidden`) para garantir boot silencioso sob múltiplos deployments ostree (zero overhead subsequente).
  - Timers de atualização (`bootc-fetch-apply-updates`, `flatpak-system-update`, `flatpak-user-update`, `podman-auto-update` system/user, `soar-upgrade-packages`) operam com `OnBootSec=5m`, `OnUnitActiveSec=45m` e prioridades em idle (`Nice=19`, `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`). Timers monotônicos não usam `Persistent=true`.
  - Timers semanais de manutenção (`kinoite-maintenance.timer`, `kinoite-user-maintenance.timer`) operam com `OnCalendar=weekly`, `RandomizedDelaySec=60min`, `Persistent=true` e prioridade ociosa para poda de contêineres/volumes órfãos do Podman e rotação de journald (anti-padrão: recriar `/etc/rpm-ostreed.conf`).
- **Armazenamento Btrfs NoCOW & `tmpfiles.d`:**
  - Aplicar atributo `+C` (NoCOW) exclusivamente via diretiva não-recursiva `h` em `60-io-tuning-system.conf` (`/var/lib/libvirt/images`, `/var/lib/containers/storage{,/volumes}`) e `60-io-tuning-user.conf` (`%h/.local/share/{libvirt/images,gnome-boxes/images,containers/storage{,/volumes}}`, `%h/.cache/rclone` e `%h/.local/state/wireplumber` com modo estrito `0700`).
  - Anti-padrão Btrfs: usar diretiva recursiva `H` (falha em arquivos não-vazios) ou caminhos inexistentes (`/var/lib/docker`, `/var/lib/distrobox`). Diretivas `C+` são atômicas (anti-padrão: `r!` prévio).
- **Montagens FUSE Rclone (`rclone@.service`, `GoogleDrive.env`, `OneDrive.env`):**
  - Template `rclone@.service` com `TimeoutStartSec=90s`, `SuccessExitStatus=143`, `--vfs-read-wait 5ms`, `--local-no-check-updated`, `--exclude ".Trash-**"`, `--exclude ".Trash/**"`, sem `network-guard` e anti-padrão `--vfs-refresh`.
  - Cache VFS padrão: `max-size=15G`, `max-age=24h`, `min-free-space=15G`, `write-back=10s`, `dir-cache-time=24h`, `attr-timeout=1h`, `buffer-size=32M`, `read-ahead=64M`, `read-chunk-streams=4`.
  - **Google Drive:** `tpslimit=12`, `burst=100`, `pacer_min_sleep=10ms`, `list_chunk=1000`, `chunk_size=64M`, `use_trash=true`, `skip_gdocs=true` e uso recomendado de Client ID OAuth 2.0 próprio publicado (20.000 req/100s).
  - **OneDrive:** `tpslimit=5`, `burst=10`, `chunk_size=50M` (múltiplo exato de 320 KiB), `delta=true`, `list_chunk=1000`, `poll_interval=1m`.
  - **Higiene de Exclusão & Baloo:** `ShowDeleteCommand=true` em `/etc/xdg/kdeglobals`, `ConfirmDelete=true` e `ConfirmTrash=false` em `/etc/xdg/dolphinrc` habilitam exclusão permanente direta sem criar `.Trash-$UID`. Rclone bloqueia sincronização de `.Trash-*` via flags `--exclude`. `kinoite-optimize` purga resíduos e roda `rclone dedupe --dedupe-mode newest`. Exclusão imutável de `$HOME/Cloud` e `/run/user` em `/etc/xdg/baloofilerc` (`[$ei]`).
- **Áudio PipeWire & Bluetooth:**
  - Buffer quântico calibrado em `60-quantum-tuning.conf` e `60-pulse-quantum.conf`: quantum `256` @ `48kHz` (~5.3ms, min `256`, max `1024`, taxas `44.1k/48k/88.2k/96k`, `pulse.default.req = 256/48000` sem forçar `min.quantum < 256` ou `default.frag` para evitar packet starvation A2DP e cortes HFP/mSBC).
  - Quirk cirúrgico em `60-tribit-volume-quirk.conf` (`bluez5.enable-hw-volume = false` restrito ao `Tribit XSound Go` `usb:v10D6pB009`); anti-padrão: desativar `hw-volume` globalmente em fones TWS (`Baseus Bass EP10 Pro`) ou redeclarar defaults nativos do PipeWire 1.6 / WirePlumber 0.5 (`sbc-xq`, `msbc`, `autoswitch-to-headset-profile`).
- **GPU IA (Vulkan RADV & ROCm CDI), Browsers & Flatpak Overrides:**
  - Inferência local no host (`llama.cpp`, GGUF) acelerada nativamente por **Vulkan 1.4 (`radv` Mesa 26.2)** sem inflar a imagem base com bibliotecas `rocblas`/`hipblas`.
  - Memória paginada/fixada sem limite (`DefaultLimitMEMLOCK=infinity` em `60-kinoite-limits.conf` de `system.conf.d`, `user.conf.d` e `limits.d`) para permitir `--mlock` de modelos GGUF nos 64 GB de RAM e alocação DMA de VRAM/GTT sem erro `ENOMEM`, mais ACLs dinâmicas `TAG+="uaccess"` para `/dev/kfd` e `/dev/dri/renderD*` em `70-peripherals.rules`.
  - Aceleração ROCm/HIP pesada (Ollama, PyTorch, vLLM) containerizada via CDI em `/etc/cdi/amdgpu.yaml` (`--device amd.com/gpu=all`, `HSA_OVERRIDE_GFX_VERSION=10.3.0`; anti-padrão: instalar bibliotecas `rocblas`/`hipblas` pesadas diretamente no host).
  - Browsers Flatpak (`Brave`, `Chrome`, `Firefox` em `common-flatpaks.yml`) provisionados via `70-browser-flags.conf` e `chromium-flags.conf` com Wayland nativo (`--ozone-platform=wayland`), rasterização zero-copy DMA-BUF (`--enable-gpu-rasterization`, `--enable-zero-copy`, `--ignore-gpu-blocklist`), VA-API/KWin (`VaapiIgnoreDriverChecks`, `AcceleratedVideoEncoder`, `UiGpuRasterization`, `WaylandOverlayDelegation`, `WaylandTextInputV3`, `ZeroCopyDesktopCapture`, `WebRtcPipeWireCamera`, `ParallelDownloading`) e integração D-Bus KDE Plasma (`60-flatpak-overrides.conf`); anti-padrão no Wayland: `--enable-vulkan` ou flags legadas/removidas (`AcceleratedVideoDecodeLinuxZeroCopyGL` / `AcceleratedVideoDecodeLinuxGL` / `WebRTCPipeWireCapturer` / `CloudImportClient`).
  - Overrides Flatpak em `/usr/share/flatpak/overrides/` sincronizados para `/var/lib/flatpak/overrides/` via `60-flatpak-overrides.conf` (anti-padrão: `/etc/flatpak/overrides/`).
- **Sessão, Segurança, Virtualização & Higiene de Pacotes:**
  - Variáveis de sessão exclusivamente em `60-kinoite-environment.conf`; scripts `profile.d` usam apenas lógica interativa com `return 0 2>/dev/null` (anti-padrão: `exit 0`).
  - DNS DoT Control D p2 primário + Cloudflare fallback (`76.76.2.11#p2.freedns.controld.com` / `1.1.1.1#cloudflare-dns.com`, `DNSOverTLS=yes`, `DNSSEC=no` [compatibilidade obrigatória para adblock/p2 evitando loops de degradação]) em `60-dns-overrides.conf`.
  - SSHD key-only (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`) em `50-kinoite-hardening.conf`.
  - Blacklist CIS (`sctp`, `tipc`, `jffs2`, `hfs`, `hfsplus`, `firewire-core` via `install <mod> /bin/false`) em `60-security-blacklist.conf` (anti-padrão: listar módulos inexistentes no kernel 7.2 como `dccp`/`cramfs`/`freevxfs` ou já cobertos como `rds`).
  - Polkit libvirt em `51-kinoite-libvirt.rules` (sem colidir com `50-libvirt.rules` upstream) e IPC elevado para 20 clientes em `/etc/libvirt/virtqemud.conf`.
  - Higiene RPM (Anti-padrão: pacotes legados/órfãos como `fuse` 2, `podman-machine`, encoders redundantes).

## 5. CI/CD, Supply Chain e Segurança de Governança

- **Workflows:** `check-updates.yml` (`0 */2 * * *`, timeout `5m`) apenas restaura o cache de digest e verifica runs ativas antes de acionar `build-amd.yml` (timeout `45m`), que grava o cache unicamente após sucesso. `cleanup.yml` (diário, timeout `10m`) retém 15 versões no GHCR (~3 imagens completas com assinaturas Cosign), 3 dias de runs (mín. 3) e limpa caches órfãos.
- **Hardening CI:** Actions pinadas por SHA completo, `concurrency` com `cancel-in-progress: true`, `permissions` mínimas, expressões `${{ ... }}` isoladas em variáveis `env:` (anti-injection), inputs `required: true` preservados (`pr_event_number`), Dependabot semanal agrupado (`chore(deps)`, máx. 3 PRs).
- **Governança:** Nunca versionar segredos/tokens no Git (`.gitignore` protege `rclone.conf`, `*.token`, `*.secret`, `*.local.env`, `*.local.md`).

## 6. Rastreabilidade de Arquivos

| Subsistema | Arquivos de Implementação |
| :--- | :--- |
| **Receitas & Kargs** | [`recipes/recipe-amd.yml`](recipes/recipe-amd.yml), [`recipes/common-*.yml`](recipes/), [`files/system/usr/lib/modprobe.d/60-btusb.conf`](files/system/usr/lib/modprobe.d/60-btusb.conf) |
| **Sysctl, ZRAM & TuneD** | [`files/system/usr/lib/sysctl.d/90-*.conf`](files/system/usr/lib/sysctl.d/), [`files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`](files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf), [`files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf`](files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf), [`files/system/usr/lib/modules-load.d/60-bbr.conf`](files/system/usr/lib/modules-load.d/60-bbr.conf) |
| **Systemd, Boot & Timers** | [`files/system/usr/lib/systemd/system/`](files/system/usr/lib/systemd/system/), [`files/system/usr/lib/systemd/user/`](files/system/usr/lib/systemd/user/), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf) |
| **Btrfs NoCOW & Flatpak** | [`files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`](files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf), [`files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`](files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf), [`files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`](files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf), [`files/system/usr/share/flatpak/overrides/`](files/system/usr/share/flatpak/overrides/) |
| **Rclone FUSE & KDE** | [`files/system/usr/lib/systemd/user/rclone@.service`](files/system/usr/lib/systemd/user/rclone@.service), [`files/system/usr/share/rclone/env/*.env`](files/system/usr/share/rclone/env/), [`files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf`](files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf), [`files/system/etc/xdg/`](files/system/etc/xdg/) |
| **Áudio PipeWire & BT** | [`files/system/usr/share/pipewire/pipewire.conf.d/60-quantum-tuning.conf`](files/system/usr/share/pipewire/pipewire.conf.d/60-quantum-tuning.conf), [`files/system/usr/share/pipewire/pipewire-pulse.conf.d/60-pulse-quantum.conf`](files/system/usr/share/pipewire/pipewire-pulse.conf.d/60-pulse-quantum.conf), [`files/system/usr/share/wireplumber/wireplumber.conf.d/60-tribit-volume-quirk.conf`](files/system/usr/share/wireplumber/wireplumber.conf.d/60-tribit-volume-quirk.conf) |
| **GPU IA, Limites & Browsers** | [`files/system/etc/cdi/amdgpu.yaml`](files/system/etc/cdi/amdgpu.yaml), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf), [`files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf), [`files/system/etc/security/limits.d/60-kinoite-limits.conf`](files/system/etc/security/limits.d/60-kinoite-limits.conf), [`files/system/usr/share/browser-configs/chromium-flags.conf`](files/system/usr/share/browser-configs/chromium-flags.conf), [`files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf`](files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf) |
| **Sessão, CLI & Manutenção** | [`files/system/usr/lib/environment.d/60-kinoite-environment.conf`](files/system/usr/lib/environment.d/60-kinoite-environment.conf), [`files/system/etc/fonts/conf.d/64-font-rendering.conf`](files/system/etc/fonts/conf.d/64-font-rendering.conf), [`files/system/etc/profile.d/`](files/system/etc/profile.d/), [`files/system/usr/share/konsole/`](files/system/usr/share/konsole/), [`files/system/usr/share/starship/starship.toml`](files/system/usr/share/starship/starship.toml), [`files/system/usr/bin/kinoite-optimize`](files/system/usr/bin/kinoite-optimize), [`files/system/usr/bin/kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm), [`files/system/etc/containers/nodocker`](files/system/etc/containers/nodocker) |
| **Segurança, Polkit & Udev** | [`files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`](files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf), [`files/system/usr/lib/modprobe.d/60-security-blacklist.conf`](files/system/usr/lib/modprobe.d/60-security-blacklist.conf), [`files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`](files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf), [`files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`](files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules), [`files/system/etc/libvirt/virtqemud.conf`](files/system/etc/libvirt/virtqemud.conf), [`files/system/usr/lib/udev/rules.d/70-peripherals.rules`](files/system/usr/lib/udev/rules.d/70-peripherals.rules), [`files/system/usr/lib/firewalld/zones/tailscale.xml`](files/system/usr/lib/firewalld/zones/tailscale.xml) |
| **Documentação, CI/CD & Testes** | [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), [`README.md`](README.md), [`SECURITY.md`](SECURITY.md), [`.github/workflows/`](.github/workflows/), [`.github/dependabot.yml`](.github/dependabot.yml), [`tests/`](tests/) |
