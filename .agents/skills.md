# SKILLS — DevSecOps & Linux Engineering

## SEGURANÇA

- **Cadeia de Suprimentos:** Validar assinaturas criptográficas (Cosign) em imagens OCI. Exigir chaves GPG para repositórios de terceiros.
- **Hardening:** Revisar injeção limpa no rootfs. Auditar permissões sensíveis (ex: grupo `libvirt`). Bloquear telemetria/corporativa via `policies.json`.
- **Privilégios:** Nunca elevar privilégios sem justificativa técnica documentada.
- **Browser Policy Baseline (com usabilidade):**
  - Permitir conta/sincronização quando requerido pelo usuário (`BrowserSignin: 1`, `SyncDisabled: false`).
  - Não bloquear configuração dinâmica de DNS seguro no navegador.
  - Manter debloat/privacidade: telemetria desativada, gerenciador de senhas desativado, autofill de endereço/cartão desativado.

## INFRAESTRUTURA

- **systemd:** Serviços injetados devem ser stateless e idempotentes.
- **sysctl:** Parâmetros de kernel aplicados via arquivos dedicados, nunca ad-hoc.
- **BTRFS:** Aplicar NoCOW em diretórios de containers, VMs e caches de build.

## PIPELINE OCI / CI/CD

- Auditar builds/deploys OCI em busca de falhas de manifesto.
- Integrar análise de vulnerabilidade (Trivy) no fluxo de CI.
- BlueBuild: receitas YAML fragmentadas por perfil de hardware.
- Respeitar convenções do repositório para workflows (`uses` e estilo YAML) quando explicitamente definidas.

## OTIMIZAÇÃO DE CONTEXTO (LLM)

- Preferir deltas pequenos e focalizados por arquivo.
- Evitar texto repetitivo em PRs e relatórios técnicos.
- Registrar apenas decisões e trade-offs que afetem operação/manutenção.

## COMUNICAÇÃO

- Saída padrão: relatório Markdown estruturado + plano de ação + trechos refatorados.
- Zero perguntas redundantes. Executar imediatamente.
