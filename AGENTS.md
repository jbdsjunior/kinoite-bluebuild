# Diretrizes Operacionais do Agente (AGENTS.md)

Este arquivo contém apenas as invariantes críticas sempre ativas para minimizar o consumo de tokens em cada rodada de auditoria e edição.
O catálogo linear completo de frases simples descrevendo cada arquivo do projeto está em `docs/DIRECTIVES.md`.

## Arquitetura Essencial e Papel das GPUs

- O projeto constrói imagens imutáveis Fedora Kinoite via BlueBuild, Bootc e OSTree nas variantes `kinoite-amd` (100% AMD) e `kinoite-dual` (display AMD + computação NVIDIA).
- A árvore `/usr/lib/` e `/usr/share/` concentra as configurações do sistema para manter o `/etc/` limpo e seguir a regra de zero duplicação.
- A GPU primária AMD Radeon RX 6600 XT (`0000:0c:00.0`) é dedicada exclusivamente ao display Wayland, KDE Plasma, aceleração Vulkan/VA-API e máquinas virtuais.
- A GPU secundária NVIDIA GeForce RTX 3080 Ti (`0000:09:00.0`) opera estritamente headless na imagem `kinoite-dual` apenas para IA e CUDA, sem render nodes DRM.
- Os guias operacionais e diretrizes (`AGENTS.md`, `docs/DIRECTIVES.md` e `docs/POST_INSTALL.md`) utilizam português do Brasil e `README.md`, `SECURITY.md`, código, scripts e mensagens de sistema utilizam inglês.

## Invariantes de Engenharia e Regras Proibidas

- É terminantemente proibido adicionar `nvidia-drm.modeset=1` ou permitir a criação de render nodes DRM na GPU secundária NVIDIA.
- É proibido incluir qualquer arquivo, driver ou módulo da NVIDIA na imagem `kinoite-amd`.
- É proibido desativar a autenticação obrigatória de root (`sulogin`) em consoles de recuperação ou emergência.
- É proibido adicionar kargs redundantes ou obsoletos como `preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt` ou `amd_pstate=active`.
- É proibido colocar arquivos de configuração de sistema em `/etc/` quando o subsistema suportar diretórios em `/usr/lib/` ou `/usr/share/`.
- É proibido realizar downgrade de pacotes base do Fedora ou reintroduzir scripts imperativos (`type: script`) nas receitas quando houver solução declarativa.

## Critérios para Adição de Novos Softwares

- Aplicativos com interface gráfica devem ser instalados exclusivamente via Flatpak em `recipes/common-flatpaks.yml`.
- Linguagens de programação, SDKs e ambientes de desenvolvimento devem rodar isolados em contêineres Distrobox ou Podman.
- A imagem base OSTree recebe apenas drivers de hardware, virtualização, serviços de infraestrutura e utilitários CLI essenciais.
- Configurações de aplicativos de usuário devem ser aplicadas via `user-tmpfiles.d` usando templates armazenados em `/usr/share/`.

## Validação Obrigatória Pré-Commit e Boas Práticas de Git

- Todo script shell alterado deve passar na verificação de sintaxe `bash -n` sem erros.
- Todos os arquivos YAML de receitas e workflows devem ser validados com um parser YAML estrito antes do commit.
- Arquivos TOML de kargs e arquivos `.conf` do systemd/sysctl devem ser validados quanto à sintaxe antes do commit.
- Qualquer alteração nas regras do sistema deve ser validada executando `kinoite-optimize --audit` com aprovação nos 6 pilares.
- Sempre que adicionar, remover ou alterar a função de um arquivo do repositório, sincronize a frase correspondente em `docs/DIRECTIVES.md`.
- Os commits devem seguir o padrão Conventional Commits (`feat`, `fix`, `refactor`, `docs`, `ci`, `chore`) com `git add <arquivo>` individual e inspeção de `git diff --cached`.

## Índice de Leitura Cirúrgica (`docs/DIRECTIVES.md`)

- Nunca leia `docs/DIRECTIVES.md` inteiro sem necessidade; consulte apenas o intervalo de linhas da categoria pertinente com `read_file` (`StartLine`/`EndLine`) ou `grep`.
- Arquitetura, organização do repositório, hardware/GPUs e flavors: linhas 6 a 42 de `docs/DIRECTIVES.md`.
- Receitas BlueBuild, kargs e isolamento NVIDIA: linhas 44 a 71 de `docs/DIRECTIVES.md`.
- Armazenamento Btrfs NoCOW, ZRAM, limites de memória, segurança, rede e DNS: linhas 73 a 101 de `docs/DIRECTIVES.md`.
- Timers systemd de atualização/manutenção, desktop KDE e navegadores: linhas 103 a 140 de `docs/DIRECTIVES.md`.
- Aceleração de IA/CDI, periféricos, Rclone, utilitários locais e CI/CD: linhas 142 a 168 de `docs/DIRECTIVES.md`.
- Invariantes de engenharia, regras proibidas, adição de software e validação pré-commit: linhas 170 a 192 de `docs/DIRECTIVES.md`.
