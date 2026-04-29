# CI/CD e Automação (GitHub Actions)

Este documento descreve **somente** os pipelines do GitHub Actions e sua operação.

## Visão Geral

| Workflow | Trigger | Objetivo |
| :-- | :-- | :-- |
| `build-amd.yml` | `workflow_dispatch` | Build/publicação da imagem AMD |
| `build-nvidia.yml` | `workflow_dispatch` | Build/publicação da imagem NVIDIA |
| `check-updates.yml` | `schedule` (2h) + `workflow_dispatch` | Detecta novo digest upstream e dispara builds |
| `security-scan.yml` | `push(main)`, `pull_request`, `schedule`, `workflow_dispatch` | Scan de segurança com Trivy + SARIF |
| `cleanup.yml` | `schedule` diário + `workflow_dispatch` | Limpeza de imagens e runs antigos |

---

## Build de Imagens

### AMD
- Workflow: `.github/workflows/build-amd.yml`
- Trigger: manual (`workflow_dispatch`)
- Timeout: 45 min
- Ação principal: `blue-build/github-action@v1`
- Assinatura: via `cosign_private_key: ${{ secrets.SIGNING_SECRET }}`

### NVIDIA
- Workflow: `.github/workflows/build-nvidia.yml`
- Trigger: manual (`workflow_dispatch`)
- Timeout: 45 min
- Ação principal: `blue-build/github-action@v1`
- Assinatura: via `cosign_private_key: ${{ secrets.SIGNING_SECRET }}`

### Configurações relevantes de build

- `verify_install: true`
- `use_cache: true`
- `retry_push_count: 3`
- `build_chunked_oci: false` (estado atual)

---

## Atualização Automática por Digest

Workflow: `.github/workflows/check-updates.yml`

- Agenda: `0 */2 * * *` (a cada 2 horas)
- Matriz: `amd` e `nvidia`
- Fluxo:
  1. Lê `base-image` em `recipes/recipe-<flavor>.yml`
  2. Obtém digest remoto com `skopeo inspect`
  3. Compara via cache key `upstream-<flavor>-<digest>`
  4. Se digest novo, dispara `gh workflow run build-<flavor>.yml`

> Resultado prático: os builds de imagem continuam manuais por design, mas são **orquestrados automaticamente** pelo checker quando o upstream muda.

---

## Segurança (Shift-Left)

Workflow: `.github/workflows/security-scan.yml`

- Trivy em modo filesystem (`scan-type: fs`)
- Severidades: `CRITICAL,HIGH`
- `ignore-unfixed: true`
- Upload SARIF para Security tab

Recomendação:
- manter revisão periódica de `ignore-unfixed`;
- considerar gate opcional por branch protegida para severidade crítica.

---

## Higiene Operacional

Workflow: `.github/workflows/cleanup.yml`

- Remove versões antigas de imagens GHCR (mantém 7)
- Remove runs antigos (retém mínimo para investigação)

---

## Boas Práticas Recomendadas

1. **Separar documentação por domínio**
   - Projeto/uso: `README.md`
   - Operação pós-instalação: `docs/POST_INSTALL.md`
   - CI/CD: `docs/CI_CD.md`
   - Hardware/perfil: `docs/HARDWARE_BASELINE.md`
2. **Evitar drift documental**
   - Toda mudança em `.github/workflows/*.yml` deve atualizar `docs/CI_CD.md`.
3. **Auditoria contínua**
   - Revisar triggers, permissões e secrets trimestralmente.
