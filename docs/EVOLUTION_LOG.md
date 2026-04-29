# Evolution Log (`/evolve`)

Registro curto de ciclos de evolução aplicados no repositório, com foco em rastreabilidade.

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
