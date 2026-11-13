# Diretrizes Lineares do Projeto (kinoite-bluebuild)

## Arquitetura Geral e Hardware

- O projeto é modular, declarativo e organizado em camadas BlueBuild sobre Fedora Kinoite gerenciado via Bootc.
- A árvore `/usr/lib/` e `/usr/share/` concentra as configurações do sistema para manter `/etc/` limpo.
- O flavor `kinoite-amd` atende sistemas 100% AMD sem nenhum arquivo, driver ou karg NVIDIA.
- O flavor `kinoite-dual` herda toda a base AMD e adiciona a camada de drivers e isolamento headless NVIDIA.
- A estação de referência usa Ryzen 9 5950X (`amd-pstate-epp`), placa Gigabyte X570 AORUS PRO WIFI em UEFI com Secure Boot e fTPM 2.0, 64 GB DDR4 e 32 GB ZRAM zstd.
- A GPU primária é a AMD Radeon RX 6600 XT (`amdgpu`), dedicada a display Wayland, KDE Plasma, Vulkan/VA-API e VMs.
- A GPU secundária é a NVIDIA RTX 3080 Ti (`nvidia`), isolada em modo headless exclusivamente para CUDA, PyTorch e LLMs locais.
- O armazenamento usa NVMe PCIe Gen4 de 1 TB em Btrfs e discos auxiliares de 1 TB; a rede usa Intel I211 GbE e Intel Wi-Fi 6E AX210.
- Os periféricos USB homologados são receptores VXE/Compx (`3554`), headset MCHOSE X9 (`3837`), teclado BY Tech (`258a`), LED ITE (`048d`) e dispositivos Android ADB/Fastboot (`18d1`, `2a70`, `04e8`, `22b8`, `2717`, `05c6`, `0e8d`).

## Estrutura do Repositório e Documentação

- `recipes/` reúne os manifestos principais (`recipe-*.yml`) e `recipes/modules/` reúne os módulos compartilhados (`common-*.yml`).
- `files/system/` contém as configurações comuns a todas as imagens.
- `files/nvidia/` contém exclusivamente os arquivos de suporte e isolamento da GPU NVIDIA.
- `files/dnf/` contém as definições de repositórios externos RPM.
- `AGENTS.md` define processo, Git, validações pré-commit e categorias de consulta para agentes de IA.
- `PROJECTS.md` mantém o catálogo linear completo de arquitetura, hardware, arquivos e invariantes do projeto.
- `README.md` apresenta visão geral, comandos de troca de imagem e estrutura do repositório em inglês.
- `SECURITY.md` documenta a política de verificação Cosign e permissões mínimas do CI/CD em inglês.
- `docs/POST_INSTALL.md` documenta o guia pós-instalação de TPM 2.0, Rclone, manutenção e recuperação em português do Brasil.
- `LICENSE` declara a licença Apache 2.0 do projeto.
- `.gitignore` exclui artefatos locais e temporários mantendo regras, documentação e chaves públicas rastreados.

## Receitas BlueBuild

- `recipes/recipe-amd.yml`: compila a imagem limpa `kinoite-amd` para sistemas exclusivos AMD.
- `recipes/recipe-dual.yml`: compila a imagem `kinoite-dual` para estações Dual-GPU AMD + NVIDIA.
- `recipes/modules/common-packages.yml`: consolida em camada única DNF + fontes a remoção de bloat (`firefox`, `kwrite`, `plasma-discover-rpm-ostree`, `plasma-discover-notifier`), troca `ocl-icd`, localização `langpacks-pt_BR`, KDE (`plasma-firewall`, `kio-admin`, `ksshaskpass`, `qt6-qtimageformats`), codecs RPM Fusion (`mesa-va-drivers-freeworld`, `ffmpeg`, `libva-utils`, `libheif-freeworld`, GStreamer), pilha KVM/libvirt (`@virtualization`, `gnome-boxes`, excluindo `virt-viewer`), ferramentas CLI/diagnóstico (`topgrade`, `starship`, `fastfetch`, `tailscale`, `git`, `rclone`, `distrobox`, `mesa-libOpenCL`, `clinfo`, `vulkan-tools`, `nvtop`), `rsms-inter-vf-fonts` e Nerd Fonts (`FiraCode`, `JetBrainsMono`, `NerdFontsSymbolsOnly`).
- `recipes/modules/common-drivers-nvidia.yml`: compila `nvidia-open` via akmods (`MULTILIB=0`), aplica os arquivos de `files/nvidia/`, habilita `nvidia-persistenced.service` e mascara `nvidia-powerd.service`.
- `recipes/modules/common-flatpaks.yml`: declara os 24 aplicativos Flatpak de sistema via módulo `default-flatpaks` v2 (incluindo `org.kde.okular`).
- `recipes/modules/common-kargs.yml`: define a baseline compartilhada de kargs com `initcall_blacklist=simpledrm_platform_driver_init`.
- `recipes/modules/common-systemd.yml`: habilita timers/serviços de sistema e usuário e mascara `systemd-remount-fs.service` e `intel_lpmd.service`.

## Kernel Arguments e Isolamento NVIDIA

- `initcall_blacklist=simpledrm_platform_driver_init` evita conflito de framebuffer com Mesa/DRM no boot.
- `rd.driver.blacklist=nouveau` e `modprobe.blacklist=nouveau` bloqueiam `nouveau` no initramfs e userspace da imagem dual.
- `rd.driver.blacklist=nvidia-drm` e `modprobe.blacklist=nvidia-drm` impedem nó gráfico DRM na NVIDIA preservando nós CUDA (`/dev/nvidia*`).
- `files/nvidia/usr/lib/bootc/kargs.d/00-bluebuild-nvidia-kargs.toml`: sobrescreve os kargs do akmods eliminando `nvidia-drm.modeset=1` e aplicando blacklist de `nouveau` e `nvidia-drm`.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia.conf`: mantém apenas `amdgpu` em `force_drivers` para carregar módulos NVIDIA sob demanda no userspace.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia-headless.conf`: omite `nvidia_drm` e `nvidia-drm` do initramfs.
- `files/nvidia/usr/lib/modprobe.d/60-nvidia-headless.conf`: bloqueia `nvidia-drm`/`nvidia_drm` e redireciona carregamentos para `/usr/bin/true`.
- `files/nvidia/usr/lib/environment.d/60-nvidia-headless.conf`: força `__EGL_VENDOR_LIBRARY_FILENAMES` e `__GLX_VENDOR_LIBRARY_NAME=mesa` para impedir que aplicações host capturem EGL/GLX da NVIDIA.
- `files/nvidia/usr/lib/tmpfiles.d/60-nvidia-headless.conf`: prioriza Mesa EGL via symlink `/etc/glvnd/egl_vendor.d/00_mesa.json` para daemons com ambiente limpo (`virtqemud`/`qemu`) preservando `10_nvidia.json` para CDI.
- `files/nvidia/etc/pki/akmods/certs/akmods-ublue.der`: fornece o certificado público MOK para validação dos módulos akmods no Secure Boot.

## Armazenamento, ZRAM, Memória e Segurança

- `files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`: aplica Btrfs NoCOW (`+C`) em `/var/lib/libvirt/images` e `/var/lib/containers/storage`.
- `files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`: aplica Btrfs NoCOW (`+C`) em imagens de VMs, contêineres rootless e cache do rclone.
- `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`: configura swap ZRAM zstd em 50% da RAM até 32 GB.
- `files/system/usr/lib/sysctl.d/90-memory-fs-tuning.conf`: ajusta ZRAM (`swappiness=150`, `page-cluster=0`), watchers inotify e `dirty_ratio` para NVMe.
- `files/system/etc/security/limits.d/60-kinoite-limits.conf`: libera `memlock unlimited` em sessões PAM/SSH.
- `files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`: define `DefaultLimitMEMLOCK=infinity` no systemd de sistema.
- `files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf`: define `DefaultLimitMEMLOCK=infinity` no systemd de usuário.
- `files/system/usr/lib/sysctl.d/90-kernel-tuning.conf`: ativa `sysrq=1` (REISUB), `kptr_restrict=1` e `panic=20`.
- `files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf`: protege os sysctls do projeto via symlinks em `/etc/sysctl.d/` contra sobrescrita do TuneD.
- `files/system/usr/lib/modprobe.d/60-hardware-tuning.conf`: desativa economia de energia no Wi-Fi 6E Intel AX210 (`iwlwifi`/`iwlmvm`) e ativa PAT + Resizable BAR na RTX 3080 Ti.
- `files/system/usr/lib/modprobe.d/60-security-blacklist.conf`: bloqueia protocolos/filesystems obsoletos (`sctp`, `tipc`, `jffs2`, `hfs`, `hfsplus`, `firewire-core`).
- `files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`: endurece SSH exigindo autenticação por chave, sem root e sem X11.
- `files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf`: reduz `SyncIntervalSec` do journald para 30s.
- `files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`: define `ShowStatus=error` para boot silencioso exibindo apenas falhas.
- `files/system/usr/lib/modules-load.d/60-bbr.conf`: carrega `sch_fq` e `tcp_bbr` no boot.
- `files/system/usr/lib/sysctl.d/90-network-tuning.conf`: ativa TCP BBR/FQ, buffers até 32 MB, TCP Fast Open e bloqueio de redirects ICMP.
- `files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`: aplica DNS-over-TLS estrito com Control D (`p2`) e fallback Cloudflare.
- `files/system/usr/lib/firewalld/zones/tailscale.xml`: declara zona confiável do firewall para a interface `tailscale0`.
- `files/dnf/tailscale.repo`: configura o repositório oficial da Tailscale.
- `files/dnf/terra.repo`: configura o repositório Terra da Fyra Labs.

## Serviços, Timers e Manutenção

- Os timers de atualização rodam em prioridade ociosa (`Nice=19`, `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`) apenas na tomada com jitter de `2m`; units de usuário incluem `ConditionUser=!@system` para ignorar o greeter `plasmalogin`.
- `files/system/usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/override.conf`: executa `bootc update --quiet` em prioridade ociosa na tomada.
- `files/system/usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/override.conf`: agenda busca de updates do SO após 5m do boot e a cada 45m.
- `files/system/usr/lib/systemd/system/flatpak-system-update.service`: atualiza Flatpaks de sistema e remove runtimes órfãos.
- `files/system/usr/lib/systemd/system/flatpak-system-update.timer`: dispara atualização de Flatpaks de sistema após 5m do boot e a cada 45m.
- `files/system/usr/lib/systemd/user/flatpak-user-update.service`: atualiza Flatpaks de usuário e limpa runtimes sem uso (`ConditionUser=!@system`).
- `files/system/usr/lib/systemd/user/flatpak-user-update.timer`: dispara atualização de Flatpaks de usuário após 5m do login e a cada 45m (`ConditionUser=!@system`).
- `files/system/usr/lib/systemd/system/podman-auto-update.service.d/override.conf`: restringe auto-update Podman de sistema à tomada em prioridade ociosa.
- `files/system/usr/lib/systemd/system/podman-auto-update.timer.d/override.conf`: verifica updates Podman de sistema após 5m do boot e a cada 45m.
- `files/system/usr/lib/systemd/user/podman-auto-update.service.d/override.conf`: executa auto-update Podman de usuário em prioridade ociosa na tomada (`ConditionUser=!@system`).
- `files/system/usr/lib/systemd/user/podman-auto-update.timer.d/override.conf`: verifica updates Podman de usuário após 5m do login e a cada 45m (`ConditionUser=!@system`).
- `files/system/usr/lib/systemd/user/podman-restart.service.d/override.conf`: impede execução de `podman-restart.service` para contas `@system` como `plasmalogin`.
- `files/system/usr/lib/systemd/system/kinoite-btrfs-scrub.service`: executa `btrfs scrub start -B /var/home` em prioridade idle somente em alimentação AC.
- `files/system/usr/lib/systemd/system/kinoite-btrfs-scrub.timer`: agenda o scrub mensal de `/var/home`.
- `files/system/usr/lib/systemd/system/kinoite-maintenance.service`: limpa contêineres/volumes/imagens Podman de sistema e limita journald a 200 MB / 14 dias.
- `files/system/usr/lib/systemd/system/kinoite-maintenance.timer`: agenda limpeza semanal de sistema.
- `files/system/usr/lib/systemd/user/kinoite-user-maintenance.service`: limpa Podman de usuário, limita journald a 100 MB / 14 dias e remove thumbnails > 30 dias (`ConditionUser=!@system`).
- `files/system/usr/lib/systemd/user/kinoite-user-maintenance.timer`: agenda limpeza semanal de usuário (`ConditionUser=!@system`).
- `files/system/usr/lib/systemd/system/kinoite-boot-init.service`: oculta o menu GRUB (preservando acesso via tecla Shift) e aplica o perfil `throughput-performance` do `tuned` no primeiro boot.
- `files/system/usr/lib/systemd/system/user-.slice.d/60-kinoite-oomd.conf`: habilita `ManagedOOMMemoryPressure=kill` (70%) e `ManagedOOMSwap=kill` nas sessões de usuário.
- `files/system/usr/bin/kinoite-optimize`: executa manutenção local em 8 fases e auditoria somente leitura `--audit` dos 6 pilares com detecção dinâmica de nós DRM por driver (`amdgpu`/`nvidia`).
- `files/system/usr/bin/kinoite-setup-tpm`: vincula partição LUKS2 ao fTPM 2.0 (PCRs 7+14) com suporte a PIN, chave de recuperação e atualização segura de `/etc/crypttab`.

## Desktop KDE, Navegadores e Terminal

- `files/system/usr/share/chromium/chromium-flags.conf`: ativa Wayland nativo, GPU AMD, VA-API e desativa telemetria em Chromium.
- `files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf`: provisiona `chromium-flags.conf` para Brave e Chrome no login.
- `files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`: aplica overrides Flatpak declarativos (`global`, Jan, Brave, Chrome, Firefox e VS Code).
- `files/system/usr/share/flatpak/overrides/ai.jan.Jan`: expõe dispositivos GPU/KFD (`devices=all`) e `HSA_OVERRIDE_GFX_VERSION=10.3.0` para LLMs locais no Jan.
- `files/system/usr/share/flatpak/overrides/com.visualstudio.code`: libera Wayland nativo e socket Podman (`ro`) no VS Code Flatpak.
- `files/system/usr/share/flatpak/overrides/global`: aplica leitura de `gtk-3.0`/`gtk-4.0`/`fontconfig`/`kdeglobals`, Wayland nativo em Electron, FreeType e `LIBVA_DRIVER_NAME=radeonsi` para todos os Flatpaks.
- `files/system/usr/share/flatpak/overrides/org.mozilla.firefox`: habilita `MOZ_ENABLE_WAYLAND=1` e integração D-Bus com KDE Plasma no Firefox Flatpak.
- `files/system/usr/share/flatpak/overrides/plasma-browser-integration.override`: libera permissão D-Bus para integração de navegadores com KDE Plasma.
- `files/system/etc/fonts/conf.d/64-font-rendering.conf`: configura hinting leve, RGB subpixel, Inter Variable e fallback JetBrainsMono Nerd Font.
- `files/system/etc/xdg/baloofilerc`: exclui cache do rclone e montagens `/run/user` da indexação do KDE Baloo.
- `files/system/etc/xdg/dolphinrc`: desativa restauração de abas, oculta barra de menus e ativa miniaturas locais no Dolphin.
- `files/system/etc/xdg/breezerc`: remove bordas de janela e gradiente de fundo do Breeze para estética limpa no Plasma 6.
- `files/system/etc/xdg/kdeglobals`: aplica Breeze Dark, tipografia `Inter Variable` e `JetBrainsMono Nerd Font`, destaque azul, animações 0.5x, clique simples e desativa miniaturas remotas.
- `files/system/etc/xdg/kwinrc`: ajusta o efeito Blur do KWin (`BlurStrength=10`, `NoiseStrength=2`) sem sobrescrever preferências de tela do usuário.
- `files/system/etc/xdg/kiorc`: exige confirmação ao excluir permanentemente ou esvaziar a lixeira.
- `files/system/etc/xdg/konsolerc`: define `Kinoite.profile` como padrão, oculta a barra de menus e exibe a barra de abas apenas quando necessária.
- `files/system/etc/xdg/kwinrulesrc`: força posicionamento centralizado no KWin para janelas iniciais do Brave e Google Chrome em Wayland.
- `files/system/usr/share/konsole/Kinoite.profile`: configura fonte JetBrainsMono Nerd Font 10.5, espaçamento de linha, margem de 12px, cursor barra vertical estático e barra de rolagem oculta.
- `files/system/usr/share/konsole/Kinoite.colorscheme`: define paleta escura Tokyo Night com vidro fosco (`Opacity=0.92`, `Blur=true`).
- `files/system/usr/share/starship/starship.toml`: configura prompt Starship em duas linhas estilo minimalista com `right_format`, status de erro, duração e linguagens sob demanda.
- `files/system/usr/share/fastfetch/config.jsonc`: define layout compacto com logo pequeno, ícones Nerd Font e telemetria de hardware (CPU, Dual-GPU, ZRAM, Btrfs).
- `files/system/usr/share/user-tmpfiles.d/70-fastfetch.conf`: sincroniza `config.jsonc` do Fastfetch em `~/.config/fastfetch/` no login.
- `files/system/etc/profile.d/50-kinoite-env.sh`: inicializa Starship e exibe Fastfetch uma vez por sessão interativa fora de terminais embutidos de IDE.
- `files/system/etc/profile.d/60-kinoite-aliases.sh`: define aliases de terminal, proteção interativa (`cp -i`, `mv -i`, `rm -i`) e atalhos de diagnóstico/manutenção.
- `files/system/usr/share/topgrade/10-kinoite.toml`: desabilita passos conflitantes (`toolbx`, `tailscale`) no Topgrade.
- `files/system/usr/share/user-tmpfiles.d/70-topgrade.conf`: copia o drop-in do Topgrade para `~/.config/topgrade.d/` no login.

## IA, CDI, Periféricos, Virtualização e Nuvem

- `files/system/etc/cdi/amdgpu.yaml`: expõe `/dev/kfd`, `/dev/dri/renderD128` (mapeado dinamicamente de `/dev/dri/primary-render`) e `/dev/dri/card0` com `HSA_OVERRIDE_GFX_VERSION=10.3.0` via CDI `amd.com/gpu`.
- `files/system/usr/lib/environment.d/60-kinoite-environment.conf`: exporta `HSA_OVERRIDE_GFX_VERSION=10.3.0`, `LIBVA_DRIVER_NAME=radeonsi`, `VDPAU_DRIVER=radeonsi`, `VK_DRIVER_FILES` (RADV), `FREETYPE_PROPERTIES` e `ELECTRON_OZONE_PLATFORM_HINT=auto`.
- `files/system/usr/lib/tmpfiles.d/60-kinoite-mm.conf`: define `transparent_hugepage/defrag=defer+madvise` no boot para desfragmentação assíncrona via `kcompactd`.
- `files/system/usr/lib/udev/rules.d/70-peripherals.rules`: aplica `uaccess` aos periféricos USB, dispositivos Android ADB/Fastboot e `/dev/kfd`, cria `/dev/dri/primary-render` por `DRIVERS=="amdgpu"` e ajusta fila NVMe (`scheduler=none`, `read_ahead_kb=256`, `add_random=0`, `rq_affinity=2`).
- `files/system/usr/share/polkit-1/rules.d/60-kinoite-libvirt.rules`: permite ao grupo `wheel` gerenciar libvirt/KVM localmente sem prompt de senha.
- `files/system/usr/lib/systemd/user/rclone@.service`: monta remotos Rclone em `/run/user/%U/cloud/%i` com cache VFS completo e limites de I/O (`ConditionUser=!@system`).
- `files/system/usr/share/rclone/env/GoogleDrive.env`: configura rate limits (12 TPS), chunks de 64M, lixeira e ocultação de Google Docs.
- `files/system/usr/share/rclone/env/OneDrive.env`: configura rate limits (5 TPS), Delta API e chunks de 50M para Microsoft Graph.
- `files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf`: cria `~/.config/rclone/env/` e `/run/user/%U/cloud` e copia os perfis padrão no login.

## CI/CD e Assinatura

- `.github/workflows/build.yml`: compila `amd`, `dual` ou `all` via BlueBuild (`chunkah: true`) e assina com Cosign.
- `.github/workflows/check-updates.yml`: verifica a cada 2 horas se o digest upstream mudou ou se commits recentes tocaram entradas da receita em relação ao GHCR e dispara build apenas se necessário.
- `.github/workflows/cleanup.yml`: remove versões antigas das imagens mantendo 15 e limpa históricos de runs diariamente.
- `.github/workflows/validate.yml`: valida scripts Shell (`bash -n`), sintaxe YAML, cobertura de `PROJECTS.md` e receitas BlueBuild em todo `push`/`pull_request`.
- `.github/dependabot.yml`: verifica semanalmente atualizações das GitHub Actions.
- `cosign.pub`: chave pública embutida para verificação criptográfica das imagens via Bootc.

## Invariantes e Critérios de Software

- É proibido adicionar `nvidia-drm.modeset=1` ou permitir render nodes DRM na GPU secundária NVIDIA.
- É proibido desativar `sulogin` em modos de resgate ou emergência.
- É proibido adicionar kargs obsoletos ou redundantes (`preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`).
- É proibido codificar endereços PCI estáticos (`pci-0000:..`) em regras `udev`, specs CDI ou scripts quando houver detecção por driver.
- É proibido colocar configurações em `/etc/` quando o subsistema suportar `/usr/lib/` ou `/usr/share/` (exceções válidas: `profile.d`, `security/limits.d`, `ssh/sshd_config.d`, `fonts/conf.d`, `xdg`, `cdi`, `pki/akmods/certs`).
- É proibido fazer downgrade de pacotes base ou usar `type: script` nas receitas quando houver solução declarativa.
- Aplicativos GUI devem ser instalados exclusivamente via Flatpak em `recipes/modules/common-flatpaks.yml` (exceção: `gnome-boxes` RPM para integração direta com libvirt/virgl/SPICE).
- Linguagens, SDKs e CLIs de desenvolvimento devem rodar isolados em contêineres Distrobox ou Podman.
- Configurações de usuário devem ser aplicadas via `user-tmpfiles.d` usando templates em `/usr/share/`.
