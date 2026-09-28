# Project Agent Guidelines (`AGENTS.md`)

Este arquivo define as regras e diretrizes permanentes para todos os agentes que operam no repositório `kinoite-bluebuild`.

## 1. Diretriz Obrigatória de Versionamento Git

- **Skill Obrigatória Ativa:** A skill [`git-workflow`](.agents/skills/git-workflow/SKILL.md) está permanentemente ativa para o projeto.
- **Commit Obrigatório em Modificações:** Toda e qualquer tarefa que altere, adicione ou remova arquivos no repositório DEVE ser finalizada com a execução de commit Git estruturado antes de considerar a tarefa concluída.
- **Padrão de Mensagem (Conventional Commits):**
  - Todo commit deve possuir mensagem clara no formato `<type>(<scope>): <descrição>` com detalhamento em tópicos (bullet points) das decisões técnicas e arquivos impactados.
  - Tipos válidos: `feat`, `fix`, `docs`, `refactor`, `chore`.
- **Árvore de Trabalho Limpa:** Nunca encerre uma interação deixando alterações pendentes ou `working tree dirty`.

## 2. Princípios de Engenharia e Regras de Execução

- Consulte [`agent.md`](agent.md) para as regras de execução, restrições do hardware baseline (Ryzen 9 5950X, RX 6600 XT, Fedora Kinoite 44 imutável) e as Invariantes do Sistema.
- **Segurança > Performance > Conveniência:** Elimine permissões excessivas, valide parâmetros de kernel e garanta a integridade das esteiras transacionais `bootc`.
