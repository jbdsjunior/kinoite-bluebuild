# CHECKLIST — Execução de Auditoria

## [P0] ESTABILIDADE CORE & SEGURANÇA

- [ ] **Cadeia de Suprimentos:** Cosign ativo? GPG em repositórios de terceiros?
- [ ] **Hardening:** rootfs limpo? Permissões sensíveis corretas?
- [ ] **Browser Policies:** Brave/Chrome/Edge com baseline de debloat + privacidade sem bloquear sync/DNS seguro do usuário?
- [ ] **Boot/Gráficos:** Wayland estável? Configurações inválidas de kernel? Isolamento AMDGPU/NVIDIA sem falhas?
- [ ] **Pipeline OCI:** GitHub Actions sem falhas de build/deploy? Trivy integrado?

## [P1] MANUTENIBILIDADE & ARQUITETURA

- [ ] **Modularidade:** Manifestos BlueBuild fragmentados por hardware (AMD vs NVIDIA)?
- [ ] **IaC:** Serviços systemd stateless? sysctl parametrizado? BTRFS NoCOW aplicado?
- [ ] **Expansibilidade:** Estrutura permite adição de novos perfis de hardware sem retrabalho?
- [ ] **Consistência de Padrões:** Preferências explícitas do projeto foram preservadas (versões de actions, marcadores YAML, estilo de docs)?
- [ ] **Eficiência LLM:** Arquivos de agente e docs estão objetivos, sem redundância e com estrutura escaneável?
