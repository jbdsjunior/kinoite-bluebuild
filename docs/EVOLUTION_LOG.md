# Evolution Log (`/evolve`)

Registro curto de ciclos de evolução aplicados no repositório, com foco em rastreabilidade.

## 2026-04-29 — Alinhamento de governança de instruções (`/evolve`)

### Detectar / Diagnosticar
- Detectada inconsistência entre a documentação de governança (`AGENTS.md`) e a estrutura real do repositório: apenas `/.agent/agent.md` existe.
- Risco identificado: agentes externos podem tentar carregar arquivos `/.agents/*` inexistentes e perder diretrizes críticas.

### Propor / Aplicar
- Atualizada a seção "Instruction Architecture" em `AGENTS.md` para refletir a fonte canônica real (`/.agent/agent.md`).
- Revisadas regras de manutenção para priorizar uma única origem de verdade e evitar drift documental.

### Verificar
- Busca textual confirmou ausência de referências pendentes a `/.agents/*` após ajuste.

### Impacto
- Reduz ambiguidade operacional para agentes e colaboradores.
- Melhora previsibilidade do fluxo `/evolve` ao apontar corretamente a diretriz ativa.

## 2026-04-29 — Correções de consistência CI + documentação

### Detectar / Diagnosticar
- Identificado risco de falha de build por referência incorreta/instável de receitas em workflows.
- Identificado gap de documentação operacional para validação rápida pré-PR.

### Propor / Aplicar
- Corrigidos os caminhos de receita nos workflows de build:
  - `recipe: recipes/recipe-amd.yml`
  - `recipe: recipes/recipe-nvidia.yml`
- Atualizado `docs/CI_CD.md` com:
  - caminhos de receita por variante;
  - checklist de sanidade mínima para YAML, paths de recipe e `build_chunked_oci: false`.

### Verificar
- Parsing YAML de `recipes/*.yml` e `.github/workflows/*.yml` com Ruby (`YAML.load_file`) concluído com sucesso.
- Checagens por regex (`rg`) confirmaram os caminhos de recipe e a restrição de Rechunk desativado.

### Impacto
- Reduz risco de falha em `workflow_dispatch`.
- Melhora previsibilidade e padronização das validações antes de merge.
