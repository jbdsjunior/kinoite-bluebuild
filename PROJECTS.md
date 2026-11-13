# Diretrizes Lineares do Projeto (kinoite-bluebuild)

Este arquivo reúne todas as frases simples que definem a arquitetura, o hardware e a função de cada arquivo do projeto.
Todas as diretrizes estão listadas de forma linear e organizadas em categorias sem numeração.

## Arquitetura e Organização do Repositório

- O projeto é estritamente modular, declarativo e organizado em camadas BlueBuild.
- O sistema operacional base é o Fedora Kinoite imutável gerenciado via Bootc e OSTree.
- A árvore `/usr/lib/` concentra todas as configurações do sistema para manter o `/etc/` limpo para o usuário.
- O repositório segue a regra de zero duplicação de pacotes, configurações e rotinas de CI/CD.
- O diretório `recipes/` centraliza os manifestos principais `recipe-*.yml` e submódulos compartilhados `common-*.yml`.
- O diretório `files/system/` armazena todos os arquivos de configuração comuns a todas as imagens.
- O diretório `files/nvidia/` armazena exclusivamente os arquivos de suporte e isolamento da GPU NVIDIA.
- O diretório `files/dnf/` armazena as definições de repositórios externos de software.
- `AGENTS.md`: define as invariantes críticas, regras proibidas, validações pré-commit e o índice de leitura cirúrgica para agentes de IA.
- `PROJECTS.md`: armazena o catálogo completo de frases simples lineares sobre o hardware, a arquitetura e cada arquivo do repositório.
- `docs/POST_INSTALL.md`: documenta o guia operacional pós-instalação com foco em TPM 2.0, Rclone, manutenção e recuperação.
- `README.md`: apresenta a visão geral do projeto, instruções rápidas de mudança de imagem e estrutura de diretórios.
- `SECURITY.md`: define a política de verificação de assinatura Cosign e o modelo de permissões mínimas do CI/CD.
- `LICENSE`: declara o licenciamento do projeto sob a licença Apache 2.0.
- `.gitignore`: define os padrões de exclusão de artefatos locais e temporários, preservando arquivos de regras, documentação e chaves públicas rastreados.
- Os guias operacionais e diretrizes (`AGENTS.md`, `PROJECTS.md` e `docs/POST_INSTALL.md`) utilizam português do Brasil e `README.md`, `SECURITY.md`, código, scripts e mensagens de sistema utilizam inglês.

## Hardware da Estação e Papel das GPUs

- O processador de referência é o AMD Ryzen 9 5950X (16 núcleos e 32 threads, arquitetura Zen 3) com gerenciamento `amd-pstate-epp` nativo.
- A placa-mãe é a Gigabyte X570 AORUS PRO WIFI operando em modo UEFI puro com Secure Boot e fTPM 2.0 ativos.
- A memória principal possui 64 GB de RAM DDR4 complementada por 32 GB de swap em ZRAM comprimido com algoritmo zstd.
- A GPU primária é a AMD Radeon RX 6600 XT de 8 GB GDDR6 (Navi 23 / RDNA2) localizada no barramento PCI `0000:0c:00.0`.
- A GPU AMD é dedicada exclusivamente ao display, sessão gráfica Wayland, desktop KDE Plasma, aceleração Vulkan/VA-API e máquinas virtuais.
- A GPU secundária é a NVIDIA GeForce RTX 3080 Ti de 12 GB GDDR6X (GA102 / Ampere) localizada no barramento PCI `0000:09:00.0`.
- A GPU NVIDIA opera de forma estritamente headless dedicada exclusivamente para IA, LLMs locais, PyTorch e computação CUDA.
- O isolamento headless impede a criação de render nodes DRM na NVIDIA, blindando o Wayland, o QEMU e o GNOME Boxes contra conflitos de vídeo.
- O armazenamento primário é um SSD NVMe M.2 PCIe Gen4 de 1 TB (Asgard AN4 / Innogrit IG5236) em Btrfs com discos SATA e USB de 1 TB auxiliares.
- A conectividade de rede utiliza placa cabeada Intel I211 Gigabit Ethernet e placa sem fio Intel Wi-Fi 6E AX210 com Bluetooth 5.3.
- Os periféricos USB homologados incluem receptores de mouse VXE/Compx (`3554`), headset MCHOSE X9 (`3837`), teclado BY Tech (`258a`) e controlador RGB ITE IT8297 (`048d`).

## Imagens e Flavors do Projeto

- A imagem AMD (`kinoite-amd`) é otimizada exclusivamente para computadores com hardware 100% AMD.
- A imagem AMD não recebe nenhum arquivo, driver, módulo ou ajuste pertencente à imagem NVIDIA.
- A imagem NVIDIA (`kinoite-dual`) recebe todos os ajustes da imagem AMD e adiciona a camada de drivers e isolamento headless da NVIDIA.

## Receitas e Módulos BlueBuild

- `recipes/recipe-amd.yml`: manifesto principal que compila a imagem limpa para sistemas exclusivos AMD.
- `recipes/recipe-dual.yml`: manifesto principal que compila a imagem para estações Dual-GPU com display AMD e computação NVIDIA.
- `recipes/common-core.yml`: instala aplicativos essenciais do KDE Plasma, utilitários de monitoramento de hardware e suporte ao idioma português.
- `recipes/common-debloat.yml`: remove navegadores nativos redundantes, utilitários de boas-vindas e agentes de máquinas virtuais desnecessários em bare metal.
- `recipes/common-drivers.yml`: instala drivers de aceleração de vídeo Mesa Freeworld e codecs multimídia completos da RPM Fusion para a GPU AMD.
- `recipes/common-drivers-nvidia.yml`: compila o driver `nvidia-open` via akmods e aplica declarativamente os arquivos de isolamento headless de `files/nvidia/`.
- `recipes/common-fonts.yml`: instala a fonte de interface Inter Variable e as fontes monoespaçadas Nerd Fonts (JetBrainsMono, FiraCode e Symbols).
- `recipes/common-flatpaks.yml`: instala a seleção padronizada de aplicativos Flatpak de escopo de sistema para navegadores, desenvolvimento, IA e produtividade.
- `recipes/common-kargs.yml`: define a baseline compartilhada de argumentos de boot que desativa o framebuffer simpledrm.
- `recipes/common-kvm.yml`: instala a pilha de virtualização KVM/QEMU, GNOME Boxes e suporte a emulação de TPM 2.0.
- `recipes/common-systemd.yml`: habilita os serviços e timers de automação nos escopos de sistema e usuário e mascara o `systemd-remount-fs.service`.
- `recipes/common-tools.yml`: instala ferramentas modernas de linha de comando para produtividade no terminal, contêineres, sincronização em nuvem e diagnósticos de hardware.

## Kernel Arguments (Kargs) e Isolamento de Drivers

- `initcall_blacklist=simpledrm_platform_driver_init`: evita conflitos de framebuffer primitivo com o driver DRM da AMD durante o early boot.
- `rd.driver.blacklist=nouveau`: bloqueia o carregamento do driver open-source nouveau na fase de initramfs da imagem dual.
- `modprobe.blacklist=nouveau`: bloqueia o carregamento do driver open-source nouveau no userspace da imagem dual.
- `rd.driver.blacklist=nvidia-drm`: impede a inicialização do módulo de modosetting de vídeo da NVIDIA no initramfs da imagem dual.
- `modprobe.blacklist=nvidia-drm`: impede a criação do nó gráfico `/dev/dri/renderD129` pela NVIDIA preservando `/dev/nvidia*` e `/dev/nvidia-uvm` para CUDA.
- `files/nvidia/usr/lib/bootc/kargs.d/00-bluebuild-nvidia-kargs.toml`: sobrescreve declarativamente o arquivo gerado pelo akmods, eliminando `nvidia-drm.modeset=1` e aplicando o blacklist de `nouveau` e `nvidia-drm`.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia.conf`: substitui declarativamente a configuração padrão do dracut omitindo `nvidia_drm` da diretiva `force_drivers`.
- `files/nvidia/usr/lib/dracut/dracut.conf.d/99-nvidia-headless.conf`: reforça no dracut a omissão explícita dos módulos `nvidia_drm` e `nvidia-drm` da imagem do ramdisk.
- `files/nvidia/usr/lib/modprobe.d/60-nvidia-headless.conf`: bloqueia `nvidia-drm` no modprobe e redireciona tentativas de carregamento para `/usr/bin/true`.
- `files/nvidia/etc/pki/akmods/certs/akmods-ublue.der`: fornece o certificado público MOK para validação de módulos akmods pelo Secure Boot.

## Armazenamento, Memória, Btrfs NoCOW e ZRAM

- O sistema aplica o atributo Btrfs NoCOW (`+C`) em pastas de escrita aleatória intensa para evitar fragmentação e amplificação de escrita no NVMe.
- `files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`: aplica NoCOW nos diretórios de imagens do libvirt e armazenamento de contêineres Podman do sistema.
- `files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`: aplica NoCOW nas imagens do libvirt do usuário, máquinas do GNOME Boxes, contêineres rootless e cache do rclone.
- `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`: configura swap ZRAM em RAM com compressão zstd dimensionado em 50% da RAM até o limite de 32 GB.
- `files/system/usr/lib/sysctl.d/90-memory-fs-tuning.conf`: calibra `vm.swappiness=150` e `vm.page-cluster=0` para ZRAM, amplia watchers inotify para IDEs e reduz `dirty_ratio` para evitar engasgos de I/O no NVMe Gen4.
- `files/system/etc/security/limits.d/60-kinoite-limits.conf`: libera trava de memória ilimitada (`memlock unlimited`) em sessões PAM e SSH para carregamento de modelos LLM em RAM.
- `files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`: define `DefaultLimitMEMLOCK=infinity` para serviços de sistema e motores de inferência de IA.
- `files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf`: define `DefaultLimitMEMLOCK=infinity` para aplicações da sessão gráfica e contêineres Podman do usuário.

## Segurança, Resiliência e Integridade do Sistema

- O sistema exige autenticação obrigatória de root (`sulogin`) em consoles de recuperação e emergência, proibindo qualquer bypass sem senha.
- `files/system/usr/lib/sysctl.d/90-kernel-tuning.conf`: ativa o atalho seguro SysRq REISUB (`kernel.sysrq=1`), oculta ponteiros de kernel e define janela de 20 segundos antes de reiniciar após kernel panic.
- `files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf`: cria symlinks em `/etc/sysctl.d/` apontando para `/usr/lib/sysctl.d/` para impedir que perfis do TuneD sobrescrevam os sysctls do projeto.
- `files/system/usr/lib/modprobe.d/60-security-blacklist.conf`: desativa protocolos de rede obsoletos (sctp, tipc), sistemas de arquivos legados vulneráveis (jffs2, hfs, hfsplus) e drivers firewire conforme CIS Benchmark.
- `files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`: endurece o servidor SSH proibindo login de root, desativando senhas em favor de chaves criptográficas e desligando encaminhamento X11.
- `files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf`: reduz o intervalo de sincronização do journald para 30 segundos para preservar logs de diagnóstico no NVMe em caso de travamento abrupto.
- `files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`: configura `ShowStatus=error` no systemd para manter o boot silencioso e exibir mensagens na tela apenas se algum serviço falhar.

## Rede, DNS e Conexões Seguras

- `files/system/usr/lib/modules-load.d/60-bbr.conf`: carrega os módulos de kernel `sch_fq` e `tcp_bbr` automaticamente durante a inicialização.
- `files/system/usr/lib/sysctl.d/90-network-tuning.conf`: ativa controle de congestionamento TCP BBR com fila justa (`fq`), amplia buffers TCP para 32 MB, ativa TCP Fast Open e bloqueia redirecionamentos ICMP.
- `files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`: configura DNS-over-TLS estrito usando Control D (com bloqueio nativo de malware, anúncios e trackers) e Cloudflare como fallback.
- `files/system/usr/lib/firewalld/zones/tailscale.xml`: declara a zona confiável do firewall dedicada à interface `tailscale0` da VPN mesh.
- `files/dnf/tailscale.repo`: configura o repositório oficial da Tailscale para a VPN mesh.
- `files/dnf/terra.repo`: configura o repositório Terra da Fyra Labs para fornecimento de ferramentas complementares de terminal.

## Atualização Contínua e Timers Automáticos

- As atualizações de imagem base, Flatpaks e contêineres ocorrem em segundo plano quando o computador está conectado à energia.
- Todos os serviços de atualização e limpeza rodam com prioridade mínima (`Nice=19`, `CPUSchedulingPolicy=idle` e `IOSchedulingClass=idle`) para zero impacto no uso de desktop ou IA.
- `files/system/usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/override.conf`: ajusta o serviço nativo do Bootc para baixar e preparar atualizações silenciosamente (`bootc update --quiet`) em prioridade ociosa.
- `files/system/usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/override.conf`: aciona a busca de atualizações do sistema operacional 5 minutos após o boot e repete a cada 45 minutos.
- `files/system/usr/lib/systemd/system/flatpak-system-update.service`: atualiza todos os Flatpaks do sistema e remove runtimes órfãos de forma automática.
- `files/system/usr/lib/systemd/system/flatpak-system-update.timer`: dispara a atualização de Flatpaks do sistema 5 minutos após o boot e repete a cada 45 minutos.
- `files/system/usr/lib/systemd/user/flatpak-user-update.service`: atualiza Flatpaks instalados no escopo do usuário e limpa dependências sem uso.
- `files/system/usr/lib/systemd/user/flatpak-user-update.timer`: dispara a atualização de Flatpaks do usuário 5 minutos após o login e repete a cada 45 minutos.
- `files/system/usr/lib/systemd/system/podman-auto-update.service.d/override.conf`: restringe a atualização automática de contêineres do sistema ao funcionamento na tomada e em prioridade ociosa.
- `files/system/usr/lib/systemd/system/podman-auto-update.timer.d/override.conf`: verifica atualizações de contêineres do sistema 5 minutos após o boot e a cada 45 minutos.
- `files/system/usr/lib/systemd/user/podman-auto-update.service.d/override.conf`: executa a atualização automática de contêineres do usuário em prioridade ociosa de CPU e I/O.
- `files/system/usr/lib/systemd/user/podman-auto-update.timer.d/override.conf`: verifica atualizações de contêineres do usuário 5 minutos após o login e a cada 45 minutos.
- `files/system/usr/lib/systemd/system/kinoite-maintenance.service`: remove contêineres parados, volumes e imagens órfãs do sistema e limita o journald a 200 MB ou 14 dias.
- `files/system/usr/lib/systemd/system/kinoite-maintenance.timer`: agenda a execução da limpeza de sistema semanalmente com persistência.
- `files/system/usr/lib/systemd/user/kinoite-user-maintenance.service`: remove contêineres parados, volumes e imagens não utilizadas do Podman no escopo do usuário, limita o journald do usuário a 100 MB ou 14 dias e exclui miniaturas com mais de 30 dias.
- `files/system/usr/lib/systemd/user/kinoite-user-maintenance.timer`: agenda a limpeza semanal de contêineres e caches do usuário.
- `files/system/usr/lib/systemd/system/kinoite-boot-init.service`: oculta automaticamente o menu do GRUB (`timeout=0` e `menu_auto_hide=2`) no primeiro boot preservando o acesso via tecla Shift.

## Navegadores, Interface Gráfica e Desktop

- `files/system/usr/share/browser-configs/chromium-flags.conf`: ativa backend Wayland nativo, rasterização em GPU AMD, zero-copy, decodificação VA-API e desativa telemetria em navegadores baseados em Chromium.
- `files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf`: copia declarativamente as flags de aceleração para as pastas de configuração do Brave e Google Chrome no login do usuário.
- `files/system/usr/share/browser-configs/plasma-browser-integration.override`: template único que concede permissão D-Bus para integração de mídia e downloads dos navegadores com o KDE Plasma.
- `files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`: provisiona os overrides Flatpak para Brave, Chrome, Firefox e VS Code em `/var/lib/flatpak/overrides/`.
- `files/system/usr/share/flatpak/overrides/com.visualstudio.code`: libera acesso de leitura ao socket do Podman e ativa Wayland nativo no VS Code Flatpak.
- `files/system/etc/fonts/conf.d/64-font-rendering.conf`: configura hinting leve e subpixel RGB, define Inter Variable como fonte sans-serif padrão e prioriza JetBrainsMono Nerd Font com fallback de símbolos.
- `files/system/etc/xdg/baloofilerc`: exclui o cache do rclone e montagens FUSE em `/run/user` da indexação de arquivos do KDE Baloo.
- `files/system/etc/xdg/dolphinrc`: desativa restauração de abas antigas, oculta barra de menus e ativa pré-visualização completa de miniaturas locais no Dolphin.
- `files/system/etc/xdg/kdeglobals`: aplica tema Breeze Dark com destaque azul, animações rápidas (0.5x), clique simples para abrir itens e desativa miniaturas em pastas remotas.
- `files/system/etc/xdg/kiorc`: exige confirmação antes de excluir permanentemente arquivos ou esvaziar a lixeira.
- `files/system/etc/xdg/konsolerc`: define o perfil `Kinoite.profile` como padrão no terminal Konsole e oculta a barra de menus.
- `files/system/usr/share/konsole/Kinoite.profile`: configura o Konsole com fonte JetBrainsMono Nerd Font tamanho 10, histórico de 10.000 linhas e esquema de cores Kinoite.
- `files/system/usr/share/konsole/Kinoite.colorscheme`: define a paleta de cores escura de alto contraste do terminal Konsole.
- `files/system/usr/share/starship/starship.toml`: configura o prompt Starship em linha única com indicadores enxutos de diretório, branch Git, linguagens, contêiner/Distrobox e duração de comandos.
- `files/system/etc/profile.d/50-shell-env-overrides.sh`: inicializa FZF (com `fd`), Starship e Zoxide em shells interativos Bash/Zsh e executa o Fastfetch apenas uma vez por sessão de terminal.
- `files/system/etc/profile.d/60-kinoite-aliases.sh`: disponibiliza aliases para `eza`, `bat`, `btop`, `topgrade`, proteção interativa (`cp -i`, `rm -i`) e atalhos rápidos de diagnóstico de serviços, GPUs e Bootc.
- `files/system/usr/share/topgrade/10-kinoite.toml`: define as exclusões declarativas de passos conflitantes ou redundantes no sistema imutável para o atualizador Topgrade.
- `files/system/usr/share/user-tmpfiles.d/70-topgrade.conf`: provisiona o drop-in de configuração do Topgrade em `~/.config/topgrade.d/` automaticamente no login do usuário.

## Aceleração de IA, CDI, Periféricos e Virtualização

- `files/system/etc/cdi/amdgpu.yaml`: define a especificação Container Device Interface (CDI) `amd.com/gpu` expondo `/dev/kfd` e os nós PCI `0000:0c:00.0` da RX 6600 XT com `HSA_OVERRIDE_GFX_VERSION=10.3.0`.
- `files/system/usr/lib/environment.d/60-kinoite-environment.conf`: exporta globalmente `HSA_OVERRIDE_GFX_VERSION=10.3.0` para ROCm, escurecimento de hastes de fontes FreeType e suporte Wayland para apps Electron.
- `files/system/usr/lib/udev/rules.d/70-peripherals.rules`: aplica tag `uaccess` nos periféricos USB homologados e em `/dev/kfd`, cria o symlink determinístico `/dev/dri/primary-render` para a GPU AMD (`0000:0c:00.0`) e força escalonador `none` no NVMe.
- `files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`: autoriza usuários do grupo `wheel` a gerenciar conexões e máquinas virtuais do libvirt/KVM sem prompts de senha.
- `files/system/etc/containers/nodocker`: silencia avisos de compatibilidade quando a CLI `docker` redireciona comandos para o Podman.

## Integração com Armazenamento em Nuvem (Rclone)

- `files/system/usr/lib/systemd/user/rclone@.service`: unidade template de usuário que monta qualquer remoto Rclone em `/run/user/%U/cloud/%i` via FUSE com cache VFS completo, limites de banda de I/O e auto-recuperação.
- `files/system/usr/share/rclone/env/GoogleDrive.env`: define parâmetros otimizados para a API do Google Drive (12 TPS, chunks de 64M, uso de lixeira e ocultação de Google Docs nativos).
- `files/system/usr/share/rclone/env/OneDrive.env`: define parâmetros seguros contra throttling HTTP 429 da API Microsoft Graph (5 TPS, Delta API ativa e chunks de 50M múltiplos de 320 KiB).
- `files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf`: cria a árvore `~/.config/rclone/env/` e o diretório de montagem `/run/user/%U/cloud` e copia os perfis padrão do Google Drive e OneDrive no login do usuário.

## Utilitários Locais de Manutenção e Auditoria

- `files/system/usr/bin/kinoite-optimize`: ferramenta administrativa dividida em 8 fases (sysctl, tmpfiles/NoCOW, saúde Btrfs, desfragmentação de VMs, retenção de logs, limpeza de Flatpak/Podman, saneamento de kargs e auditoria) e modo somente leitura `--audit` dos 6 pilares do sistema.
- `files/system/usr/bin/kinoite-setup-tpm`: utilitário seguro que vincula a partição LUKS2 ao fTPM 2.0 (PCRs 7 + 14) com suporte a PIN de inicialização, preservando chaves de recuperação existentes e removendo slots antigos somente após sucesso do novo registro.

## CI/CD, Pipelines e Assinatura Criptográfica

- `.github/workflows/build.yml`: workflow parametrizado que compila as imagens (`amd`, `dual` ou `all`) via BlueBuild e assina os contêineres com a chave privada Cosign.
- `.github/workflows/check-updates.yml`: rotina executada a cada 2 horas que compara o digest da imagem base upstream com o label `org.opencontainers.image.base.digest` publicado no GHCR e aciona o build apenas quando há atualização real.
- `.github/workflows/cleanup.yml`: rotina diária que remove versões antigas das imagens `kinoite-amd` e `kinoite-dual` em paralelo (mantendo as 15 mais recentes) e limpa históricos de execuções de workflows.
- `.github/dependabot.yml`: verifica semanalmente atualizações de versão das GitHub Actions utilizadas nos workflows.
- `cosign.pub`: chave pública embutida e versionada para verificação criptográfica das imagens com `bootc switch --enforce-container-sigpolicy`.

## Invariantes de Engenharia e Regras Proibidas

- É terminantemente proibido adicionar `nvidia-drm.modeset=1` ou permitir a criação de render nodes DRM na GPU secundária NVIDIA.
- É proibido desativar a autenticação `sulogin` em modo de resgate ou emergência.
- É proibido adicionar kargs redundantes ou obsoletos como `preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt` ou `amd_pstate=active`.
- É proibido colocar arquivos de configuração de sistema em `/etc/` quando o subsistema suportar diretórios em `/usr/lib/` ou `/usr/share/` (exceções válidas no Fedora: `profile.d`, `security/limits.d`, `ssh/sshd_config.d`, `containers/nodocker`, `fonts/conf.d`, `xdg`, `cdi` e `pki/akmods/certs`).
- É proibido realizar downgrade de pacotes base do Fedora ou reintroduzir scripts imperativos (`type: script`) nas receitas quando houver solução declarativa.

## Critérios para Adição de Novos Softwares

- Aplicativos com interface gráfica devem ser instalados exclusivamente via Flatpak em `recipes/common-flatpaks.yml`.
- Linguagens de programação, SDKs e ambientes de desenvolvimento devem rodar isolados em contêineres Distrobox ou Podman.
- A imagem base OSTree recebe apenas drivers de hardware, virtualização, serviços de infraestrutura e utilitários CLI essenciais.
- Configurações de aplicativos de usuário devem ser aplicadas via `user-tmpfiles.d` usando templates armazenados em `/usr/share/`.
