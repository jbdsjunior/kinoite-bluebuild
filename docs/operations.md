# Operação e Rotina do Sistema

Guia prático para manter o host Kinoite BlueBuild organizado e previsível no dia a dia.

## Rotina recomendada

### Diariamente

- Verificar status das atualizações automáticas:

```bash
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-flatpak-update.timer
```

### Semanalmente

- Rodar manutenção completa (com limpeza de deployments e podman):

```bash
bash scripts/maintenance.sh --clean-deployments --prune-podman
```

- Se quiser simular antes de executar:

```bash
bash scripts/maintenance.sh --clean-deployments --prune-podman --dry-run
```

### Mensalmente

- Revisar estado do sistema imutável:

```bash
rpm-ostree status
```

- Validar consistência do repositório local:

```bash
bash scripts/validate-project.sh
```

## Perfis de uso úteis

### Host focado só em rpm-ostree

```bash
bash scripts/maintenance.sh --skip-flatpak
```

### Host focado só em Flatpak

```bash
bash scripts/maintenance.sh --skip-rpm-ostree
```

### Limpeza de journal mais agressiva (7 dias)

```bash
bash scripts/maintenance.sh --journal-days 7
```

## Organização operacional

- Prefira `topgrade` via timers para atualização contínua.
- Use `maintenance.sh` para higienização periódica e tarefas mais pesadas.
- Use `validate-project.sh` antes de commit/PR para manter documentação, timers e receitas alinhadas.

## Compatibilidade

O script legado `scripts/mantence.sh` permanece disponível como atalho e redireciona para `maintenance.sh`.
