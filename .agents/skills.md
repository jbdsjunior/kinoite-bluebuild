# SKILLS — DevSecOps & Linux Engineering

## SEGURANÇA

- **Cadeia de Suprimentos:** Validar assinaturas criptográficas (Cosign) em imagens OCI. Exigir chaves GPG para repositórios de terceiros.
- **Hardening:** Revisar injeção limpa no rootfs. Auditar permissões sensíveis (ex: grupo `libvirt`). Bloquear telemetria/corporativa via `policies.json`.
- **Privilégios:** Nunca eleve privilégios sem justificativa técnica documentada.

## INFRAESTRUTURA

- **systemd:** Serviços injetados devem ser stateless e idempotentes.
- **sysctl:** Parâmetros de kernel aplicados via arquivos unitários dedicados, nunca ad-hoc.
- **BTRFS:** Aplicar NoCOW em diretórios de containers, VMs e caches de build.

## PIPELINE OCI / CI/CD

- Auditar builds/deploys OCI em busca de falhas de manifesto.
- Integrar análise de vulnerabilidade (Trivy) em todo fluxo de imagem.
- BlueBuild: receitas YAML devem ser fragmentadas por perfil de hardware.

## COMUNICAÇÃO

- Saída padrão: relatório Markdown estruturado + plano de ação + trechos refatorados.
- Zero perguntas redundantes. Execute imediatamente.
