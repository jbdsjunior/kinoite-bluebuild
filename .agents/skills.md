# SKILLS — DevSecOps & Linux Engineering

## SEGURANÇA

- **Supply chain:** validar assinatura Cosign de imagens OCI e manter GPG obrigatório para repositórios de terceiros.
- **Hardening:** auditar rootfs e permissões sensíveis (ex.: grupo `libvirt`) com princípio do menor privilégio.
- **Browser policy baseline:** manter telemetria off + debloat sem bloquear `BrowserSignin: 1`, `SyncDisabled: false` e DNS seguro configurável.

## INFRAESTRUTURA

- **systemd:** unidades injetadas devem ser stateless e idempotentes.
- **sysctl:** tuning somente via arquivos dedicados versionados.
- **BTRFS:** aplicar NoCOW em caminhos de alto write amplification (containers, VMs, caches de build).

## PIPELINE OCI / CI

- Validar manifestos de build/deploy e garantir separação explícita de jobs AMD/NVIDIA.
- Manter Trivy no CI com severidade alta/crítica e evidência no Security tab (SARIF).
- Preservar `build_chunked_oci: false` enquanto Rechunk estiver proibido pelo projeto.

## PRÁTICA OPERACIONAL

- Preferir deltas pequenos, revertíveis e com testes objetivos.
- Evitar repetição textual em relatórios; registrar apenas decisão e impacto operacional.
