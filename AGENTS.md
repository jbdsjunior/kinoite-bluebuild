# Diretrizes do Sistema Multiagente (`AGENTS.md`)

Este arquivo define as regras permanentes de arquitetura, princípios de execução, baseline de hardware e invariantes de engenharia para todos os agentes que operam no repositório `kinoite-bluebuild`.

## 1. Diretriz Obrigatória de Versionamento Git

Este repositório consolida autoritativamente todas as convenções e disciplinas de Git neste arquivo, eliminando arquivos e diretórios redundantes de skills.

- **Commit Obrigatório em Modificações:** Toda e qualquer tarefa que altere, adicione ou remova arquivos no repositório DEVE ser finalizada com a execução de commit Git estruturado antes de considerar a tarefa concluída. Nunca encerre uma interação deixando alterações pendentes ou `working tree dirty`.
- **Padrão de Mensagem (Conventional Commits):**
  - Formato estrito: `<type>(<scope>): <descrição sucinta no presente>`
  - Tipos válidos:
    - `feat`: Nova funcionalidade, recurso ou capacidade.
    - `fix`: Correção de bug, vulnerabilidade de segurança ou ajuste de estabilidade.
    - `docs`: Modificações exclusivamente em arquivos de documentação e governança.
    - `refactor`: Alteração estrutural em código/configurações sem alteração de comportamento funcional.
    - `chore`: Ajustes de ferramentas, workflows de CI, dependências ou governança.
  - Corpo obrigatório: Lista em tópicos (*bullet points*) detalhando as decisões técnicas, parâmetros alterados, impacto operacional e arquivos afetados.
- **Disciplina de Staging e Higiene de Arquivos:**
  - Adicionar arquivos explicitamente (`git add <arquivo1> <arquivo2>`). É proibido adicionar arquivos em lote cegamente (`git add .`) quando houver arquivos de rascunho, chaves privadas ou credenciais.
  - Validar previamente o estado com `git status` e inspecionar o diff preparado com `git diff --cached` antes de consolidar o commit.
- **Validação de Integridade da Árvore de Trabalho:**
  - Executar `git status` pós-commit para certificar que a working tree está rigorosamente limpa (`working tree clean`).
  - Reportar ao usuário o hash gerado e o comando exato de sincronização remota (`git push origin <branch>`).

## 2. Papel dos Agentes e Princípios de Execução

- **Estrutura Multiagente:** Atue como um sistema multiagente (Executor e Revisor) orientado para evolução, auditoria e otimização contínua deste repositório.
  - O **Executor** implementa as mudanças técnicas.
  - O **Revisor** analisa, pesquisa na web quando necessário, critica e exige refinamentos. O processo deve iterar em loop até que o Revisor esteja plenamente satisfeito, sem ressalvas.
- **Prioridade Absoluta:** Segurança > Performance > Conveniência. Elimine vulnerabilidades, permissões excessivas e dívida técnica de forma proativa.
- **Design (KISS):** Evite over-engineering. Utilize ferramentas nativas e modernas, eliminando redundâncias. É proibido realizar downgrade de pacotes ou utilizar daemons legados quando houver alternativas modulares.
- **Resiliência:** Para qualquer alteração crítica, emitir alerta explícito e fornecer comando exato de rollback.
- **Formato (Zero Overhead):** Sem saudações, preâmbulos, encerramentos ou justificativas não solicitadas. Scripts shell devem ser estritamente lineares, sem funções desnecessárias. Comentários apenas para alertas críticos de segurança ou fluxo essencial, em inglês técnico.
- **Solução Comprovada:** Entregar apenas o caminho mais seguro e comprovado, com justificativa concisa.
- **Bloqueio e Pesquisa:** Interromper e solicitar informações adicionais se faltar contexto ou realizar pesquisa na web quando necessário. Faça ajustes apenas quando for preciso e necessário.

## 3. Ambiente e Hardware Baseline

- **Processador & Gráficos:** AMD Ryzen 9 5950X (16C/32T, Zen 3, dual-CCD), AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23 / RDNA2).
- **Placa-mãe:** Gigabyte X570 AORUS PRO WIFI, BIOS F39 (AGESA ComboV2 1.2.0.x), microcode `0xa201213`.
- **Memória:** 64 GB DDR4 **não-ECC, kits mistos** (4×16 GB, 2 DIMMs/canal): `DIMM 0` (A1/B1) = genérico 16 GB 1R 3200; `DIMM 1` (A2/B2) = KingSpec `KS3200D4R13516G` 16 GB 2R 3200 (1.2V JEDEC). Topologia 3 ranks/canal — a mais sensível do IMC Zen 3 (Infinity Fabric/ProcODT/VSOC).
- **Armazenamento:** 1 TB NVMe PCIe Gen4 (Btrfs).
- **Sistema Operacional:** Fedora Kinoite 44 (imutável, Wayland nativo, modelo `bootc`, KDE Plasma 6).
- **Workloads do Usuário:** DevSecOps, desenvolvimento de software, inferência local de LLMs (ROCm/HIP via CDI em contêineres), navegação intensiva, virtualização KVM.
- **Periféricos Homologados:**
  - **Headset USB:** MCHOSE X9 (ALSA quirks em `51-mchose-x9.conf`).
  - **Fones Bluetooth TWS:** Baseus Bass EP10 Pro (LDAC/AAC/SBC, Bluetooth 5.4, Hi-Res Audio Wireless).
  - **Caixa de Som Bluetooth:** Tribit XSound Go (em avaliação A/B com stack nativa de áudio).
  - **Periféricos HID:** VXE Mouse, BY Tech (udev uaccess em `70-peripherals.rules`).
- **Diagnóstico e Resiliência de Hardware:**
  - **RAS (`rasdaemon`):** Registra MCE (cache/core/Data Fabric), PCIe AER e erros de bloco em `/var/lib/rasdaemon/ras-mc_event.db` (consulta via `sudo ras-mc-ctl --errors`). Com DIMMs não-ECC o `amd64_edac` não carrega: **erros de DRAM são invisíveis ao kernel** e só podem ser detectados por teste ativo (MemTest86 / `stressapptest`). É proibido afirmar cobertura EDAC de DRAM nesta plataforma.
  - **Calibração de BIOS e Proteção Térmica de DRAM:** Fonte única e detalhada em [`docs/POST_INSTALL.md` §14](docs/POST_INSTALL.md). Invariantes mínimas: `Extreme Memory Profile (X.M.P.) = Profile1` homologado oficialmente como perfil padrão baseline (`Profile A`) para DDR4-3200; `Power Supply Idle Control = Typical Current Idle`; `CPPC` + `CPPC Preferred Cores` = `Enabled` (sem eles o `amd-pstate-epp` não carrega — `_CPC object is not present in SBIOS`); FCLK:UCLK:MEMCLK 1:1 síncrono em 1600 MHz (`UCLK DIV1 MODE = UCLK==MEMCLK`); PBO stock (PPT 142W, TDC 95A, EDC 140A) e Curve Optimizer desativado até validação de estabilidade (nunca aplicar CO negativo nos núcleos preferenciais como Cores 0 e 3); sub-tensões fixadas contra flutuações e overshoot térmico do modo Auto sob XMP (teto de DRAM Voltage em 1.350V ou undervolt estável em 1.300V–1.320V limitando dissipação jouleiana $P \propto V^2$, VSOC estritamente manual em 1.100V com teto de 1.150V para suprimir os 1.20V–1.25V do modo Auto que superaquecem o plano de cobre do soquete AM4 adjacente aos slots A1/A2, VDDG IOD 1.000V, VDDG CCD 0.950V, cLDO VDDP 0.900V); preservação estrita de timings de recarga capacitiva `tRFC` / `tREFI` em `Auto` para evitar bit-flips por fuga térmica em ICs de 8Gb; ativação de `Auto Self Refresh (ASR)` / `Extended Temperature Range` no AMD CBS (força taxa de refresh dobrada 2x próximo a 85 °C); fluxo de ar ativo obrigatório no gabinete sobre os 4 slots DIMM contíguos; impedâncias terminadas para 3 ranks/canal (ProcODT 40.0 Ω, RttWr RZQ/3 80 Ω, RttPark RZQ/5 48 Ω, CAD_BUS DrvStr 24-24-24-24 Ω); barramento com `Gear Down Mode = Enabled`, `Power Down Enable = Disabled` e `Memory Context Restore = Disabled`; `TSME = Disabled` (elimina latência de encriptação em DRAM); `CSM = Disabled`, `Above 4G Decoding` + `Re-Size BAR` + `SVM` + `IOMMU` = `Enabled`.
- **Anti-Patterns de Hardware Proibidos:**
  - **CPU (Zen 3 5950X):** Proibido `preempt=full` (contenção e latência de escalonamento em 32 threads/2 CCDs), omitir `tsc=reliable` (desativa o watchdog de clocksource, evitando falsos positivos `Watchdog remote CPU read timed out` que rebaixam o TSC para HPET entre CCDs) ou utilizar `amd_iommu=on` (parâmetro inexistente). `nowatchdog` desativa os detectores de soft/hard lockup (elimina jitter de NMI em 32 threads); trade-off aceito: hard lockups puros não disparam `kernel.panic`, restando SysRq REISUB.
  - **BIOS / Memória:** Proibido inverter a terminação de slots daisy-chain (módulos dual-rank 2R devem residir obrigatoriamente nas pontas A2/B2 e 1R em A1/B1; inverter causa reflexão de sinal nos stubs e corrupção no barramento DQ). Proibido ativar TSME (penalidade de 2-4 ns e ~3% em throughput). Proibido deixar VSOC/VDDG/ProcODT ou DRAM Voltage em `Auto` sob perfil XMP com 4 DIMMs mistos (gera picos de tensão, desestabiliza o IMC Zen 3 e induz sobreaquecimento no plano de cobre AM4). Proibido apertar manualmente `tRFC` ou `tREFI` em topologia de 4 DIMMs mistos (induz fuga de carga capacitiva e corrupção térmica silenciosa de dados). Proibido operar os 4 DIMMs contíguos sob cargas contínuas sem fluxo de ar ativo direcionado aos slots. Proibido Curve Optimizer negativo nos núcleos preferenciais de silício (Cores 0 e 3), PBO com limites "Motherboard"/scalar elevado (> 1X) ou frequências acima de DDR4-3200 nesta topologia de kits mistos 1R+2R sem validação prévia (MemTest86 ≥ 4 passes + `stressapptest` ≥ 1 h). Proibido `Memory Context Restore = Enabled` com 4 DIMMs mistos (pula retreinamento e mascara margens marginais).
  - **GPU (Navi 23 6600 XT):** Proibido ativar flags experimentais de decodificação de vídeo (`AcceleratedVideoDecodeLinuxZeroCopyGL`, `AcceleratedVideoDecodeLinuxGL`), causadoras de GPU hangs e deadlocks no driver Mesa/AMDGPU, e proibido instalar stacks pesadas de ROCm no host (usar estritamente CDI containerizado).
  - **Memória & Armazenamento:** Proibido `page_alloc.shuffle=1` (fragmentação do alocador de páginas), limites manuais restritivos em parâmetros auto-escaláveis (`inotify`) e gravação com CoW ativo em VMs, contêineres e modelos de IA (obrigatório NoCOW `+C`).
  - **Áudio & Conectividade:** Proibido desativar `bluez5.hw-volume` em fones TWS (induz assimetria de ganho analógico) e proibido ativar encaminhamento IP global (`net.ipv4.ip_forward`) no sysctl.

## 4. Restrições do Projeto

- **Sem Redundâncias de SO:** Não incluir ajustes ou configurações redundantes já presentes por padrão no Linux/Fedora Kinoite 44.
- **Automação de Atualizações:** Timers de atualização (`bootc`, Flatpak do sistema e usuário, Podman, soar) iniciam exatamente 5 minutos após o boot (`OnBootSec=5m`) e repetem a cada 45 minutos (`OnUnitActiveSec=45m`). Devem possuir guarda de resiliência de rede obrigatória via script executável centralizado `/usr/libexec/kinoite/network-guard` (`ExecCondition`), inspecionando o `NetworkManager` via D-Bus para abortar sem erro em conexões limitadas/offline.
- **Checagem de Atualização Upstream:** Executada via GitHub Actions (`check-updates.yml`) a cada 2 horas (`0 */2 * * *`) de forma otimizada para cotas de CI.
- **Qualidade Visual:** Garantir qualidade mínima equivalente ou superior a sistemas modernos (estilo macOS), com foco em terminal, Konsole e tipografia.
- **Referência Técnica:** Soluções e melhorias podem utilizar como base referências comprovadas do projeto Bazzite Linux.
- **Eliminação de Instabilidade:** Configurações incorretas, instáveis ou irrelevantes devem ser removidas proativamente. Manter opções secundárias comentadas apenas quando pertinente.

## 5. Invariantes e Regras de Engenharia do Sistema

- **Validação e Estabilidade de Kernel Arguments:**
  - Proibido introduzir parâmetros inexistentes no kernel Linux (ex.: `amd_iommu=on` não existe; utilizar apenas `iommu=pt` para passthrough).
  - Proibido introduzir kargs redundantes já ativos por padrão no Fedora 44 (ex.: `CONFIG_RANDOMIZE_KSTACK_OFFSET_DEFAULT=y`, `kvm_amd.nested=1`). Sempre verificar os padrões do kernel antes de propor kargs.
  - Para a CPU AMD Ryzen 9 5950X (Zen 3, 16C/32T dual-CCD), é obrigatório fixar `tsc=reliable` (suprime o watchdog de clocksource e os falsos positivos `clocksource: Watchdog remote CPU read timed out` entre CCDs) e `nowatchdog` (desativa soft/hard lockup detectors e o NMI watchdog). Como `nowatchdog` já zera `kernel.nmi_watchdog`, é proibido redeclará-lo em `sysctl.d`. É proibido utilizar `preempt=full` (induz contenção e latência de escalonamento em 32 threads) ou `page_alloc.shuffle=1` (fragmentação de memória).
- **Arquitetura Transacional OCI / bootc:**
  - O sistema opera sob o modelo `bootc`. Atualizações automáticas de sistema são orquestradas unicamente via `bootc-fetch-apply-updates.timer` com guarda de resiliência de rede D-Bus.
  - É proibido manter ou recriar configurações legadas de staging no `/etc/rpm-ostreed.conf`.
- **Blindagem de Scripts em `/etc/profile.d/`:**
  - Scripts de perfil devem utilizar estritamente `return 0 2>/dev/null` no bypass não-interativo. É expressamente proibido usar `|| exit 0`, pois isso mata shells de login não interativos (SSH em lote, cron, automações).
- **Paridade de Navegadores Flatpak:**
  - Todo navegador Chromium-based incluído em `recipes/common-flatpaks.yml` (Brave, Google Chrome) deve ter provisionamento ativo em `70-browser-flags.conf` com flags Wayland (`--ozone-platform-hint=auto`) e aceleração GPU por hardware.
- **Aceleração de IA / ROCm via CDI:**
  - Manter a imagem base enxuta (< 4 GB). A aceleração da GPU AMD RX 6600 XT para cargas de IA locais (Ollama, PyTorch, llama.cpp) deve utilizar CDI (`--device amd.com/gpu=all` via `/etc/cdi/amdgpu.yaml`), com injeção automática de `HSA_OVERRIDE_GFX_VERSION=10.3.0`.
- **Montagens FUSE de Nuvem e Higiene de Cache (Rclone):**
  - Todo parâmetro operacional e de cache VFS (`max-size`, `max-age`, `min-free-space`, `write-back`, `dir-cache-time`, `poll-interval`) deve ser estritamente parametrizado via variáveis de ambiente no template `rclone@.service` com defaults seguros e extensível via arquivos `.env` e `.local.env`.
  - O template de serviço `rclone@.service` deve conter `TimeoutStartSec=90s` para acomodar renovação de tokens OAuth2 e handshake TLS. É proibido aplicar `network-guard` em montagens FUSE interativas de nuvem, pois o bloqueio em conexões medidas (*metered*) impede o acesso legítimo a arquivos do usuário sob tethering ou redes móveis (reservando o guard estritamente para timers de atualização em lote).
  - Garantir proteção ativa do armazenamento local através de `--vfs-cache-min-free-space` (mínimo de 15G livres resguardados) e `--vfs-cache-max-age 24h` para evitar retenção indefinida de arquivos obsoletos no SSD.
  - Proteger contra perda acidental de dados no Google Drive mantendo `RCLONE_DRIVE_USE_TRASH=true` por padrão (paridade com o cliente oficial na lixeira em nuvem).
  - Proteger contra throttling HTTP 429 no Microsoft OneDrive limitando transações (`tpslimit=5`, `chunk-size=50M` múltiplo de 320 KiB) e utilizando a Delta API com polling controlado (1m).
  - É estritamente proibido remover a exclusão imutável do indexador Baloo para `$HOME/Cloud` em `/etc/xdg/baloofilerc` (`[$ei]`).
- **Provisionamento Declarativo de Overrides Flatpak:**
  - O Flatpak monitora overrides de sistema exclusivamente em `/var/lib/flatpak/overrides/`. É expressamente proibido provisioná-los em `/etc/flatpak/overrides/` (caminho ignorado pelo Flatpak).
  - Em sistemas imutáveis/bootc, templates de override devem residir em `/usr/share/flatpak/overrides/` e ser sincronizados autoritativamente para `/var/lib/flatpak/overrides/` no boot via tmpfiles (`60-flatpak-overrides.conf`).
- **Segurança de Permissões em Caches de Usuário:**
  - Diretórios de cache de dados e sincronização em nuvem (`%h/.cache/rclone`) devem possuir estritamente permissões `0700` em todas as diretivas de tmpfiles, eliminando permissões mundiais `0755`.
- **Áudio Bluetooth (Padrão Nativo Fedora Kinoite / Avaliação A/B):**
  - O subsistema de áudio Bluetooth opera com os padrões nativos do PipeWire e WirePlumber do Fedora Kinoite 44, com políticas customizadas e quirks de Bluetooth removidos da imagem para validação empírica de compatibilidade direta.
  - Fones de ouvido TWS (True Wireless Stereo) utilizam processadores DSP independentes e controle de ganho por canal. A sincronização de hardware AVRCP (`hw-volume`) permanece nos padrões upstream. É terminantemente proibido desativar `bluez5.hw-volume` globalmente em fones TWS.
- **Higiene de Pacotes RPM na Imagem Base:**
  - É proibido instalar pacotes exclusivos de outros SO (ex.: `podman-machine` é macOS/Windows only) ou pacotes debug-only/dev-only sem utilidade funcional em produção.
  - Todo pacote incluído em `recipes/common-*.yml` deve ter justificativa funcional documentável para o perfil operacional Linux nativo.
- **Estabilidade Gráfica em Navegadores Chromium:**
  - Todo navegador Chromium-based provisionado em `70-browser-flags.conf` deve utilizar Wayland nativo (`--ozone-platform-hint=auto`), GPU rasterization e aceleração de captura via PipeWire. É terminantemente proibido introduzir flags experimentais instáveis de decodificação de vídeo (`AcceleratedVideoDecodeLinuxZeroCopyGL`, `AcceleratedVideoDecodeLinuxGL`), que causam falhas de alocação de superfície, travamentos de GPU (GPU hang) e congelamento do sistema no driver AMDGPU/Mesa.
- **Fonte Única de Verdade para Variáveis de Ambiente:**
  - Variáveis de ambiente de sessão (GPU, editor, tipografia, Wayland) devem ser definidas exclusivamente em `environment.d` (`60-kinoite-environment.conf`). É proibido redeclarar essas variáveis em scripts `profile.d`.
  - Scripts `profile.d` devem conter apenas lógica interativa condicional (inicialização de shells, detecção de binários, FZF/starship/zoxide) impossível de replicar em `environment.d`.
- **Proibição de Redeclaração de Defaults do Sistema:**
  - É proibido incluir em `sysctl.d`, `kargs`, ou qualquer arquivo de configuração parâmetros que já sejam defaults do Fedora 44, systemd, ou NetworkManager. Sempre verificar o valor efetivo via `sysctl`, `cat /proc/cmdline` ou documentação upstream antes de propor qualquer adição.
- **Segurança de Resolução de Nomes (DoT & Resiliência DNS):**
  - O resolvedor local (`systemd-resolved`) deve priorizar conexões DNS-over-TLS criptografadas (`DNSOverTLS=opportunistic`) com validação `DNSSEC=allow-downgrade` ancoradas nos servidores primários de alto desempenho da Cloudflare (`1.1.1.1` e `1.0.0.1` com SNI `cloudflare-dns.com`).
- **Prevenção de Colisão com Pacotes RPM Upstream:**
  - Configurações e regras do sistema (como regras de Polkit em `/usr/share/polkit-1/rules.d/`) devem utilizar prefixos e nomes exclusivos (ex.: `51-kinoite-libvirt.rules`). É terminantemente proibido sobrescrever arquivos pertencentes a pacotes RPM upstream (ex.: `50-libvirt.rules` de `libvirt-daemon-common`), preservando a integridade das assinaturas e validação de pacotes (`rpm -V`).
- **Isolamento de Dispositivos e Menor Privilégio em Periféricos HID:**
  - Acesso a dispositivos HID brutos (`/dev/hidraw*`) de periféricos de alta performance (headsets USB, mouses gamers, teclados mecânicos e controladoras RGB) deve ser concedido unicamente via `TAG+="uaccess"` em `70-peripherals.rules`. É estritamente proibido conceder permissões mundiais `0666` ou exigir execução com privilégios de root para controle de hardware de usuário.
- **Prevenção de Fragmentação em Armazenamento CoW (Btrfs NoCOW):**
  - Imagens de máquinas virtuais, camadas e volumes de contêineres e cache VFS de nuvem devem ter o atributo `+C` (NoCOW) provisionado preventivamente antes da gravação de dados via `tmpfiles.d` de sistema e usuário (`60-io-tuning-*.conf`), prevenindo fragmentação severa e amplificação de escrita no Btrfs. É proibido declarar caminhos NoCOW (`+C`) para diretórios não utilizados ou runtimes não homologados/inexistentes (`/var/lib/docker`, `/var/lib/distrobox`).
- **Auto-scaling de Recursos do Kernel vs Limites Manuais:**
  - Proibido introduzir limites manuais restritivos em parâmetros do kernel que realizam dimensionamento dinâmico proporcional à memória física (ex.: `fs.inotify.max_user_watches` auto-escala acima de 650.000 instâncias no kernel Linux 5.11+ com 64 GB de RAM; fixar 524.288 artificialmente limita e degrada o sistema).
- **Encaminhamento de Rede e Isolamento de Nós Clientes:**
  - Em estações de trabalho e clientes Tailscale, é expressamente proibido habilitar `net.ipv4.ip_forward` ou `net.ipv6.conf.all.forwarding` globalmente via `sysctl.d`. O encaminhamento IP deve ser ativado exclusivamente sob demanda pelos daemons de contêineres e virtualização (Netavark/Podman, Libvirt) nas pontes virtuais designadas, prevenindo a quebra de SLAAC (RFC 4862) e a exposição indevida do host como gateway de trânsito.
- **Blacklist CIS e Higiene de Módulos do Kernel:**
  - A desativação de protocolos de rede e sistemas de arquivos vulneráveis ou legados (`sctp`, `tipc`, `jffs2`, `hfs`, `hfsplus`, `firewire-core`) deve utilizar estritamente a diretiva `install <modulo> /bin/false` (CIS Benchmark) para retornar erro explícito caso invocada. É expressamente proibido incluir módulos já expurgados ou inexistentes no kernel ativo (ex.: `dccp`, `cramfs`, `freevxfs` no Linux 7.2) ou que já possuam regras nativas upstream (ex.: `rds`).
- **Semântica e Higiene de Timers do Systemd:**
  - Timers monotônicos baseados em tempo de boot ou inatividade (`OnBootSec=`, `OnUnitActiveSec=`) não devem declarar `Persistent=true` (diretiva funcional exclusivamente em timers calendáricos com `OnCalendar=`). Timers não devem redeclarar `Unit=` quando acionam o serviço homônimo padrão, nem definir `RandomizedDelaySec=0` quando já for o padrão nativo da distribuição.
- **Atomicidade e Idempotência em Diretivas Tmpfiles:**
  - Diretivas do tipo `C+` (cópia/substituição atômica no systemd 255+) sobrescrevem o destino de forma segura e atômica; é expressamente proibido adicionar diretivas `r!` precedentes redundantes.
- **Resiliência a Kernel Oops e Prevenção de Corrupção Btrfs:**
  - Em estações de trabalho de desenvolvimento, falhas graves no kernel com interrupções desabilitadas induzem congelamento irreversível (*hard lockup*). É obrigatório fixar `kernel.panic = 10` e `kernel.panic_on_oops = 1` em `90-kernel-tuning.conf` para forçar auto-reboot limpo após 10 segundos em vez de deixar a máquina em estado zumbi congelado.
  - Para permitir recuperação de emergência sem corte abrupto de energia, é obrigatório ativar `kernel.sysrq = 1`, viabilizando o procedimento de emergência REISUB (`Alt+SysRq+R-E-I-S-U-B`) para descarregar buffers em disco e proteger a integridade dos metadados Btrfs no NVMe.
- **Calibração de BIOS e Estabilidade de Plataforma AMD Zen 3 (5950X / X570 / 4-DIMM):**
  - O perfil padrão homologado opera com `Extreme Memory Profile (X.M.P.) = Profile1` (DDR4-3200) sob estrita sincronia FCLK:UCLK:MEMCLK 1:1 (`1600 MHz`), suprimindo quebras para 2:1 que degradam a latência em ~10 ns.
  - A topologia daisy-chain exige módulos dual-rank nas terminações físicas (slots A2/B2) e single-rank nos stubs (A1/B1); qualquer alteração de hardware deve respeitar essa terminação.
  - O perfil estável com XMP exige sub-tensões manuais fixadas (DRAM 1.350V, VSOC 1.100V com teto de 1.150V, VDDG IOD 1.000V, VDDG CCD 0.950V, cLDO VDDP 0.900V) para prevenir sobretensões do modo Auto, além de impedâncias terminadas para 3 ranks/canal (ProcODT 40.0 Ω, RttWr 80 Ω, RttPark 48 Ω, CAD_BUS 24 Ω).
  - Invariantes de proteção térmica e retenção capacitiva sob XMP com 4 DIMMs contíguos:
    - DRAM Voltage fixado com teto estrito de `1.350 V` (admitindo undervolt validado em `1.300 V`–`1.320 V`) para conter a dissipação jouleiana ($P \propto V^2$).
    - CPU VCORE SOC limitado estritamente a `1.100 V` manual (jamais `Auto`), impedindo que a placa-mãe injete 1.20V–1.25V no I/O Die (SoC), o que transfere carga térmica severa diretamente ao plano de cobre do soquete AM4 adjacente aos slots A1 e A2.
    - Manutenção estrita de `tRFC` e `tREFI` em `Auto`: preservar os ciclos de recarga capacitiva é mandatório para evitar bit-flips silenciosos induzidos por elevação de temperatura nos chips DRAM de 8 Gb.
    - Habilitação obrigatória de `Auto Self Refresh (ASR)` / `Extended Temperature Range` nas opções de CBS do IMC para dobrar dinamicamente a cadência de refresh quando a temperatura operacional se aproximar do limiar crítico de 85 °C.
    - Garantia de fluxo de ar ativo no gabinete sobre os quatro módulos DIMM para mitigar o acúmulo térmico entre os slots contíguos.
  - É proibido aplicar offsets de Curve Optimizer negativos nos núcleos com classificação de silício máxima (`highest_perf` do CPPC, como Cores 0 e 3), evitando *light workload kernel oopses*.
  - É obrigatório manter `Power Supply Idle Control = Typical Current Idle` (evita C6 idle voltage sag), `CPPC` + `CPPC Preferred Cores = Enabled` (requisito de publicação ACPI `_CPC` para o driver `amd-pstate-epp`), `CSM = Disabled`, `Above 4G Decoding` e `Re-Size BAR = Enabled` (SAM ativo com BAR de 8192 MB na GPU Navi 23), e `TSME = Disabled` (elimina penalidade de encriptação em DRAM).

## 6. Práticas de Segurança e Governança de Instruções (`AGENTS.md`)

- **Fonte Canônica Única (Single Source of Truth):**
  - A fonte canônica, exclusiva e auto-suficiente de regras do projeto reside em `AGENTS.md`. Diretórios redundantes de skills (como `.agents/`) e links simbólicos (como `agent.md`) são eliminados para manter o repositório 100% DRY, enxuto e livre de duplicatas.
- **Segregação de Segredos:**
  - Arquivos de regras (`AGENTS.md`) são versionados no Git e NUNCA devem conter chaves privadas, senhas, tokens de API ou credenciais pessoais.
  - Configurações locais privadas de agentes devem residir em arquivos ignorados pelo Git (ex.: `*.local.md`).
- **Defesa contra Prompt Injection:**
  - Arquivos de instrução de agentes têm efeito direto na geração de código e execução de comandos. Qualquer alteração em `AGENTS.md` deve ser tratada e revisada com o mesmo rigor de segurança de código de infraestrutura.

## 7. CI/CD, GitHub Actions e Proteção de Supply Chain

- **Gatilho de Build por Digest:**
  - O workflow `check-updates.yml` executa a cada 2 horas (`0 */2 * * *`) e dispara o build apenas quando o digest upstream muda, usando cache de Actions para evitar rebuilds redundantes. É proibido alterar esta cadência sem justificativa de cota.
  - O cache de digest upstream opera de forma desacoplada: `check-updates.yml` atua estritamente em modo de leitura (`actions/cache/restore`) e verifica se já existem execuções ativas (`in_progress` ou `queued`) antes de disparar; a gravação do cache (`actions/cache/save`) ocorre exclusivamente após a conclusão com sucesso do build em `build-amd.yml`, garantindo que falhas de compilação ou rede sejam retentadas automaticamente na checagem seguinte.
- **Concorrência, Timeouts e Proteção de Quota Free:**
  - Todo workflow deve declarar `concurrency` com `cancel-in-progress: true` para evitar execuções paralelas que desperdicem minutos de CI.
  - É obrigatório declarar `timeout-minutes` restritivo em 100% dos jobs (máximo de 5m para checagens de atualização, 10m para rotinas de limpeza e 45m para build de imagem OCI), eliminando o risco de jobs zumbis consumirem cotas da conta gratuita do GitHub.
- **Pinagem de Actions e Higiene do Dependabot:**
  - Todas as GitHub Actions de terceiros devem ser pinadas por hash SHA completo (não por tag mutável) para proteção contra supply chain attacks.
  - O Dependabot deve operar em cadência semanal (`weekly`, segundas-feiras) com agrupamento unificado (`groups: github-actions`) e prefixo Conventional Commits (`chore(deps)`), limitando-se a no máximo 3 PRs abertos simultaneamente para manter a aba de Pull Requests limpa e evitar dispersão de testes de CI.
- **Retenção, Limpeza e Caches Órfãos:**
  - O workflow `cleanup.yml` executa diariamente, retendo 15 versões de pacote no GHCR (calibrado para preservar 3 imagens completas de contêiner: a imagem ativa e 2 versões de rollback, considerando ~4 artefatos OCI por build entre índices, manifestos de arquitetura, atestações e assinaturas Cosign), 3 dias de execuções de workflows (mínimo de 3 runs preservadas) e realizando expurgo proativo de caches de Actions obsoletos (`gh cache delete`). É proibido desativar a limpeza automática ou manter retenção excessiva.
- **Segurança de Shell e Menor Privilégio:**
  - Cada workflow deve declarar explicitamente o conjunto mínimo de `permissions` necessário (ex.: `contents: read`, `packages: write`, `actions: write`). É terminantemente proibido utilizar `permissions: write-all`.
  - Parâmetros e contextos dinâmicos do GitHub Actions (`${{ ... }}`) nunca devem ser concatenados diretamente no corpo de scripts shell executáveis (`run: |`); devem ser sanitizados e injetados estritamente via variáveis de ambiente no bloco `env:` para prevenção contra command injection.
- **Contrato de Schemas e Preservação de Inputs Obrigatórios:**
  - Parâmetros declarados como obrigatórios (`required: true`) nos manifestos `action.yml` de GitHub Actions (ex.: `pr_event_number` em `blue-build/github-action`) devem ser mantidos explicitamente declarados no bloco `with:` mesmo em disparos manuais (`workflow_dispatch`) onde seu valor avalia como nulo, garantindo conformidade com o validador de schema.

## 8. Rastreabilidade: Invariantes → Implementação

| Invariante | Arquivo(s) de Implementação |
| :--------- | :-------------------------- |
| Validação de Kernel Arguments | [`recipes/common-kargs.yml`](recipes/common-kargs.yml) |
| Arquitetura Transacional bootc | [`files/system/usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/override.conf`](files/system/usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/override.conf) |
| Blindagem profile.d | [`files/system/etc/profile.d/50-shell-env-overrides.sh`](files/system/etc/profile.d/50-shell-env-overrides.sh), [`files/system/etc/profile.d/60-kinoite-aliases.sh`](files/system/etc/profile.d/60-kinoite-aliases.sh) |
| Paridade de Navegadores Flatpak | [`files/system/usr/share/browser-configs/chromium-flags.conf`](files/system/usr/share/browser-configs/chromium-flags.conf), [`files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf`](files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf) |
| Aceleração IA / ROCm via CDI | [`files/system/etc/cdi/amdgpu.yaml`](files/system/etc/cdi/amdgpu.yaml) |
| Montagens FUSE Rclone | [`files/system/usr/lib/systemd/user/rclone@.service`](files/system/usr/lib/systemd/user/rclone@.service), [`files/system/usr/share/rclone/env/*.env`](files/system/usr/share/rclone/env/) |
| Overrides Flatpak Declarativos | [`files/system/usr/share/flatpak/overrides/*`](files/system/usr/share/flatpak/overrides/), [`files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`](files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf) |
| Cache Permissions 0700 | [`files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`](files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf) |
| Áudio Bluetooth | Padrão nativo Fedora Kinoite / WirePlumber upstream |
| Headset MCHOSE X9 | [`files/system/usr/share/wireplumber/wireplumber.conf.d/51-mchose-x9.conf`](files/system/usr/share/wireplumber/wireplumber.conf.d/51-mchose-x9.conf) |
| Higiene de Pacotes | [`recipes/common-tools.yml`](recipes/common-tools.yml), [`recipes/common-drivers.yml`](recipes/common-drivers.yml), [`recipes/common-fonts.yml`](recipes/common-fonts.yml) |
| Aceleração de Vídeo Browsers | [`files/system/usr/share/browser-configs/chromium-flags.conf`](files/system/usr/share/browser-configs/chromium-flags.conf) |
| Fonte Única Env Vars | [`files/system/usr/lib/environment.d/60-kinoite-environment.conf`](files/system/usr/lib/environment.d/60-kinoite-environment.conf) |
| Proibição Redeclaração Defaults | [`files/system/usr/lib/sysctl.d/90-*.conf`](files/system/usr/lib/sysctl.d/) |
| CI/CD Proteção | [`.github/workflows/*.yml`](.github/workflows/), [`.github/dependabot.yml`](.github/dependabot.yml) |
| Resiliência DNS e DoT | [`files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`](files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf) |
| Menor Privilégio Periféricos HID | [`files/system/usr/lib/udev/rules.d/70-peripherals.rules`](files/system/usr/lib/udev/rules.d/70-peripherals.rules) |
| Btrfs NoCOW Storage | [`files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`](files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf), [`files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`](files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf) |
| Hardening SSHD e Blacklist Kernel | [`files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`](files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf), [`files/system/usr/lib/modprobe.d/60-security-blacklist.conf`](files/system/usr/lib/modprobe.d/60-security-blacklist.conf) |
| ZRAM Swap Policy | [`files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`](files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf) |
| Compatibilidade CLI Docker | [`files/system/etc/containers/nodocker`](files/system/etc/containers/nodocker) |
| Guarda de Resiliência de Rede | [`files/system/usr/libexec/kinoite/network-guard`](files/system/usr/libexec/kinoite/network-guard) |
| Menor Privilégio Libvirt Polkit | [`files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`](files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules) |
| Configurações Plasma KDE | [`files/system/etc/xdg/*`](files/system/etc/xdg/) |
| Resiliência a Kernel Oops e SysRq | [`files/system/usr/lib/sysctl.d/90-kernel-tuning.conf`](files/system/usr/lib/sysctl.d/90-kernel-tuning.conf) |
| Diagnóstico de Hardware e RAS | [`recipes/common-tools.yml`](recipes/common-tools.yml), [`recipes/common-systemd.yml`](recipes/common-systemd.yml) |
| Calibração de BIOS e Estabilidade de Memória | [`docs/POST_INSTALL.md` §14](docs/POST_INSTALL.md), [`docs/TECHNICAL_ARCHITECTURE.md` §2.1, §5.7](docs/TECHNICAL_ARCHITECTURE.md) |
