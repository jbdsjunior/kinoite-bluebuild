# Guia Pós-Instalação

## Aliases Globais

O sistema inclui aliases globais pré-configurados para rotinas de manutenção.
Disponíveis em todos os shells de login:

| Alias               | Comando                                                   |
| ------------------- | --------------------------------------------------------- |
| `update`            | Executa topgrade (alinhado ao timer do usuário)           |
| `rollback`          | `sudo bootc rollback`                                     |
| `kargs`             | `rpm-ostree kargs`                                        |
| `kargs-edit`        | `sudo rpm-ostree kargs --editor`                          |
| `config-diff`       | `sudo ostree admin config-diff`                           |
| `update-status`     | `systemctl --user status topgrade-update.timer`           |
| `fw-status`         | `sudo systemctl status firewalld`                         |
| `dns-status`        | `sudo systemctl status systemd-resolved`                  |
| `kvm-status`        | `sudo systemctl status libvirtd`                          |
| `secureboot-enroll` | `ujust enroll-secure-boot-key` (variante NVIDIA)          |
| `tmpfiles-system`   | Aplica NoCOW BTRFS (system)                               |
| `tmpfiles-user`     | Aplica NoCOW BTRFS (user)                                 |
| `status-all`        | Combo: `update-status && fw-status && dns-status`         |
| `kvm-setup`         | `sudo setup-kvm.sh`                                       |

## Virtualização (KVM/libvirt)

### Configurar permissões

Execute:

```bash
sudo setup-kvm.sh
```

Ou use o alias:

```bash
kvm-setup
```

Saia e entre novamente na sessão para aplicar permissões de grupo.

## Rclone Mount (opcional)

### Configurar remotes

```bash
rclone config
```

### Habilitar serviço user

```bash
systemctl --user enable --now rclone@<remote-name>.service
```

## Aplicar atributos NoCOW (BTRFS)

Se usar BTRFS, aplique atributos para evitar Copy-on-Write em VMs e containers.

### Sistema

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
```

### Usuário

```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

## NVIDIA GPU (apenas variante nvidia)

### Secure Boot (Enrollment MOK)

Se Secure Boot estiver habilitado, registre a chave para módulos NVIDIA:

```bash
ujust enroll-secure-boot-key
```

## Validar atualizações automáticas

```bash
systemctl --user status topgrade-update.timer
```

O status esperado é `active (waiting)`.

## Validar argumentos do kernel

```bash
rpm-ostree kargs
```

Para edição (se necessário):

```bash
sudo rpm-ostree kargs --editor
```

## Inspeção de mudanças

```bash
sudo ostree admin config-diff
```

## Validação de serviços

### Firewall

```bash
sudo systemctl status firewalld
```

### DNS resolvido

```bash
sudo systemctl status systemd-resolved
```

### Libvirt (se KVM habilitado)

```bash
sudo systemctl status libvirtd
```
