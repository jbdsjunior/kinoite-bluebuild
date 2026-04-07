# Guia Pós-Instalação (Todas Variantes)

Este guia cobre validação e configuração compartilhada para todos os usuários.

> **Usuários NVIDIA/Híbrido:** Complete este guia primeiro, depois siga [`POST_INSTALL_NVIDIA.md`](POST_INSTALL_NVIDIA.md).

## 1. Virtualização (KVM/libvirt)

### Configurar Permissões

Execute o script de configuração do projeto:

```bash
setup-kvm.sh
```

Saia e entre novamente na sessão para aplicar permissões de grupo.

### Aplicar Atributos NoCOW (BTRFS)

Se usar BTRFS, aplique atributos para evitar Copy-on-Write em VMs e containers:

```bash
# Sistema
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf

# User-local
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

## 2. Montagem de Nuvem (Opcional)

Se usar rclone para sincronização de arquivos:

```bash
# Configurar remservices de nuvem
rclone config

# Habilitar serviço user (substitua 'remote' pelo nome configurado)
systemctl --user enable --now rclone@remote.service
```

## 3. Validar Atualizações Automáticas

Verifique se os timers de atualização estão ativos:

```bash
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-flatpak-update.timer
```

Todos devem mostrar `active (waiting)`.

## 4. Validar Argumentos do Kernel

```bash
# Verificar argumentos atuais
rpm-ostree kargs
```

```bash
sudo rpm-ostree kargs --editor
```

## 5. Inspeção de Mudanças

Ver arquivos de configuração modificados:

```bash
sudo ostree admin config-diff
```

## 6. Validação de Serviços

```bash
# Firewall ativo
sudo systemctl status firewalld

# DNS resolvido
sudo systemctl status systemd-resolved

# Libvirt (se KVM habilitado)
sudo systemctl status libvirtd
```
