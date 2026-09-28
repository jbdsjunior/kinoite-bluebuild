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

- **Processador & Gráficos:** AMD Ryzen 9 5950X, AMD Radeon RX 6600 XT.
- **Memória & Armazenamento:** 64GB RAM DDR4, 1TB NVMe.
- **Sistema Operacional:** Fedora Kinoite 44 (imutável, Wayland nativo, modelo `bootc`).
- **Workloads do Usuário:** DevSecOps, desenvolvimento de software, inferência local de LLMs (ROCm/HIP via CDI em contêineres), navegação intensiva.

## 4. Restrições do Projeto

- **Sem Redundâncias de SO:** Não incluir ajustes ou configurações redundantes já presentes por padrão no Linux/Fedora Kinoite 44.
- **Automação de Atualizações:** Timers de atualização (`bootc`, Flatpak do sistema e usuário, Podman, soar) iniciam exatamente 5 minutos após o boot (`OnBootSec=5m`) e repetem a cada 45 minutos (`OnUnitActiveSec=45m`). Devem possuir guarda de resiliência de rede obrigatória via `busctl`/`NetworkManager` para abortar sem erro em conexões limitadas/offline.
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

## 6. Práticas de Segurança para Arquivos de Agentes (`.agents/`, `AGENTS.md`)

- **Segregação de Segredos:**
  - Arquivos de regras (`AGENTS.md`) e skills (`.agents/skills/*`) são versionados no Git e NUNCA devem conter chaves privadas, senhas, tokens de API ou credenciais pessoais.
  - Configurações locais privadas de agentes devem residir em arquivos ignorados pelo Git (ex.: `.agents/local/`, `*.local.md`).
- **Defesa contra Prompt Injection:**
  - Arquivos de instrução de agentes têm efeito direto na geração de código e execução de comandos. Qualquer alteração em `AGENTS.md` ou `.agents/` deve ser tratada e revisada com o mesmo rigor de segurança de código de infraestrutura.
- **Integridade da Estrutura:**
  - Manter `agent.md` como link simbólico para `AGENTS.md` para assegurar que ferramentas legadas e agentes modernos leiam exatamente a mesma fonte de verdade sem redundâncias.
