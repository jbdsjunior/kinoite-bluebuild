# AGENTS.md - Convencoes do repositorio

## Principios canonicos
1. Immutable-first: customizacao via recipes/*.yml e files/system/.
2. OCI-native: bootc switch / bootc rollback.
3. Shift-left security: Trivy gate, Cosign, SBOM em CI.
4. Fail fast, recover faster: rollback atomico.

## Hierarquia de referencia
- recipes/recipe-amd.yml agrega common-*.yml
- common-base.yml orquestra a ordem dos modulos
- files/system/ overlays imutaveis copiados para /
- .github/workflows/ CI/CD

## Regras de edicao
- Nao instalar pacotes no host; declarar nas recipes.
- Units de usuario em files/system/usr/lib/systemd/user/.
- Manter docs/POST_INSTALL.md sincronizado com os overlays.
