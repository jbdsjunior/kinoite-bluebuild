# Project Overview

## Objective

Provide immutable Fedora Kinoite OCI images with BlueBuild in two variants:

- `kinoite-amd`
- `kinoite-nvidia`

## Declarative Architecture

- Main recipes:
  - `recipes/recipe-amd.yml`
  - `recipes/recipe-nvidia.yml`
- Shared modules: `recipes/common-*.yml`
- System files applied in image builds: `files/system/`

## Operating Model

- Image switch: `bootc switch`
- Rollback: `bootc rollback`
- Kernel argument management: `rpm-ostree kargs`
- Drift inspection: `ostree admin config-diff`

## Security

- Image signing with Cosign
- Continuous repository scanning with Trivy (GitHub Actions)
- System changes are preferably declarative (Infrastructure as Code)

## Related Documentation

- Main guide: `README.md`
- Post-installation: `docs/POST_INSTALL.md`
- CI/CD: `docs/CI_CD.md`
- Hardware baseline: `docs/HARDWARE_BASELINE.md`
