# Diretrizes do Sistema Multiagente (`AGENTS.md`)

Este arquivo define as regras permanentes de arquitetura, princípios de execução, baseline de hardware e invariantes de engenharia para todos os agentes que operam no repositório `kinoite-bluebuild`.

## 1. Diretriz Obrigatória de Versionamento Git

- **Skill Obrigatória Ativa:** A skill [`git-workflow`](.agents/skills/git-workflow/SKILL.md) está permanentemente ativa para o projeto.
- **Commit Obrigatório em Modificações:** Toda e qualquer tarefa que altere, adicione ou remova arquivos no repositório DEVE ser finalizada com a execução de commit Git estruturado antes de considerar a tarefa concluída.
- **Padrão de Mensagem (Conventional Commits):**
  - Todo commit deve possuir mensagem clara no formato `<type>(<scope>): <descrição>` com detalhamento em tópicos (bullet points) das decisões técnicas e arquivos impactados.
  - Tipos válidos: `feat`, `fix`, `docs`, `refactor`, `chore`.
- **Árvore de Trabalho Limpa:** Nunca encerre uma interação deixando alterações pendentes ou `working tree dirty`.

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

- **Processador & Gráficos:** AMD Ryzen 9 5950X (16C/32T, Zen 3), AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23 / RDNA2).
- **Memória & Armazenamento:** 64GB RAM DDR4, 1TB NVMe PCIe Gen4 (Btrfs).
- **Sistema Operacional:** Fedora Kinoite 44 (imutável, Wayland nativo, modelo `bootc`, KDE Plasma 6).
- **Workloads do Usuário:** DevSecOps, desenvolvimento de software, inferência local de LLMs (ROCm/HIP via CDI em contêineres), navegação intensiva, virtualização KVM.
- **Periféricos Homologados:**
  - **Headset USB:** MCHOSE X9 (ALSA quirks em `51-mchose-x9.conf`).
  - **Fones Bluetooth TWS:** Baseus Bass EP10 Pro (LDAC/AAC/SBC, Bluetooth 5.4, Hi-Res Audio Wireless).
  - **Periféricos HID:** VXE Mouse, BY Tech (udev uaccess em `70-peripherals.rules`).

## 4. Restrições do Projeto

- **Sem Redundâncias de SO:** Não incluir ajustes ou configurações redundantes já presentes por padrão no Linux/Fedora Kinoite 44.
- **Automação de Atualizações:** Timers de atualização (`bootc`, Flatpak do sistema e usuário, Podman, soar) iniciam exatamente 5 minutos após o boot (`OnBootSec=5m`) e repetem a cada 45 minutos (`OnUnitActiveSec=45m`). Devem possuir guarda de resiliência de rede obrigatória via script executável centralizado `/usr/libexec/kinoite/network-guard` (`ExecCondition`), inspecionando o `NetworkManager` via D-Bus para abortar sem erro em conexões limitadas/offline.
- **Checagem de Atualização Upstream:** Executada via GitHub Actions (`check-updates.yml`) a cada 2 horas (`0 */2 * * *`) de forma otimizada para cotas de CI.
- **Qualidade Visual:** Garantir qualidade mínima equivalente ou superior a sistemas modernos (estilo macOS), com foco em terminal, Konsole e tipografia.
- **Referência Técnica:** Soluções e melhorias podem utilizar como base referências comprovadas do projeto Bazzite Linux.
- **Eliminação de Instabilidade:** Configurações incorretas, instáveis ou irrelevantes devem ser removidas proativamente. Manter opções secundárias comentadas apenas quando pertinente.

## 5. Invariantes e Regras de Engenharia do Sistema

- **Validação de Kernel Arguments:**
  - Proibido introduzir parâmetros inexistentes no kernel Linux (ex.: `amd_iommu=on` não existe; utilizar apenas `iommu=pt` para passthrough).
  - Proibido introduzir kargs redundantes já ativos por padrão no Fedora 44 (ex.: `CONFIG_RANDOMIZE_KSTACK_OFFSET_DEFAULT=y`, `kvm_amd.nested=1`). Sempre verificar os padrões do kernel antes de propor kargs.
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
  - Garantir proteção ativa do armazenamento local através de `--vfs-cache-min-free-space` (mínimo de 15G livres resguardados) e `--vfs-cache-max-age 24h` para evitar retenção indefinida de arquivos obsoletos no SSD.
  - Proteger contra perda acidental de dados no Google Drive mantendo `RCLONE_DRIVE_USE_TRASH=true` por padrão (paridade com o cliente oficial na lixeira em nuvem).
  - Proteger contra throttling HTTP 429 no Microsoft OneDrive limitando transações (`tpslimit=5`, `chunk-size=50M` múltiplo de 320 KiB) e utilizando a Delta API com polling controlado (1m).
  - É estritamente proibido remover a exclusão imutável do indexador Baloo para `$HOME/Cloud` em `/etc/xdg/baloofilerc` (`[$ei]`).
- **Provisionamento Declarativo de Overrides Flatpak:**
  - O Flatpak monitora overrides de sistema exclusivamente em `/var/lib/flatpak/overrides/`. É expressamente proibido provisioná-los em `/etc/flatpak/overrides/` (caminho ignorado pelo Flatpak).
  - Em sistemas imutáveis/bootc, templates de override devem residir em `/usr/share/flatpak/overrides/` e ser sincronizados autoritativamente para `/var/lib/flatpak/overrides/` no boot via tmpfiles (`60-flatpak-overrides.conf`).
- **Segurança de Permissões em Caches de Usuário:**
  - Diretórios de cache de dados e sincronização em nuvem (`%h/.cache/rclone`) devem possuir estritamente permissões `0700` em todas as diretivas de tmpfiles, eliminando permissões mundiais `0755`.
- **Calibração e Quirks de Áudio Bluetooth (WirePlumber 0.5):**
  - O subsistema de áudio deve priorizar permanentemente a **máxima fidelidade e estabilidade sonora**, provisionando a hierarquia estrita de codecs (`LDAC > AAC > SBC-XQ > SBC`) com taxa de bits adaptativa (`bluez5.a2dp.ldac.quality = "auto"`) para garantir até 990 kbps (24-bit/96kHz) sem perda de pacotes ou engasgos.
  - Fones de ouvido TWS (True Wireless Stereo) utilizam processadores DSP independentes e controle de ganho por canal. A sincronização de hardware AVRCP (`hw-volume`) é obrigatória para manter a calibração de ganho analógico idêntica em ambos os lados e prevenir o bombeamento assimétrico do limitador dinâmico (DRC/AGC) entre os canais esquerdo e direito. É terminantemente proibido desativar `bluez5.hw-volume` em fones TWS.
  - Para evitar degradação involuntária da saída estéreo de alta fidelidade (A2DP LDAC/AAC/SBC-XQ) para perfis mono de chamada (HSP/HFP) por sondagem de microfones em navegadores ou aplicações, a política declarativa do WirePlumber deve fixar `bluetooth.autoswitch-to-headset-profile = false`.
- **Higiene de Pacotes RPM na Imagem Base:**
  - É proibido instalar pacotes exclusivos de outros SO (ex.: `podman-machine` é macOS/Windows only) ou pacotes debug-only/dev-only sem utilidade funcional em produção.
  - Todo pacote incluído em `recipes/common-*.yml` deve ter justificativa funcional documentável para o perfil operacional Linux nativo.
- **Aceleração de Vídeo por Hardware em Navegadores Chromium:**
  - Todo navegador Chromium-based provisionado em `70-browser-flags.conf` deve incluir, além de Wayland (`--ozone-platform-hint=auto`) e GPU rasterization, flags de aceleração de vídeo por hardware (`AcceleratedVideoDecodeLinuxGL`, `AcceleratedVideoDecodeLinuxZeroCopyGL`, `AcceleratedVideoEncoder`) para explorar VA-API zero-copy GL com a GPU AMD.
- **Fonte Única de Verdade para Variáveis de Ambiente:**
  - Variáveis de ambiente de sessão (GPU, editor, tipografia, Wayland) devem ser definidas exclusivamente em `environment.d` (`60-kinoite-environment.conf`). É proibido redeclarar essas variáveis em scripts `profile.d`.
  - Scripts `profile.d` devem conter apenas lógica interativa condicional (inicialização de shells, detecção de binários, FZF/starship/zoxide) impossível de replicar em `environment.d`.
- **Proibição de Redeclaração de Defaults do Sistema:**
  - É proibido incluir em `sysctl.d`, `kargs`, ou qualquer arquivo de configuração parâmetros que já sejam defaults do Fedora 44, systemd, ou NetworkManager. Sempre verificar o valor efetivo via `sysctl`, `cat /proc/cmdline` ou documentação upstream antes de propor qualquer adição.
- **Segurança de Resolução de Nomes (DoT & Fallback Resiliente):**
  - O resolvedor local (`systemd-resolved`) deve priorizar conexões DNS-over-TLS criptografadas com `DNSSEC=allow-downgrade`. É obrigatório manter `FallbackDNS` ativo e configurado com múltiplos servidores DoT de alta disponibilidade do Quad9 (`dns.quad9.net` com bloqueio de malware e suporte a DNSSEC) para prevenir indisponibilidade ou rebaixamento para texto plano desprotegido.
- **Prevenção de Colisão com Pacotes RPM Upstream:**
  - Configurações e regras do sistema (como regras de Polkit em `/usr/share/polkit-1/rules.d/`) devem utilizar prefixos e nomes exclusivos (ex.: `51-kinoite-libvirt.rules`). É terminantemente proibido sobrescrever arquivos pertencentes a pacotes RPM upstream (ex.: `50-libvirt.rules` de `libvirt-daemon-common`), preservando a integridade das assinaturas e validação de pacotes (`rpm -V`).
- **Isolamento de Dispositivos e Menor Privilégio em Periféricos HID:**
  - Acesso a dispositivos HID brutos (`/dev/hidraw*`) de periféricos de alta performance (headsets USB, mouses gamers, teclados mecânicos e controladoras RGB) deve ser concedido unicamente via `TAG+="uaccess"` em `70-peripherals.rules`. É estritamente proibido conceder permissões mundiais `0666` ou exigir execução com privilégios de root para controle de hardware de usuário.
- **Prevenção de Fragmentação em Armazenamento CoW (Btrfs NoCOW):**
  - Imagens de máquinas virtuais, camadas e volumes de contêineres, cache VFS de nuvem e modelos de inteligência artificial de grande porte (Ollama, HuggingFace) devem ter o atributo `+C` (NoCOW) provisionado preventivamente antes da gravação de dados via `tmpfiles.d` de sistema e usuário (`60-io-tuning-*.conf`), prevenindo fragmentação severa e amplificação de escrita no Btrfs.

## 6. Práticas de Segurança para Arquivos de Agentes (`.agents/`, `AGENTS.md`)

- **Segregação de Segredos:**
  - Arquivos de regras (`AGENTS.md`) e skills (`.agents/skills/*`) são versionados no Git e NUNCA devem conter chaves privadas, senhas, tokens de API ou credenciais pessoais.
  - Configurações locais privadas de agentes devem residir em arquivos ignorados pelo Git (ex.: `.agents/local/`, `*.local.md`).
- **Defesa contra Prompt Injection:**
  - Arquivos de instrução de agentes têm efeito direto na geração de código e execução de comandos. Qualquer alteração em `AGENTS.md` ou `.agents/` deve ser tratada e revisada com o mesmo rigor de segurança de código de infraestrutura.
- **Integridade da Estrutura:**
  - A fonte canônica e exclusiva de regras do projeto reside em `AGENTS.md`. Links simbólicos redundantes (como `agent.md`) são eliminados para manter o repositório enxuto e livre de duplicatas.

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
  - O workflow `cleanup.yml` executa diariamente, retendo no máximo 3 versões de imagens de contêiner no GHCR (a imagem ativa e até 2 versões de rollback), 3 dias de execuções de workflows (mínimo de 3 runs preservadas) e realizando expurgo proativo de caches de Actions obsoletos (`gh cache delete`). É proibido desativar a limpeza automática ou manter retenção excessiva.
- **Segurança de Shell e Menor Privilégio:**
  - Cada workflow deve declarar explicitamente o conjunto mínimo de `permissions` necessário (ex.: `contents: read`, `packages: write`, `actions: write`). É terminantemente proibido utilizar `permissions: write-all`.
  - Parâmetros e contextos dinâmicos do GitHub Actions (`${{ ... }}`) nunca devem ser concatenados diretamente no corpo de scripts shell executáveis (`run: |`); devem ser sanitizados e injetados estritamente via variáveis de ambiente no bloco `env:` para prevenção contra command injection.

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
| Áudio Bluetooth TWS | [`files/system/usr/share/wireplumber/wireplumber.conf.d/80-bluetooth-policy.conf`](files/system/usr/share/wireplumber/wireplumber.conf.d/80-bluetooth-policy.conf) |
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
