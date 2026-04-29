<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)
![Status-Security](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/security-scan.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Imagem OCI imutável baseada em Fedora Kinoite (KDE Plasma), construída com BlueBuild para workloads de desktop, virtualização e desenvolvimento local com foco em reprodutibilidade, segurança e rollback rápido.

---

## Visão Geral

Este repositório publica **duas variantes**:

| Variante | Imagem Base | Destino | Caso de uso |
| :-- | :-- | :-- | :-- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-amd:latest` | Sistemas AMD sem GPU NVIDIA dedicada |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | `ghcr.io/jbdsjunior/kinoite-nvidia:latest` | Sistemas com GPU NVIDIA (inclui híbrido AMD+NVIDIA) |

### Princípios do projeto

- **Immutable-first:** customizações entram via `recipes/*.yml` + `files/system/`, não via `dnf install` direto no host.
- **OCI-native:** troca/atualização da imagem com `bootc switch` e rollback com `bootc rollback`.
- **Shift-left security:** scanner Trivy em CI, upload SARIF e assinatura Cosign no pipeline de build.
- **Fail-fast, recover-faster:** rollback atômico para deployment anterior em caso de regressão.

> ⚠️ **Aviso:** perfil otimizado para workstations com **64 GB RAM**. Consulte o baseline em [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md).

---

## CI/CD

A documentação detalhada de automação está em [`docs/CI_CD.md`](docs/CI_CD.md).

Resumo rápido:
- builds de imagem (`build-amd.yml`, `build-nvidia.yml`) são manuais (`workflow_dispatch`);
- `check-updates.yml` roda em agenda e pode disparar os builds ao detectar novo digest upstream;
- scan de segurança (`security-scan.yml`) e limpeza (`cleanup.yml`) rodam de forma contínua.

---

## Quick Start

## 1) Trocar para a imagem customizada

```bash
# AMD
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest

# NVIDIA
sudo bootc switch ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reinicie após a conclusão.

## 2) Validar assinatura Cosign (recomendado)

Chave pública do projeto: [`cosign.pub`](cosign.pub).

```bash
# Exemplo (AMD)
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest

# Exemplo (NVIDIA)
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

## 3) (Opcional) Enforce de política de assinatura no switch

```bash
# AMD
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# NVIDIA
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

## 4) Pós-instalação

Siga: [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Rollback e Recuperação de Desastres

### Cenários comuns

- Kernel panic após update
- Falha de sessão Wayland
- Regressão de driver (ex.: stack NVIDIA)

### Procedimento recomendado (Fail-Fast, Recover-Faster)

1. Reinicie e selecione o deployment anterior (se necessário).
2. Execute rollback atômico:

```bash
sudo bootc rollback
```

3. Reinicie e valide serviços essenciais:

```bash
systemctl --user status topgrade-update.timer
sudo systemctl status firewalld
```

### Voltar ao Fedora Kinoite stock

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## Estrutura do Repositório

| Caminho | Finalidade |
| :-- | :-- |
| `recipes/recipe-amd.yml` | Receita principal da variante AMD |
| `recipes/recipe-nvidia.yml` | Receita principal da variante NVIDIA |
| `recipes/common-*.yml` | Módulos compartilhados (pacotes, drivers, serviços etc.) |
| `files/system/` | Arquivos aplicados no sistema da imagem |
| `.github/workflows/` | Pipelines CI/CD |
| `cosign.pub` | Chave pública para verificação |

---

## Documentação

| Documento | Objetivo |
| :-- | :-- |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Validações pós-instalação, operação e manutenção |
| [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) | Baseline de hardware e limites operacionais |
| [`docs/CI_CD.md`](docs/CI_CD.md) | Pipelines GitHub Actions, triggers e segurança |
| [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) | Arquitetura declarativa e visão técnica do projeto |

## Licença

Projeto licenciado sob [`LICENSE`](LICENSE).
