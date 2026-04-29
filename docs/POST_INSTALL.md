# Guia Pós-Instalação (Kinoite BlueBuild)

Este guia descreve validações e ajustes pós-rebase para operação segura em ambiente imutável.

---

## 1) Validação Inicial (após reboot)

### Estado do sistema

```bash
rpm-ostree status
bootc status
```

### Timer de atualização automática (usuário)

```bash
systemctl --user status topgrade-update.timer
```

Esperado: `active (waiting)`.

> ⚠️ **Aviso:** o timer é de escopo **user**. Execute no usuário logado da sessão desktop.

---

## 2) Aliases Globais Disponíveis

| Alias | Comando/ação |
| :-- | :-- |
| `update` | Executa `topgrade` |
| `rollback` | `sudo bootc rollback` |
| `kargs` | `rpm-ostree kargs` |
| `kargs-edit` | `sudo rpm-ostree kargs --editor` |
| `config-diff` | `sudo ostree admin config-diff` |
| `update-status` | `systemctl --user status topgrade-update.timer` |
| `fw-status` | `sudo systemctl status firewalld` |
| `dns-status` | `sudo systemctl status systemd-resolved` |
| `kvm-status` | `sudo systemctl status libvirtd` |
| `secureboot-enroll` | `ujust enroll-secure-boot-key` (NVIDIA) |
| `tmpfiles-system` | `sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf` |
| `tmpfiles-user` | `systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf` |
| `status-all` | `update-status && fw-status && dns-status` |
| `kvm-setup` | `sudo setup-kvm.sh` |

---

## 3) Serviços Essenciais

```bash
sudo systemctl status firewalld
sudo systemctl status systemd-resolved
```

Se usar virtualização:

```bash
sudo systemctl status libvirtd
```

---

## 4) Virtualização (KVM/libvirt)

Configure permissões e grupos:

```bash
sudo setup-kvm.sh
```

Ou:

```bash
kvm-setup
```

Faça logout/login para aplicar grupos.

---

## 5) BTRFS NoCOW para workloads de I/O intenso

Aplicar tmpfiles do sistema:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
```

Aplicar tmpfiles do usuário:

```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

---

## 6) NVIDIA (apenas variante nvidia)

Se Secure Boot estiver habilitado, faça enrollment da chave MOK:

```bash
ujust enroll-secure-boot-key
```

Depois reinicie e valide módulos/stack gráfica conforme seu fluxo.

---

## 7) Operação OCI-Native e alteração de kernel args

Consultar kargs atuais:

```bash
rpm-ostree kargs
```

Editar kargs:

```bash
sudo rpm-ostree kargs --editor
```

Inspecionar drift/configuração:

```bash
sudo ostree admin config-diff
```

> ⚠️ **Aviso:** em sistema imutável, prefira mudanças declarativas por receita (`recipes/*.yml`) e arquivos versionados em vez de ajustes manuais recorrentes no host.

---

## 8) Recuperação de Desastres / Rollback

### Quando usar

- Boot falhando após update
- Kernel panic
- Sessão gráfica quebrada
- Regressão crítica de driver

### Procedimento

1. Faça boot no deployment anterior (menu de boot), se necessário.
2. Execute rollback:

```bash
sudo bootc rollback
```

3. Reinicie.
4. Valide timer de update e serviços base:

```bash
systemctl --user status topgrade-update.timer
sudo systemctl status firewalld
sudo systemctl status systemd-resolved
```

### Retornar para imagem base Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## 9) Rclone Mount (opcional)

```bash
rclone config
systemctl --user enable --now rclone@<remote-name>.service
```
