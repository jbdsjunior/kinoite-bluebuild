# Prompt Principal do Projeto (kinoite)

## Visão Geral, Imagens e Governança

- O projeto constrói imagens imutáveis sobre Fedora Kinoite (`image-version: latest`) via Bootc e BlueBuild, priorizando declarações nativas em vez de scripts imperativos.

- O repositório gera duas variantes oficiais: `kinoite-amd` (100% AMD, sem nenhum vestígio NVIDIA) e `kinoite-cuda` (base AMD para vídeo/Wayland/VMs com GPU NVIDIA headless dedicada exclusivamente a CUDA e computação).

- A imagem é configurada nativamente para português do Brasil (`langpacks-pt_BR`), preservando o layout físico de teclado configurado no host (`us-alt-intl`).

- A governança técnica é dividida entre regras de processo/Git/validação para agentes, catálogo técnico completo de arquivos/invariantes, visão geral em inglês, política de segurança Cosign, guia operacional pós-instalação e este prompt local como fonte principal de intenção.

- O projeto embute a chave pública Cosign para verificação criptográfica das imagens via `bootc`.

- O repositório adota a licença Apache 2.0 e mantém o `.gitignore` bloqueando segredos e overrides locais.

## Hardware Alvo e Desempenho

- O sistema é calibrado para workstation com AMD Ryzen 9 5950X (`amd-pstate-epp`), placa Gigabyte X570 AORUS PRO WIFI (Secure Boot + fTPM 2.0), 64 GB DDR4, NVMe PCIe Gen4 em Btrfs e rede Intel GbE.

- O Wi-Fi 6E Intel AX210 desativa economia de energia (`power_save=0`) e força modo ativo.

- O swap em RAM usa ZRAM `zstd` dimensionado em 50% da RAM até 32 GB (superando o padrão 8 GB `lzo-rle` do Fedora), pareado com `vm.swappiness=150` e `vm.page-cluster=0`.

- O kernel eleva `fs.inotify.max_user_instances=8192` para suportar múltiplos watchers simultâneos em IDEs e contêineres.

- Os parâmetros de kernel mantêm `kernel.sysrq=1` (REISUB) e visibilidade de logs críticos no console, protegidos em `/run/sysctl.d/` contra sobrescrita pelo TuneD (`reapply_sysctl=1`) sem sujar `/etc/` (confiando no `kptr_restrict=1` já nativo do Fedora 45).

- A pilha de rede pré-carrega `sch_fq` e `tcp_bbr`, ativa controle de congestionamento BBR com `fq`, habilita TCP Fast Open (`tcp_fastopen=3`) e bloqueia redirects ICMP contra adulteração de rotas.

- Toda identificação de GPUs, periféricos USB homologados e dispositivos Android ADB/Fastboot usa detecção dinâmica por driver ou atributos (`uaccess`), sem endereços PCI estáticos.

## GPUs, ROCm e Isolamento NVIDIA Headless

- A GPU primária AMD Radeon RX 6600 XT (`amdgpu`) atende exclusivamente Wayland, KDE Plasma, aceleração VA-API (`radeonsi`) e Vulkan RADV.

- A camada AMD ROCm/HIP na RX 6600 XT exporta `HSA_OVERRIDE_GFX_VERSION=10.3.0`, garante acesso `uaccess` em `/dev/kfd`, cria o link `/dev/dri/primary-render` e expõe a spec CDI `amd.com/gpu`.

- Na variante CUDA, a GPU secundária NVIDIA RTX 3080 Ti recebe o driver `nvidia-open` (`MULTILIB=0`) e certificado público MOK para Secure Boot, mantendo `nvidia-persistenced` ativo e `nvidia-powerd` mascarado.

- O isolamento headless NVIDIA remove `nvidia-drm.modeset=1` nos argumentos de kernel, bloqueia `nouveau` e `nvidia-drm` no initramfs e userspace, ativa Resizable BAR e força EGL/GLX/Vulkan do host (inclusive daemons com ambiente limpo) para Mesa AMD, reservando a NVIDIA apenas para CUDA/CDI.

## Organização Modular e Herança de Configurações

- Os overlays seguem separação estrita por domínio (base do sistema, desktop, shell/CLI, nuvem Rclone, virtualização, computação ROCm, rede mesh Tailscale, camada CUDA/NVIDIA e repositórios DNF externos).

- As configurações do sistema residem em `/usr/lib/` e `/usr/share/`, usando `/etc/` apenas quando o subsistema exige esse caminho.

- As configurações padrão de usuário são herdadas diretamente de `/etc/xdg/`, `/usr/share/` e variáveis de ambiente, sem criar ou copiar arquivos para `$HOME`.

- As regras `user-tmpfiles.d` limitam-se à marcação Btrfs NoCOW (`+C`) nos diretórios de imagens de VMs de usuário e no cache VFS do Rclone.

## Rede, DNS, Virtualização e Nuvem

- O `systemd-resolved` usa Control D "p2.freedns.controld.com" com fallback Cloudflare em `DNSOverTLS=opportunistic` e `DNSSEC=no` (delegando `.local` ao Avahi), garantindo DoT na internet e compatibilidade com o MagicDNS da Tailscale.

- O firewall cria uma zona confiável dedicada para a interface `tailscale0`, mantendo o daemon `tailscaled` habilitado na imagem.

- A virtualização KVM/Libvirt integra `gnome-boxes` em RPM, sockets modulares via preset upstream (`socket activation`) e regra Polkit liberando gerenciamento local ao grupo `wheel` sem senha (`qemu:///system` para `virt-manager`/`virbr0` e `qemu:///session` em modo _usermode_ para `gnome-boxes`/VMs sem root).

- As montagens em nuvem via Rclone operam sob demanda por unidade template de usuário em `/run/user/$UID/cloud/`, herdando perfis de Google Drive (chunks 64M, lixeira em nuvem) e OneDrive (chunks 50M múltiplos de 320 KiB, Delta API) direto de `/usr/share/` com override opcional local.

## Atualizações Automáticas e Topgrade

- As atualizações automáticas de sistema (`bootc upgrade --quiet`) e de Flatpaks (sistema e usuário) rodam 1 minuto após o boot/login e a cada 30 minutos em prioridade ociosa, aguardando rede online via `nm-online` (timeout `15s`) sem gerar erro quando offline.

- O `topgrade` atua como atualizador manual unificado (desabilitando etapas conflitantes como `toolbx` e `tailscale`), herdando sua configuração diretamente de `/usr/share/` via wrapper no shell sem copiar arquivos para `$HOME`.

## Desktop, Terminal, Pacotes e CI/CD

- O KWin centraliza automaticamente novas janelas de aplicativos na área útil do monitor em Wayland, combinando `Placement=Centered` com o script `kinoite-window-center` para contornar falhas de posicionamento do Plasma 6.

- O Konsole usa perfil próprio, esquema de cores Tokyo Night translúcido com blur e barra de menus oculta.

- As fontes Nerd Fonts (`JetBrainsMono`, `FiraCode`) e `Inter Variable` são instaladas na imagem e mapeadas globalmente via Fontconfig sem sobrescrever preferências de renderização do usuário.

- As receitas removem bloatware da base (`firefox` e notificadores `rpm-ostree`), mantendo o `kwrite`.

- As receitas instalam codecs multimídia do RPM Fusion e aceleração gráfica/computacional AMD (`mesa-va-drivers-freeworld`, `mesa-libOpenCL`).

- As receitas instalam ferramentas CLI modernas (`starship`, `fastfetch`, `topgrade`, `tailscale`, `rclone`, `distrobox`) via repositórios Tailscale/Terra e 13 aplicativos gráficos ativos via Flatpak.

- O workflow principal compila as imagens via BlueBuild (`chunkah`) e realiza assinatura criptográfica com Cosign.

- Os workflows auxiliares verificam exclusivamente se a imagem base upstream mudou em relação ao GHCR a cada 1 hora (sem verificar o repositório local e respeitando o plano gratuito com backoff em falhas), limpam versões antigas no GHCR mantendo 15 e atualizam actions semanalmente via Dependabot.

## Funcionalidades dos Scripts e Utilitários

- **Manutenção de sistema e NoCOW (`kinoite-optimize`):** detecta GPUs dinamicamente por driver e sincroniza `tmpfiles` e atributos NoCOW em discos de VMs e cache Rclone.

- **Manutenção de armazenamento (`kinoite-optimize`):** limpa `.Trash-*` em montagens nuvem, executa `balance` e `fstrim` em `/var/home`, audita/desfragmenta imagens de VM acima de 5000 extents e compacta imagens `.qcow2` desligadas.

- **Higienização de caches (`kinoite-optimize`):** limpa caches (`journald`, thumbnails) e remove imagens Podman órfãs.

- **Auditoria somente leitura (`kinoite-optimize --audit`):** valida os 6 pilares do sistema (armazenamento, ZRAM/sysctl, GPUs/IOMMU, rede/DNS/firewall, systemd/serviços e boot/TPM) sem modificar o host.

- **Provisionamento TPM 2.0 (`kinoite-setup-tpm`):** detecta a partição LUKS2 raiz, gera chave de recuperação offline de forma idempotente, vincula o desbloqueio ao fTPM 2.0 (PCRs 7+14) com PIN opcional e atualiza `/etc/crypttab` validando a integração Bootc.

- **Prompt e telemetria de shell:** ignora sessões não-interativas, inicializa o Starship herdando o tema da imagem e exibe o Fastfetch uma única vez por sessão fora de terminais embutidos do VS Code, sem gravar em `$HOME`.

- **Aliases e wrapper de terminal:** fornece proteção interativa (`cp -i`, `mv -i`, `rm -i`), wrapper inteligente do Topgrade (`topgrade`, `update`, `update-all`), atalhos de recuperação (`rollback`, `sysup` com `bootc upgrade`, `kargs`, `config-diff`), consulta de serviços (`status-*`, `logs-rclone`) e manutenção (`optimize`, `sys-optimize`, `setup-tpm`, `podman-cleanup`).

## O que Foi Removido do Projeto

- **Padrões de kernel/armazenamento já nativos no Fedora 45:** regra NVMe (`scheduler=none`, `add_random=0`), limite `fs.inotify.max_user_watches` e `kernel.kptr_restrict=1`.

- **Padrões de drivers/serviços já nativos ou substituídos:** substituição forçada `ocl-icd`/`OpenCL-ICD-Loader`, NoCOW de sistema em `/var/lib/libvirt/images`, serviço contínuo `virtqemud-session` (substituído por socket activation), remoção redundante de `org.gnome.Boxes` Flatpak, `common-kargs.yml` (`simpledrm` movido apenas para `kinoite-cuda` preservando `kmscon` no `kinoite-amd`) e redeclaração redundante de `bootc-fetch-apply-updates.timer`.

- **Configurações arriscadas de memória e storage:** limites globais `memlock=infinity`, NoCOW em storage do Podman (prejudicava reflinks/compressão do OverlayFS) e symlinks persistentes em `/etc/sysctl.d/`.

- **Ajustes de rede e memória voltados a servidores:** buffers TCP de 32 MB, `tcp_fin_timeout`, `netdev_max_backlog`, `watermark_scale_factor`, `dirty_*`, `vfs_cache_pressure` e reboots agressivos em `panic_on_oops`/`hardlockup_panic`.

- **Customizações de boot removidas por baixa utilidade:** GRUB auto-hide forçado, silenciamento excessivo de boot/initrd e ajuste de THP defrag.

- **Daemons, regras e overrides obsoletos:** dispatcher iSCSI, override do `smartd`, retenção customizada do `journald`, remoção de daemons Intel em CPU AMD e arquivo duplicado de dracut NVIDIA.

- **Endurecimentos sem aplicação local:** hardening SSHD em workstation sem SSH ativo e blacklist CIS de módulos raros.

- **Timers de manutenção automática removidos:** scrub Btrfs mensal automático e limpeza semanal automática de imagens Podman (mantendo `podman.socket`, `podman-auto-update.timer` e `podman-restart.service` ativos em `common-systemd.yml`).

- **Sobrescritas antigas de desktop e usuário:** overrides globais de aparência/comportamento KDE, áudio, navegadores e Flatpak, além de cópias automáticas de configs em `$HOME`.

- **Pacotes e units opcionais descartados:** `lm_sensors` (substituído por `/sys/class/hwmon/`), pacotes RPM opcionais comentados (`kio-admin`, `ksshaskpass`, `plasma-firewall`, `qt6-qtimageformats`, `rasdaemon`, `clinfo`, `libva-utils`, `vulkan-tools`, `git`, `nvtop`, remoção de `kwrite` no debloat) e máscaras/serviços comentados (`lm_sensors`, `dnf-makecache`, `NetworkManager-wait-online`, `raid-check`, `systemd-remount-fs`, `rasdaemon`, `drkonqi-coredump-pickup`).

## O que Permanece Desabilitado para Avaliação

- **Aplicativos Flatpak opcionais comentados:** 11 aplicativos de produtividade, segurança, contêineres, IA e mídia mantidos em reserva para seleção gradual.

- **Validação pós-boot — desktop e `$HOME`:** confirmar a centralização automática de janelas no Plasma 6 Wayland e a ausência de cópias automáticas em `$HOME`.

- **Validação pós-boot — rede e automação:** confirmar DNS Control D P2 + Tailscale MagicDNS e timers de 30 minutos antes de reativar itens pendentes.
