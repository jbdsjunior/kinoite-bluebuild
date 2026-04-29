# Visão do Projeto

## Objetivo

Fornecer imagens OCI imutáveis do Fedora Kinoite com BlueBuild, em duas variantes:

- `kinoite-amd`
- `kinoite-nvidia`

## Arquitetura Declarativa

- Receitas principais:
  - `recipes/recipe-amd.yml`
  - `recipes/recipe-nvidia.yml`
- Módulos compartilhados: `recipes/common-*.yml`
- Arquivos aplicados no sistema: `files/system/`

## Modelo Operacional

- Troca de imagem: `bootc switch`
- Rollback: `bootc rollback`
- Ajustes de kernel args: `rpm-ostree kargs`
- Verificação de drift: `ostree admin config-diff`

## Segurança

- Assinatura de imagens com Cosign
- Scan contínuo de repositório via Trivy (GitHub Actions)
- Mudanças de sistema preferencialmente declarativas (IaC)

## Documentação Relacionada

- Guia principal: `README.md`
- Pós-instalação: `docs/POST_INSTALL.md`
- CI/CD: `docs/CI_CD.md`
- Baseline de hardware: `docs/HARDWARE_BASELINE.md`
