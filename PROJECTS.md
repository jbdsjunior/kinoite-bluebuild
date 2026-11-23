# Diretrizes Lineares do Projeto (kinoite-bluebuild)

## Arquitetura Geral e Hardware

- O projeto é modular, declarativo e organizado em camadas BlueBuild sobre Fedora Kinoite gerenciado via Bootc.
- A árvore `/usr/lib/` e `/usr/share/` concentra as configurações do sistema para manter `/etc/` limpo.
- O flavor `kinoite-amd` atende sistemas 100% AMD sem nenhum arquivo, driver ou karg NVIDIA.
- O flavor `kinoite-cuda` herda toda a base AMD e adiciona a camada de drivers e isolamento headless NVIDIA para CUDA/compute.
- A estação de referência usa Ryzen 9 5950X (`amd-pstate-epp`), placa Gigabyte X570 AORUS PRO WIFI em UEFI com Secure Boot e fTPM 2.0, 64 GB DDR4 e 32 GB ZRAM zstd.
- A GPU primária é a AMD Radeon RX 6600 XT (`amdgpu`), dedicada a display Wayland, KDE Plasma, Vulkan/VA-API e VMs.
- A GPU secundária é a NVIDIA RTX 3080 Ti (`nvidia`), isolada em modo headless exclusivamente para CUDA, PyTorch e LLMs locais.
- O armazenamento usa NVMe PCIe Gen4 de 1 TB em Btrfs e discos auxiliares de 1 TB; a rede usa Intel I211 GbE e Intel Wi-Fi 6E AX210.
- Os periféricos USB homologados são receptores VXE/Compx (`3554`), headset MCHOSE X9 (`3837`), teclado BY Tech (`258a`), LED ITE (`048d`) e dispositivos Android ADB/Fastboot (`18d1`, `2a70`, `22d9`, `04e8`, `22b8`, `2717`, `05c6`, `0e8d`).

## Estrutura do Repositório e Documentação

- `recipes/` reúne os manifestos principais (`recipe-*.yml`) e `recipes/modules/` reúne os módulos compartilhados (`common-*.yml`).
- `files/base/` contém as configurações fundamentais do sistema (kernel, ZRAM, rede, segurança, udev, manutenção e utilitários).
- `files/desktop/` contém as configurações de ambiente desktop KDE Plasma, fontes, Konsole e timers Flatpak.
- `files/shell/` contém as configurações de shell, prompt Starship, Fastfetch e wrapper Topgrade.
- `files/rclone/` contém as definições de montagem automática em nuvem via Rclone.
- `files/virt/` contém as configurações de autorização e Btrfs NoCOW de usuário da pilha de virtualização KVM/Libvirt.
- `files/rocm/` contém as configurações da pilha de computação AMD ROCm/HIP (CDI, variáveis e regra `udev` `/dev/kfd`).
- `files/tailscale/` contém a configuração da zona confiável do firewall para a rede mesh Tailscale.
- `files/nvidia/` contém exclusivamente os arquivos de suporte e isolamento da GPU NVIDIA.
- `files/dnf/` contém as definições de repositórios externos RPM.
- `AGENTS.md` define processo, Git, validações pré-commit e categorias de consulta para agentes de IA.
- `PROJECTS.md` mantém o catálogo linear completo de arquitetura, hardware, arquivos e invariantes do projeto.
- `README.md` apresenta visão geral, comandos de troca de imagem e estrutura do repositório em inglês.
- `SECURITY.md` documenta a política de verificação Cosign e permissões mínimas do CI/CD em inglês.
- `docs/POST_INSTALL.md` documenta o guia pós-instalação de TPM 2.0, Rclone, manutenção e recuperação em português do Brasil.
- `LICENSE` declara a licença Apache 2.0 do projeto.
- `.gitignore` exclui artefatos locais e temporários mantendo regras, documentação e chaves públicas rastreados.
- `.gitattributes` padroniza finais de linha LF para arquivos de texto e preserva binários `.der`.

## Receitas BlueBuild

- `recipes/recipe-amd.yml`: compila a imagem limpa `kinoite-amd` para sistemas exclusivos AMD.
- `recipes/recipe-cuda.yml`: compila a imagem `kinoite-cuda` para estações AMD + NVIDIA headless (CUDA/compute).
- `recipes/modules/common-files.yml`: aplica os overlays de domínio compartilhados (`base`, `desktop`, `shell`, `rclone`, `virt`, `rocm`, `tailscale`).
- `recipes/modules/common-fonts.yml`: instala Nerd Fonts (`FiraCode`, `JetBrainsMono`, `NerdFontsSymbolsOnly`) e tipografia do sistema RPM (`rsms-inter-vf-fonts`).
- `recipes/modules/common-debloat.yml`: remove bloatware RPM da imagem base (`firefox`, `plasma-discover-rpm-ostree`, `plasma-discover-notifier`) via módulo `dnf` com `auto-remove: true`.
- `recipes/modules/common-core.yml`: instala localização essencial (`langpacks-pt_BR`).
- `recipes/modules/common-multimedia.yml`: habilita `rpmfusion` (com `cleanup: true`) e instala a pilha multimídia completa e codecs proprietários (`ffmpeg`, `libheif-freeworld`, GStreamer plugins extras, freeworld e ugly).
- `recipes/modules/common-drivers.yml`: habilita `rpmfusion` (com `cleanup: true`) e instala aceleração gráfica/computacional AMD (`mesa-va-drivers-freeworld`, `mesa-libOpenCL`).
- `recipes/modules/common-virt.yml`: instala a pilha KVM/libvirt (`@virtualization`, `libvirt-nss`, `gnome-boxes`, excluindo `virt-viewer`).
- `recipes/modules/common-tools.yml`: habilita `tailscale.repo` e `terra.repo` (com `cleanup: true`) e instala ferramentas CLI, monitoramento, containers, sync, credenciais e rede (`lm_sensors`, `topgrade`, `starship`, `fastfetch`, `tailscale`, `rclone`, `distrobox`, `git-credential-libsecret`).
- `recipes/modules/cuda-nvidia.yml`: compila `nvidia-open` via akmods (`MULTILIB=0`), aplica os arquivos de `files/nvidia/`, habilita `nvidia-persistenced.service` e mascara `nvidia-powerd.service`.
- `recipes/modules/common-flatpaks.yml`: declara os 21 aplicativos Flatpak de sistema ativos via módulo `default-flatpaks` v2 (incluindo `Warehouse`, `Kontainer`, `sshpilot`, `KTailctl`, `Gtk3theme.Breeze`, `kcalc`, `kclock`, `okular`, `Stremio` e `MissionCenter`).
- `recipes/modules/common-systemd.yml`: habilita `bootc-fetch-apply-updates.timer`, `bootc-update-ca-trust.service`, `bootc-update-crypto-policies.service`, `flatpak-nuke-fedora.service`, `flatpak-system-update.timer` e `tailscaled.service` no sistema, mascara `flatpak-add-fedora-repos.service`, e habilita `flatpak-user-update.timer`, `podman.socket`, `podman-auto-update.timer` e `podman-restart.service` no usuário (deixando `systemd-resolved`, `firewalld`, `fstrim.timer`, `smartd.service`, `systemd-oomd.service` e sockets modulares do `libvirt` aos presets upstream e mantendo `ModemManager.service` desmascarado para evitar erros D-Bus).

## Kernel Arguments e Isolamento NVIDIA

- `initcall_blacklist=simpledrm_platform_driver_init` é aplicado exclusivamente na variante `kinoite-cuda` via `00-bluebuild-nvidia-kargs.toml` para evitar conflito de framebuffer em dual-GPU (deixando `kinoite-amd` usar `simpledrm` nativo com `kmscon` no Fedora 45).
- `rd.driver.blacklist=nouveau` e `modprobe.blacklist=nouveau` bloqueiam `nouveau` no initramfs e userspace da imagem `kinoite-cuda`.
- `rd.driver.blacklist=nvidia-drm` e `modprobe.blacklist=nvidia-drm` impedem nó gráfico DRM na NVIDIA preservando nós CUDA (`/dev/nvidia*`).
- `files/nvidia/usr/lib/bootc/kargs.d/00-bluebuild-nvidia-kargs.toml`: sobrescreve os kargs do akmods eliminando `nvidia-drm.modeset=1`, aplicando `initcall_blacklist=simpledrm_platform_driver_init` e blacklist de `nouveau` e `nvidia-drm`.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia.conf`: mantém apenas `amdgpu` em `force_drivers` e omite `nvidia_drm`/`nvidia-drm` do initramfs para carregar módulos NVIDIA sob demanda no userspace.
- `files/nvidia/usr/lib/modprobe.d/60-nvidia-headless.conf`: bloqueia `nvidia-drm`/`nvidia_drm` redirecionando para `/usr/bin/true`, ativa Resizable BAR na RTX 3080 Ti e desativa RTD3 dinâmico em desktop (`NVreg_DynamicPowerManagement=0x00`).
- `files/nvidia/usr/lib/udev/rules.d/65-nvidia-headless-pm.rules`: mantém GPU NVIDIA (`0x10de`) e seu áudio HDMI fora de runtime suspend e D3cold (`power/control=on`, `d3cold_allowed=0`), sobrescrevendo `60-nvidia.rules`.
- `files/nvidia/usr/lib/environment.d/65-nvidia-headless.conf`: força `__EGL_VENDOR_LIBRARY_FILENAMES` e `__GLX_VENDOR_LIBRARY_NAME=mesa` (complementando `VK_DRIVER_FILES` de `60-desktop.conf`) para impedir que aplicações host capturem EGL/GLX da NVIDIA.
- `files/nvidia/usr/lib/tmpfiles.d/60-nvidia-headless.conf`: prioriza Mesa EGL via symlink `/etc/glvnd/egl_vendor.d/00_mesa.json` para daemons com ambiente limpo (`virtqemud`/`qemu`) preservando `10_nvidia.json` para CDI.
- `files/nvidia/etc/pki/akmods/certs/akmods-ublue.der`: fornece o certificado público MOK para validação dos módulos akmods no Secure Boot.

## Armazenamento, ZRAM, Memória e Segurança

- `files/base/usr/lib/bootc/kargs.d/10-pcie-pm.toml`: aplica `pcie_port_pm=off` nas imagens base evitando suspensão runtime D3 em portas e switches PCIe de desktop.
- `files/base/usr/lib/modprobe.d/60-snd-hda-intel.conf`: desativa `power_save` e `power_save_controller` em `snd_hda_intel` prevenindo travamentos D3/PME no controlador de áudio AMD X570 (`1022:1487`).
- `files/base/usr/lib/tmpfiles.d/60-btrfs-reclaim.conf`: ativa reclaim dinâmico e periódico de chunks Btrfs (`dynamic_reclaim=1`, `periodic_reclaim=1`) evitando `ENOSPC` falso.
- `files/base/usr/lib/systemd/zram-generator.conf.d/60-zram.conf`: configura swap ZRAM zstd em 50% da RAM até 32 GB.
- `files/base/usr/lib/sysctl.d/90-memory.conf`: ajusta ZRAM (`swappiness=150`, `page-cluster=0`) e `fs.inotify.max_user_instances=8192`.
- `files/base/usr/lib/sysctl.d/90-kernel.conf`: ativa `sysrq=1` (REISUB) e `kernel.printk` (mantendo `kptr_restrict=1` ao padrão nativo do Fedora 45).
- `files/base/usr/lib/tmpfiles.d/60-sysctl-runtime.conf`: registra symlinks efêmeros dos sysctls em `/run/sysctl.d/` para prevalecer sobre o TuneD (`reapply_sysctl=1`) sem poluir `/etc/sysctl.d/`.
- `files/base/usr/lib/modprobe.d/60-iwlwifi.conf`: desativa economia de energia e ativa modo ativo no Wi-Fi 6E Intel AX210 (`iwlwifi`/`iwlmvm`).
- `files/base/usr/lib/modules-load.d/60-tcp-bbr.conf`: carrega `sch_fq` e `tcp_bbr` no boot.
- `files/base/usr/lib/sysctl.d/90-network.conf`: ativa TCP BBR/FQ, TCP MTU probing (`tcp_mtu_probing=1`) e bloqueio de redirects ICMP.
- `files/base/usr/lib/systemd/resolved.conf.d/60-dns.conf`: aplica DNS-over-TLS oportunista (`DNSOverTLS=opportunistic`) com Control D (`p2`), fallback Cloudflare, compatibilidade com MagicDNS da Tailscale e `MulticastDNS=no` (delegando mDNS ao `avahi-daemon`).
- `files/tailscale/usr/lib/firewalld/zones/tailscale.xml`: declara zona confiável do firewall para a interface `tailscale0`.
- `files/dnf/tailscale.repo`: configura o repositório oficial da Tailscale.
- `files/dnf/terra.repo`: configura o repositório Terra da Fyra Labs com `baseurl` direto e `repo_gpgcheck=1`.
- `files/base/usr/lib/bootc/install/20-kinoite.toml`: define `root-fs-type = "btrfs"` e `enforce-container-sigpolicy = true` para instalações Bootc.

## Serviços, Timers e Manutenção

- Os timers de atualização rodam em prioridade ociosa (`Nice=19`, `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`) com jitter de `10m`–`15m` e `ExecCondition=/usr/bin/nm-online -q -t 15`; units de usuário incluem `ConditionUser=!@system` para ignorar o greeter `plasmalogin`.
- `files/base/usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/override.conf`: executa `bootc upgrade --quiet` (`Type=oneshot`, `nm-online`) em prioridade ociosa.
- `files/base/usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/override.conf`: agenda busca de updates do SO após 15m do boot e a cada 6h (`Persistent=true`).
- `files/base/usr/lib/systemd/system/bootc-update-ca-trust.service`: regenera `/etc/pki/ca-trust` no boot após *three-way merge* de atualizações Bootc.
- `files/base/usr/lib/systemd/system/bootc-update-crypto-policies.service`: regenera os backends de `crypto-policies` no boot após atualizações Bootc.
- `files/base/usr/lib/systemd/system/flatpak-nuke-fedora.service`: remove remotes Flatpak residuais `fedora`/`fedora-testing` na primeira inicialização (`ConditionPathExists=!/var/lib/flatpak/.fedora-initialized`) mantendo apenas Flathub.
- `files/base/usr/lib/systemd/system/fstrim.service.d/workaround-no-root-trim.conf`: direciona `fstrim.service` para `--listed-in /proc/self/mountinfo` garantindo TRIM em subvolumes Btrfs no Bootc.
- `files/desktop/usr/lib/systemd/system/flatpak-system-update.service`: atualiza Flatpaks de sistema e remove runtimes órfãos apenas com rede online.
- `files/desktop/usr/lib/systemd/system/flatpak-system-update.timer`: dispara atualização de Flatpaks de sistema após 10m do boot e a cada 6h (`Persistent=true`).
- `files/desktop/usr/lib/systemd/user/flatpak-user-update.service`: atualiza Flatpaks de usuário e limpa runtimes sem uso apenas com rede online (`ConditionUser=!@system`).
- `files/desktop/usr/lib/systemd/user/flatpak-user-update.timer`: dispara atualização de Flatpaks de usuário após 12m do login e a cada 6h (`ConditionUser=!@system`, `Persistent=true`).
- `files/base/usr/bin/kinoite-optimize`: executa manutenção local em 6 fases e auditoria somente leitura `--audit` dos 6 pilares com detecção dinâmica de nós DRM por driver (`amdgpu`/`nvidia`).
- `files/base/usr/bin/kinoite-setup-tpm`: vincula partição LUKS2 ao fTPM 2.0 (PCRs 7+14) com suporte a PIN, chave de recuperação e atualização segura de `/etc/crypttab`.

## Desktop KDE, Navegadores e Terminal

- `files/desktop/etc/fonts/conf.d/64-font-aliases.conf`: define aliases de fontes (`Inter Variable`, `JetBrainsMono Nerd Font`, `FiraCode Nerd Font`) preservando preferências de renderização do usuário no KDE.
- `files/desktop/etc/xdg/kwinrc`: ativa centralização nativa (`[Windows] Placement=Centered`) e o script KWin `kinoite-window-center` (`[Plugins]`) para novas janelas no Wayland.
- `files/desktop/usr/share/kwin/scripts/kinoite-window-center/metadata.json`: registra o manifesto KWin/Script `kinoite-window-center` para o Plasma 6.
- `files/desktop/usr/share/kwin/scripts/kinoite-window-center/contents/code/main.js`: centraliza janelas normais novas na área útil do monitor (`KWin.PlacementArea`) contornando falhas de posicionamento em Wayland.
- `files/desktop/etc/xdg/konsolerc`: define `Kinoite.profile` como padrão, oculta a barra de menus e exibe a barra de abas apenas quando necessária.
- `files/desktop/usr/share/konsole/Kinoite.profile`: configura fonte JetBrainsMono Nerd Font 10.5, espaçamento de linha, margem de 12px, cursor barra vertical estático e barra de rolagem oculta.
- `files/desktop/usr/share/konsole/Kinoite.colorscheme`: define paleta escura Tokyo Night com vidro fosco (`Opacity=0.92`, `Blur=true`).
- `files/desktop/usr/share/kinoite/browsers/chrome-flags.conf`: define flags padrão do Google Chrome Flatpak para Wayland nativo, rasterização GPU, zero-copy e `AcceleratedVideoEncoder`.
- `files/desktop/usr/share/kinoite/browsers/brave-flags.conf`: define flags padrão do Brave Flatpak para Wayland nativo, rasterização GPU, zero-copy e `AcceleratedVideoEncoder`.
- `files/desktop/usr/share/user-tmpfiles.d/60-browser-flags.conf`: provisiona e sobrescreve sempre (`C+`) `chrome-flags.conf` e `brave-flags.conf` em `$HOME/.var/app/`.
- `files/shell/usr/share/starship/starship.toml`: configura prompt Starship em duas linhas estilo minimalista com `right_format`, status de erro, duração e linguagens sob demanda.
- `files/shell/usr/share/fastfetch/config.jsonc`: define layout compacto com logo pequeno, ícones Nerd Font e telemetria de hardware (CPU, Dual-GPU, ZRAM, Btrfs), carregado diretamente por `50-shell-prompt.sh` quando o usuário não tiver configuração própria.
- `files/shell/etc/profile.d/50-shell-prompt.sh`: inicializa Starship (`/usr/share/starship/starship.toml`) e exibe Fastfetch (`/usr/share/fastfetch/config.jsonc`) uma vez por sessão interativa fora de terminais embutidos de IDE, sem copiar arquivos para `$HOME`.
- `files/shell/etc/profile.d/60-shell-aliases.sh`: define aliases de terminal, proteção interativa (`cp -i`, `mv -i`, `rm -i`), wrapper `_kinoite_topgrade` e atalhos de diagnóstico/manutenção.
- `files/shell/usr/share/topgrade/topgrade.toml`: desabilita passos conflitantes (`toolbx`, `tailscale`) no Topgrade, passado via `--config` por `60-shell-aliases.sh` quando `~/.config/topgrade.toml` não existir, sem copiar arquivos para `$HOME`.

## IA, CDI, Periféricos, Virtualização e Nuvem

- `files/rocm/etc/cdi/amdgpu.yaml`: expõe `/dev/kfd`, `/dev/dri/renderD128` e `/dev/dri/card0` com `HSA_OVERRIDE_GFX_VERSION=10.3.0` via CDI `amd.com/gpu`.
- `files/rocm/usr/lib/environment.d/60-rocm.conf`: exporta `HSA_OVERRIDE_GFX_VERSION=10.3.0` para compatibilidade AMD ROCm/HIP na RX 6600 XT (`gfx1032` → `gfx1030`) e ativa `RUSTICL_ENABLE=radeonsi` para OpenCL no host.
- `files/desktop/usr/lib/environment.d/60-desktop.conf`: exporta `LIBVA_DRIVER_NAME=radeonsi` e `VK_DRIVER_FILES` (RADV).
- `files/base/usr/lib/udev/rules.d/70-hardware.rules`: aplica `uaccess` aos periféricos USB e interfaces Android ADB/Fastboot (`ff4201`/`ff4203`, incluindo OPPO `22d9`), cria `/dev/dri/primary-render` por `DRIVERS=="amdgpu"` e desativa `d3cold_allowed` em controladores `snd_hda_intel`.
- `files/virt/usr/share/user-tmpfiles.d/60-virt-btrfs-nocow.conf`: aplica Btrfs NoCOW (`+C`) em imagens de VMs de usuário (`libvirt` e `gnome-boxes`).
- `files/virt/usr/share/polkit-1/rules.d/60-libvirt.rules`: permite ao grupo `wheel` gerenciar libvirt/KVM localmente sem prompt de senha.
- `files/rclone/usr/lib/systemd/user/rclone@.service`: monta remotos Rclone em `/run/user/%U/cloud/%i` com cache VFS completo, limites de I/O e `EnvironmentFile` herdado diretamente de `/usr/share/rclone/env/%i.env` com override opcional em `~/.config/rclone/env/%i.local.env` (`ConditionUser=!@system`).
- `files/rclone/usr/share/rclone/env/GoogleDrive.env`: configura rate limits (12 TPS), chunks de 64M, lixeira e ocultação de Google Docs.
- `files/rclone/usr/share/rclone/env/OneDrive.env`: configura rate limits (5 TPS), Delta API e chunks de 50M para Microsoft Graph.
- `files/rclone/usr/share/user-tmpfiles.d/60-rclone-btrfs-nocow.conf`: aplica Btrfs NoCOW (`+C`) no cache VFS do Rclone (`~/.cache/rclone`).

## CI/CD e Assinatura

- `.github/workflows/build.yml`: compila `amd`, `cuda` ou `all` via BlueBuild (`chunkah: true`) e assina com Cosign.
- `.github/workflows/check-updates.yml`: verifica a cada 1 hora se o nome ou digest da imagem base upstream mudou em relação ao GHCR (sem verificar o repositório local) e dispara build apenas se necessário.
- `.github/workflows/cleanup.yml`: remove versões antigas das imagens mantendo 15 e limpa históricos de runs diariamente.
- `.github/dependabot.yml`: verifica semanalmente atualizações das GitHub Actions.
- `cosign.pub`: chave pública embutida para verificação criptográfica das imagens via Bootc.

## Invariantes e Critérios de Software

- É proibido adicionar `nvidia-drm.modeset=1` ou permitir render nodes DRM na GPU secundária NVIDIA.
- É proibido desativar `sulogin` em modos de resgate ou emergência.
- É proibido adicionar kargs obsoletos ou redundantes (`preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`).
- É proibido codificar endereços PCI estáticos (`pci-0000:..`) em regras `udev`, specs CDI ou scripts quando houver detecção por driver.
- É proibido colocar configurações em `/etc/` quando o subsistema suportar `/usr/lib/` ou `/usr/share/` (exceções válidas: `profile.d`, `fonts/conf.d`, `xdg`, `cdi`, `pki/akmods/certs`).
- É proibido fazer downgrade de pacotes base ou usar `type: script` nas receitas quando houver solução declarativa.
- Aplicativos GUI devem ser instalados exclusivamente via Flatpak em `recipes/modules/common-flatpaks.yml` (exceção: `gnome-boxes` RPM para integração direta com libvirt/virgl/SPICE).
- Linguagens, SDKs e CLIs de desenvolvimento devem rodar isolados em contêineres Distrobox ou Podman.
- Configurações padrão devem ser herdadas de `/usr/share/` e `/etc/xdg/` sempre que possível; quando um sandbox (como Flatpak) exigir arquivo em `$HOME`, o projeto provisiona e sobrescreve sempre as configurações locais de forma determinística via `user-tmpfiles.d` (`C+`).
