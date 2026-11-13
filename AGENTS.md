# Diretrizes Operacionais do Agente

## Governança dos Arquivos de Diretrizes

- `AGENTS.md` governa exclusivamente processo, Git, validações e índice de consulta.
- `PROJECTS.md` governa exclusivamente arquitetura, hardware, arquivos e invariantes do sistema.
- Documentos externos (`README.md`, `SECURITY.md`, `docs/POST_INSTALL.md`) são derivados de `PROJECTS.md` e devem permanecer sincronizados.
- As diretrizes devem usar frases curtas, lineares e agrupadas por categorias temáticas sem numeração, tabelas ou diagramas.

## Fluxo de Trabalho e Comunicação

- Responda em português do Brasil usando links clicáveis com esquema `file://`.
- Verifique `git status -s` antes de iniciar modificações no repositório.
- Sincronize `PROJECTS.md` imediatamente sempre que criar, remover, renomear ou alterar o papel de um arquivo.
- Consulte `PROJECTS.md` apenas sob demanda localizando a seção `##` necessária antes de ler o trecho.

## Práticas de Git

- Use Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `ci:`, `chore:`).
- Nunca use `git commit -a`; adicione cada arquivo individualmente com `git add <arquivo>`.
- Revise `git diff --cached` antes do commit e faça `git push` apenas após aprovação de todas as validações.

## Validação Pré-Commit

- Valide todos os scripts `.sh` e executáveis em `files/system/usr/bin/` com `bash -n`.
- Valide a sintaxe de todos os arquivos YAML (`recipes/`, `.github/`, `amdgpu.yaml`), TOML, XML e units systemd.
- Execute `./files/system/usr/bin/kinoite-optimize --audit` com aprovação integral após mudanças de sistema.
- Confirme cobertura de 100% dos arquivos do repositório em `PROJECTS.md`.

## Categorias de Consulta em `PROJECTS.md`

- `## Arquitetura Geral e Hardware`
- `## Estrutura do Repositório e Documentação`
- `## Receitas BlueBuild`
- `## Kernel Arguments e Isolamento NVIDIA`
- `## Armazenamento, ZRAM, Memória e Segurança`
- `## Serviços, Timers e Manutenção`
- `## Desktop KDE, Navegadores e Terminal`
- `## IA, CDI, Periféricos, Virtualização e Nuvem`
- `## CI/CD e Assinatura`
- `## Invariantes e Critérios de Software`
