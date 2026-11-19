# Diretrizes Lineares do Projeto (kinoite-bluebuild)

## Arquitetura Geral e Hardware

- O projeto é modular, declarativo e organizado em camadas BlueBuild sobre Fedora Kinoite (Fedora 45+) gerenciado via Bootc.
- A árvore `/usr/lib/` e `/usr/share/` concentra as configurações do sistema para manter `/etc/` limpo.
- O flavor `kinoite-amd` atende sistemas 100% AMD sem nenhum arquivo, driver ou karg NVIDIA.
- O flavor `kinoite-cuda` herda toda a base AMD e adiciona a camada de drivers e isolamento headless NVIDIA para CUDA/compute.
- A estação de referência usa Ryzen 9 5950X (`amd-pstate-epp` quando CPPC e Cool'n'Quiet/PSS estão habilitados na BIOS), placa Gigabyte X570 AORUS PRO WIFI em UEFI com Secure Boot e fTPM 2.0, 64 GB DDR4 e 32 GB ZRAM zstd.
- A GPU primária é a AMD Radeon RX 6600 XT (`amdgpu`), dedicada a display Wayland, KDE Plasma 6, Vulkan RADV, VA-API e VMs.
- A GPU secundária é a NVIDIA RTX 3080 Ti (`nvidia`), isolada em modo headless exclusivamente para CUDA, PyTorch e LLMs locais via CDI.
- O armazenamento usa NVMe PCIe Gen4 de 1 TB em Btrfs e discos auxiliares de 1 TB; a rede usa Intel I211 GbE e Intel Wi-Fi 6E AX210.
- Os periféricos USB homologados são receptores VXE/Compx (`3554`), headset MCHOSE X9 (`3837`), teclado BY Tech (`258a`), LED ITE (`048d`) e interfaces ADB/Fastboot Android (`18d1`, `2a70`, `22d9`, `04e8`, `22b8`, `2717`, `05c6`, `0e8d`).

## Estrutura do Repositório e Documentação

- `recipes/` reúne os manifestos principais (`recipe-*.yml`) e `recipes/modules/` reúne os módulos por domínio (`base-*`, `desktop-*`, `nvidia-headless.yml`).
- `files/base/` contém as configurações essenciais de sistema operacional, kernel, armazenamento, segurança, rede, timers e utilitários CLI.
- `files/desktop/` contém as configurações de ambiente gráfico KDE Plasma, fontes, terminal, shell e overrides mínimos de Flatpak.
- `files/cloud/` contém o serviço de usuário e perfis de montagem FUSE do Rclone.
- `files/nvidia/` contém exclusivamente os arquivos de suporte e isolamento headless da GPU NVIDIA.
- `files/dnf/` contém as definições de repositórios externos RPM.
- `AGENTS.md` define processo, Git, validações pré-commit e categorias de consulta para agentes de IA.
- `PROJECTS.md` mantém o catálogo linear completo de arquitetura, hardware, arquivos e invariantes do projeto.
- `README.md` apresenta visão geral, comandos de troca de imagem e estrutura do repositório em inglês.
- `SECURITY.md` documenta a política de verificação Cosign e permissões mínimas do CI/CD em inglês.
- `docs/POST_INSTALL.md` documenta o guia pós-instalação de TPM 2.0, BIOS CPPC, Rclone, manutenção, limpeza de resíduos legados e recuperação em português do Brasil.
- `LICENSE` declara a licença Apache 2.0 do projeto.
- `.gitignore` exclui artefatos locais e temporários mantendo regras, documentação e chaves públicas rastreados.

## Receitas BlueBuild

- `recipes/recipe-amd.yml`: compila a imagem limpa `kinoite-amd` para sistemas exclusivos AMD usando os overlays `files/base/`, `files/desktop/` e `files/cloud/`.
- `recipes/recipe-cuda.yml`: compila a imagem `kinoite-cuda` para estações AMD + NVIDIA headless (CUDA/compute), inserindo `nvidia-headless.yml` antes dos units systemd finais e `initramfs`.
- `recipes/modules/base-packages.yml`: consolida em camada única DNF a remoção de bloat e daemons Intel incompatíveis (`firefox`, `kwrite`, `plasma-discover-rpm-ostree`, `plasma-discover-notifier`, `thermald`, `intel-lpmd`), localização `langpacks-pt_BR`, integração KDE (`kio-admin`, `ksshaskpass`, `plasma-firewall`, `qt6-qtimageformats`, `lm_sensors`), `rsms-inter-vf-fonts`, codecs RPM Fusion (`mesa-va-drivers-freeworld`, `ffmpeg`, `libva-utils`, `libheif-freeworld`, GStreamer), pilha KVM enxuta com GNOME Boxes e virt-manager (`qemu-kvm`, `libvirt-daemon-kvm`, `libvirt-daemon-config-network`, `libvirt-client`, `edk2-ovmf`, `swtpm`, `swtpm-tools`, `gnome-boxes`, `virt-manager`, `virt-install`) e ferramentas CLI (`topgrade`, `starship`, `fastfetch`, `tailscale`, `git`, `rclone`, `distrobox`, `nvtop`, `vulkan-tools`).
- `recipes/modules/desktop-fonts.yml`: instala Nerd Fonts (`FiraCode`, `JetBrainsMono`, `NerdFontsSymbolsOnly`).
- `recipes/modules/nvidia-headless.yml`: compila `nvidia-open` via akmods (`MULTILIB=0`), aplica os arquivos de `files/nvidia/`, habilita `nvidia-persistenced.service` e mascara `nvidia-powerd.service`.
- `recipes/modules/desktop-flatpaks.yml`: declara os 25 aplicativos Flatpak de sistema via módulo `default-flatpaks` v2 (incluindo `com.github.wwmm.easyeffects` e `org.kde.okular`).
- `recipes/modules/base-systemd.yml`: habilita timers/serviços de sistema e usuário e mascara unidades desnecessárias (`NetworkManager-wait-online.service`, `dnf-makecache.timer`, `lm_sensors.service`, `raid-check.timer`, `drkonqi-coredump-pickup.service`), mantendo `ModemManager.service` intacto para `NetworkManager-bluetooth` e deixando `systemd-remount-fs.service`, `tuned-ppd`, GRUB e sockets modulares do libvirt nos presets nativos do Fedora 45.

## Kernel Arguments e Isolamento NVIDIA

- O flavor `kinoite-amd` utiliza zero kargs customizados sobre o baseline upstream do Fedora 45 (`simpledrm` não é mais bloqueado).
- `rd.driver.blacklist=nouveau` e `modprobe.blacklist=nouveau` bloqueiam `nouveau` no initramfs e userspace da imagem `kinoite-cuda`.
- `rd.driver.blacklist=nvidia-drm` e `modprobe.blacklist=nvidia-drm` impedem nó gráfico DRM na NVIDIA preservando nós CUDA (`/dev/nvidia*`).
- `files/nvidia/usr/lib/bootc/kargs.d/00-bluebuild-nvidia-kargs.toml`: sobrescreve os kargs do akmods eliminando `nvidia-drm.modeset=1` e aplicando blacklist de `nouveau` e `nvidia-drm`.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia.conf`: mantém apenas `amdgpu` em `force_drivers` para carregar módulos NVIDIA sob demanda no userspace.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia-headless.conf`: omite `nvidia_drm` e `nvidia-drm` do initramfs.
- `files/nvidia/usr/lib/modprobe.d/60-nvidia-headless.conf`: bloqueia `nvidia-drm` redirecionando para `/usr/bin/true` e ativa Resizable BAR na RTX 3080 Ti.
- `files/nvidia/usr/lib/environment.d/60-nvidia-headless.conf`: força `__EGL_VENDOR_LIBRARY_FILENAMES`, `__GLX_VENDOR_LIBRARY_NAME=mesa` e `VK_DRIVER_FILES` (RADV) para impedir que aplicações host capturem EGL, GLX ou Vulkan da NVIDIA.
- `files/nvidia/usr/lib/tmpfiles.d/60-nvidia-headless.conf`: prioriza Mesa EGL via symlink `/etc/glvnd/egl_vendor.d/00_mesa.json` para daemons com ambiente limpo (`virtqemud`/`qemu`) preservando `10_nvidia.json` para CDI.
- `files/nvidia/etc/pki/akmods/certs/akmods-ublue.der`: fornece o certificado público MOK para validação dos módulos akmods no Secure Boot.

## Armazenamento, ZRAM, Memória e Segurança

- `files/base/usr/lib/tmpfiles.d/60-io-tuning-system.conf`: aplica Btrfs NoCOW (`+C`) em `/var/lib/libvirt/images` e `/var/lib/containers/storage`.
- `files/base/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`: aplica Btrfs NoCOW (`+C`) em imagens de VMs, contêineres rootless e cache do rclone.
- `files/base/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`: configura swap ZRAM zstd em 50% da RAM até 32 GB.
- `files/base/usr/lib/sysctl.d/90-kinoite.conf`: consolida `kernel.sysrq=1` (REISUB), `kernel.kptr_restrict=1`, `fs.inotify.max_user_instances=8192`, tuning ZRAM (`vm.swappiness=150`, `vm.page-cluster=0`), limites fixos de writeback NVMe (`vm.dirty_background_bytes=67108864`, `vm.dirty_bytes=268435456`), TCP BBR/FQ, `tcp_mtu_probing=1`, `tcp_rfc1337=1` e bloqueio de redirects ICMP.
- `files/base/etc/security/limits.d/60-kinoite-limits.conf`: libera `memlock unlimited` em sessões PAM/SSH.
- `files/base/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`: define `DefaultLimitMEMLOCK=infinity` no systemd de sistema.
- `files/base/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf`: define `DefaultLimitMEMLOCK=infinity` no systemd de usuário.
- `files/base/usr/lib/modprobe.d/60-hardware-tuning.conf`: desativa economia de energia e ativa modo ativo no Wi-Fi 6E Intel AX210 (`iwlwifi`/`iwlmvm`).
- `files/base/usr/lib/modprobe.d/60-security-blacklist.conf`: redireciona protocolos/filesystems obsoletos (`sctp`, `tipc`, `jffs2`, `hfs`, `hfsplus`, `firewire-core`) para `/usr/bin/true`.
- `files/base/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`: endurece SSH exigindo autenticação por chave, sem root e sem X11.
- `files/base/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf`: reduz `SyncIntervalSec` do journald para 30s e aplica retenção contínua (`SystemMaxUse=200M`, `MaxRetentionSec=14day`).
- `files/base/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`: define `ShowStatus=error` para boot silencioso exibindo apenas falhas.
- `files/base/usr/lib/dracut/dracut.conf.d/60-kinoite-initrd.conf`: inclui `/etc/nsswitch.conf`, `/usr/lib/{group,passwd}` e `60-kinoite-boot-quiet.conf` no initramfs não-hostonly para resolver grupos via `nss-altfiles` em `udevd`/`tmpfiles`.
- `files/base/usr/lib/modules-load.d/60-bbr.conf`: carrega `sch_fq` e `tcp_bbr` no boot.
- `files/base/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`: configura Control D (`p2`) e fallback Cloudflare com `DNSOverTLS=opportunistic`, `DNSSEC=no`, `MulticastDNS=no` e `LLMNR=no` para interoperar com Tailscale MagicDNS e redes locais.
- `files/base/usr/lib/firewalld/zones/tailscale.xml`: declara zona confiável do firewall para a interface `tailscale0`.
- `files/dnf/tailscale.repo`: configura o repositório oficial da Tailscale.
- `files/dnf/terra.repo`: configura o repositório Terra da Fyra Labs.

## Serviços, Timers e Manutenção

- Os timers recorrentes de atualização (`bootc` e Flatpak) rodam em `Type=oneshot` com prioridade ociosa (`Nice=19`, `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`), apenas em AC (`ConditionACPower=true`), 10 min após o boot e a cada 4h (`OnUnitInactiveSec=4h`, `RandomizedDelaySec=15m`) com `ExecCondition=/usr/bin/nm-online -q -t 30`; units de usuário usam `ConditionUser=!@system` para ignorar o greeter `plasmalogin`.
- `files/base/usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/override.conf`: executa `/usr/bin/bootc upgrade --quiet` em `Type=oneshot` (staged sem reboot automático) em prioridade ociosa na tomada.
- `files/base/usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/override.conf`: agenda busca de updates do SO após 10m do boot e a cada 4h.
- `files/base/usr/lib/systemd/system/flatpak-system-update.service`: atualiza Flatpaks de sistema e remove runtimes órfãos.
- `files/base/usr/lib/systemd/system/flatpak-system-update.timer`: dispara atualização de Flatpaks de sistema após 10m do boot e a cada 4h.
- `files/base/usr/lib/systemd/user/flatpak-user-update.service`: atualiza Flatpaks de usuário e limpa runtimes sem uso (`ConditionUser=!@system`).
- `files/base/usr/lib/systemd/user/flatpak-user-update.timer`: dispara atualização de Flatpaks de usuário após 10m do login e a cada 4h (`ConditionUser=!@system`).
- `files/base/usr/lib/systemd/user/drkonqi-coredump-cleanup.timer.d/override.conf`: corrige o ciclo de ordenação upstream do KDE Plasma com `timers.target` (`DefaultDependencies=no`).
- `files/base/usr/lib/systemd/user/plasma-startupsound.service.d/override.conf`: ordena o som de login após `pipewire-pulse`/`wireplumber` com retentativa tolerante a negociação Bluetooth.
- `files/base/usr/share/wireplumber/wireplumber.conf.d/51-bluez-keepalive.conf`: desativa `node.suspend-on-idle` e `session.suspend-timeout-seconds` em nós `bluez_output.*` para evitar `AVDTP START: Bad State (49)`.
- `files/base/usr/lib/systemd/user/podman-auto-update.timer.d/override.conf`: impede execução do timer diário upstream do Podman para contas `@system` como `plasmalogin`.
- `files/base/usr/lib/systemd/user/podman-restart.service.d/override.conf`: impede execução de `podman-restart.service` para contas `@system` como `plasmalogin`.
- `files/base/usr/lib/systemd/system/kinoite-btrfs-scrub.service`: executa `btrfs scrub start -B /var/home` em prioridade idle somente em alimentação AC.
- `files/base/usr/lib/systemd/system/kinoite-btrfs-scrub.timer`: agenda o scrub mensal de `/var/home`.
- `files/base/usr/lib/systemd/system/kinoite-maintenance.service`: remove imagens Podman órfãs (`podman image prune -f`) preservando contêineres parados e volumes.
- `files/base/usr/lib/systemd/system/kinoite-maintenance.timer`: agenda limpeza semanal de sistema.
- `files/base/usr/lib/systemd/user/kinoite-user-maintenance.service`: remove imagens Podman órfãs do usuário e thumbnails > 30 dias (`ConditionUser=!@system`) preservando contêineres e volumes.
- `files/base/usr/lib/systemd/user/kinoite-user-maintenance.timer`: agenda limpeza semanal de usuário (`ConditionUser=!@system`).
- `files/base/etc/NetworkManager/dispatcher.d/04-iscsi`: sobrescreve o dispatcher upstream do `iscsi-initiator-utils` para recarregar `iscsi.service` apenas quando ativo.
- `files/base/usr/share/smartmontools/smartd.conf`: monitora discos compatíveis com SMART sem sondagem ATA `-n standby` em pontes USB.
- `files/base/usr/lib/systemd/system/smartd.service.d/override.conf`: aponta `smartd.service` para `/usr/share/smartmontools/smartd.conf` mantendo `$smartd_opts`.
- `files/base/usr/bin/kinoite-optimize`: executa manutenção local segura em 5 fases (sysctl/tmpfiles e limpeza de resíduos legados, NoCOW, Btrfs/VMs, caches/imagens sem podman container/volume prune) e auditoria somente leitura `--audit` dos 5 pilares com checagem SIGPIPE-safe de MOK e alerta informativo de `cpufreq`.
- `files/base/usr/bin/kinoite-setup-tpm`: vincula partição LUKS2 ao fTPM 2.0 (PCRs 7+14) com suporte a PIN, chave de recuperação e atualização segura de `/etc/crypttab`.

## Desktop KDE, Navegadores e Terminal

- `files/desktop/usr/lib/environment.d/60-desktop-environment.conf`: exporta `FREETYPE_PROPERTIES` para renderização tipográfica nítida com stem darkening.
- `files/desktop/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`: aplica overrides Flatpak declarativos (`global` e `com.brave.Browser`).
- `files/desktop/usr/share/flatpak/overrides/global`: aplica leitura de `gtk-3.0`/`gtk-4.0`/`fontconfig`/`kdeglobals` e `FREETYPE_PROPERTIES` para todos os Flatpaks.
- `files/desktop/usr/share/flatpak/overrides/com.brave.Browser`: libera D-Bus `org.kde.plasma.browser.integration=talk` para o Brave Flatpak (Chrome e Firefox são gerenciados nativamente pelo Plasma 6.8).
- `files/desktop/etc/fonts/conf.d/64-font-rendering.conf`: define aliases de fontes (`Inter Variable`, `JetBrainsMono Nerd Font`, `FiraCode Nerd Font`) preservando preferências de renderização do usuário no KDE.
- `files/desktop/etc/xdg/baloofilerc`: exclui cache do rclone e montagens `/run/user` da indexação do KDE Baloo.
- `files/desktop/etc/xdg/dolphinrc`: desativa restauração de abas e oculta barra de menus no Dolphin preservando thumbnailers nativos do KF6.
- `files/desktop/etc/xdg/breezerc`: remove bordas de janela e gradiente de fundo do Breeze para estética limpa no Plasma 6.
- `files/desktop/etc/xdg/kdeglobals`: aplica Breeze Dark (`ColorScheme=BreezeDark`, ícones `breeze-dark`), destaque azul, animações 0.5x, clique simples e desativa miniaturas remotas (preservando fontes nativas do Plasma 6).
- `files/desktop/etc/xdg/kwinrc`: ajusta o efeito Blur do KWin (`BlurStrength=10`, `NoiseStrength=2`) e ativa `[Windows] Placement=Centered` nativo em Wayland.
- `files/desktop/etc/xdg/kiorc`: exige confirmação ao excluir permanentemente ou esvaziar a lixeira.
- `files/desktop/etc/xdg/konsolerc`: define `Kinoite.profile` como padrão, oculta a barra de menus e exibe a barra de abas apenas quando necessária.
- `files/desktop/usr/share/konsole/Kinoite.profile`: configura fonte JetBrainsMono Nerd Font 10.5, espaçamento de linha, margem de 12px, cursor barra vertical estático e barra de rolagem oculta.
- `files/desktop/usr/share/konsole/Kinoite.colorscheme`: define paleta escura Tokyo Night com vidro fosco (`Opacity=0.92`, `Blur=true`).
- `files/desktop/usr/share/starship/starship.toml`: configura prompt Starship em duas linhas estilo minimalista com `right_format`, status de erro, duração e linguagens sob demanda.
- `files/desktop/usr/share/fastfetch/config.jsonc`: define layout compacto com logo pequeno, ícones Nerd Font e telemetria de hardware (CPU, Dual-GPU, ZRAM, Btrfs).
- `files/desktop/usr/share/user-tmpfiles.d/70-fastfetch.conf`: sincroniza `config.jsonc` do Fastfetch em `~/.config/fastfetch/` no login.
- `files/desktop/etc/profile.d/50-kinoite-env.sh`: inicializa Starship e exibe Fastfetch uma vez por sessão interativa fora de terminais embutidos de IDE.
- `files/desktop/etc/profile.d/60-kinoite-aliases.sh`: define aliases de terminal, proteção interativa (`cp -i`, `mv -i`, `rm -i`) e atalhos de diagnóstico/manutenção (`sysup='sudo bootc upgrade'`, `status-libvirt`).
- `files/desktop/usr/share/topgrade/10-kinoite.toml`: desabilita passos conflitantes (`toolbx`, `tailscale`) no Topgrade.
- `files/desktop/usr/share/user-tmpfiles.d/70-topgrade.conf`: copia o drop-in do Topgrade para `~/.config/topgrade.d/` no login.

## IA, CDI, Periféricos, Virtualização e Nuvem

- A inferência local de IA roda exclusivamente na NVIDIA RTX 3080 Ti via CUDA/CDI (`nvidia-ctk`), sem overrides ROCm/OpenCL na GPU AMD.
- `files/base/usr/lib/tmpfiles.d/60-kinoite-mm.conf`: define `transparent_hugepage/defrag=defer+madvise` no boot para desfragmentação assíncrona via `kcompactd`.
- `files/base/usr/lib/udev/rules.d/70-peripherals.rules`: aplica `uaccess` aos periféricos USB HID homologados e apenas a interfaces ADB/Fastboot Android (`ID_USB_INTERFACES` `ff4201`/`ff4203`), cria `/dev/dri/primary-render` por `DRIVERS=="amdgpu"` e ajusta fila NVMe (`scheduler=none`, `read_ahead_kb=256`, `add_random=0`, `rq_affinity=2`).
- `files/base/usr/share/polkit-1/rules.d/60-kinoite-libvirt.rules`: permite ao grupo `wheel` gerenciar libvirt/KVM localmente sem prompt de senha, com `virtqemud` ativado sob demanda pelos sockets nativos.
- `files/cloud/usr/lib/systemd/user/rclone@.service`: monta remotos Rclone em `/run/user/%U/cloud/%i` com cache VFS completo e limites de I/O (`ConditionUser=!@system`).
- `files/cloud/usr/share/rclone/env/GoogleDrive.env`: configura rate limits (12 TPS), chunks de 64M, lixeira e ocultação de Google Docs.
- `files/cloud/usr/share/rclone/env/OneDrive.env`: configura rate limits (5 TPS), Delta API e chunks de 50M para Microsoft Graph.
- `files/cloud/usr/share/user-tmpfiles.d/70-rclone-env.conf`: cria `~/.config/rclone/env/` e `/run/user/%U/cloud` e copia os perfis padrão no login.

## CI/CD e Assinatura

- `.github/workflows/validate.yml`: valida sintaxe shell, arquivos estruturados (YAML, TOML, XML, JSON/JSONC), receitas BlueBuild (`v0.9.40`) e cobertura 100% de `PROJECTS.md` em cada `push` e `pull_request` na `main`.
- `.github/workflows/build.yml`: compila `amd`, `cuda` ou `all` via BlueBuild (`chunkah: true`) e assina com Cosign.
- `.github/workflows/check-updates.yml`: verifica a cada 2 horas se o digest upstream mudou ou se commits recentes tocaram entradas da receita (`files/base`, `files/desktop`, `files/cloud`, `files/dnf`, `files/nvidia`, `recipes/modules/`) em relação ao GHCR e dispara build apenas se necessário.
- `.github/workflows/cleanup.yml`: remove versões antigas das imagens mantendo 15 e limpa históricos de runs diariamente.
- `.github/dependabot.yml`: verifica semanalmente atualizações das GitHub Actions.
- `cosign.pub`: chave pública embutida para verificação criptográfica das imagens via Bootc.

## Invariantes e Critérios de Software

- É proibido adicionar `nvidia-drm.modeset=1` ou permitir render nodes DRM na GPU secundária NVIDIA.
- É proibido desativar `sulogin` em modos de resgate ou emergência.
- É proibido adicionar kargs obsoletos ou redundantes (`initcall_blacklist=simpledrm_platform_driver_init`, `preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`).
- É proibido codificar endereços PCI estáticos (`pci-0000:..`) em regras `udev`, specs CDI ou scripts quando houver detecção por driver.
- É proibido colocar configurações em `/etc/` quando o subsistema suportar `/usr/lib/` ou `/usr/share/` (exceções válidas: `profile.d`, `security/limits.d`, `ssh/sshd_config.d`, `fonts/conf.d`, `xdg`, `pki/akmods/certs`, `NetworkManager/dispatcher.d`).
- É proibido fazer downgrade de pacotes base ou usar `type: script` nas receitas quando houver solução declarativa.
- É proibido executar `podman container prune` ou `podman volume prune` em timers automáticos ou scripts de manutenção não interativos.
- Aplicativos GUI devem ser instalados exclusivamente via Flatpak em `recipes/modules/desktop-flatpaks.yml` (exceções: `gnome-boxes` e `virt-manager` RPM para integração direta com libvirt/virgl/SPICE).
- Linguagens, SDKs e CLIs de desenvolvimento devem rodar isolados em contêineres Distrobox ou Podman.
- Configurações de usuário devem ser aplicadas via `user-tmpfiles.d` usando templates em `/usr/share/`.
