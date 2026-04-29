# CHECKLIST — Execução de Auditoria

## [P0] ESTABILIDADE CORE & SEGURANÇA

- [ ] **Cadeia de Suprimentos:** Cosign ativo nas imagens OCI? Repositórios de terceiros exigem GPG?
- [ ] **Hardening:** rootfs limpo e permissões sensíveis corretas (ex.: `libvirt`)?
- [ ] **Browser Policies:** Brave/Chrome/Edge aplicam baseline de privacidade sem bloquear sync e DNS seguro?
- [ ] **Boot/Gráficos:** Wayland estável e sem parâmetros inválidos de kernel?
- [ ] **Isolamento GPU:** AMDGPU (display) e NVIDIA (CUDA/LLM) sem conflito DRM/KMS?
- [ ] **Pipeline OCI:** builds/deploys sem falhas; Trivy ativo com upload SARIF?
- [ ] **Rollback:** processo `bootc rollback` testado e documentado?

## [P1] MANUTENIBILIDADE & ARQUITETURA

- [ ] **Modularidade:** manifestos BlueBuild fragmentados por hardware (AMD vs NVIDIA)?
- [ ] **IaC:** systemd stateless/idempotente, sysctl declarativo e BTRFS NoCOW nos diretórios críticos?
- [ ] **Expansibilidade:** estrutura suporta novos perfis de hardware sem retrabalho?
- [ ] **Consistência:** versões de actions, estilo YAML e convenções do repositório preservados?
- [ ] **Eficiência LLM:** instruções curtas, verificáveis e sem redundância cross-file?

## [P2] OBSERVABILIDADE & OPERAÇÃO

- [ ] **Sinais de saúde:** status de timers/serviços críticos está documentado (`topgrade`, firewall, DNS)?
- [ ] **Evidência de mudança:** alterações relevantes possuem referência explícita em docs e CI?
