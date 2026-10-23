## Descrição do Pull Request

<!-- Forneça um resumo claro e conciso das alterações propostas neste PR. -->

### Tipo de Mudança
- [ ] `feat`: Nova funcionalidade ou módulo adicionado
- [ ] `fix`: Correção de bug ou regressão
- [ ] `perf`: Otimização de performance ou I/O
- [ ] `refactor`: Refatoração sem alteração de comportamento
- [ ] `docs`: Atualização de documentação
- [ ] `chore`: Manutenção de dependências ou governança

---

## Conformidade com as Invariantes do Sistema (`AGENTS.md`)

- [ ] **Linha de Boot & Kernel**: Zero kargs redundantes; preservada a baseline upstream do Fedora (`amd-pstate-epp`, sem `nowatchdog`, sem `preempt=full`).
- [ ] **Hardware Profile A**: Compatível com Ryzen 9 5950X, Radeon RX 6600 XT e 64GB DDR4 misto (Daisy-Chain A2/B2 + A1/B1).
- [ ] **Btrfs NoCOW & tmpfiles**: Diretivas `h` não-recursivas aplicadas exclusivamente onde necessário (`/var/lib/containers/storage`, VMs).
- [ ] **Audio & Periféricos**: Respeitado quantum 256 @ 48kHz; quirks Bluetooth cirúrgicos.
- [ ] **Princípio KISS & DRY**: Zero duplicação de configurações já nativas do Fedora Kinoite ou systemd.

---

## Checklist de Validação

- [ ] Suíte de testes automatizados executada e aprovada: `./tests/run_tests.sh`
- [ ] Validação de sintaxe YAML / Shell sem erros (`bash -n`)
- [ ] Conventional Commits respeitados no histórico
- [ ] Árvore de trabalho limpa (`git status` limpo)
