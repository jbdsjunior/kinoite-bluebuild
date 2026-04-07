# Guia Pós-Instalação

## Virtualização (KVM/libvirt)

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

## Validação de GPU

### AMD GPU

Verifique se os drivers Mesa estão carregados corretamente:

```bash
# Verificar renderizador Vulkan
vulkaninfo --summary

# Verificar drivers VA-API (aceleração de vídeo)
vainfo
```

Espera-se ver `card0` e `renderD128` (ou similar) listados.

### NVIDIA GPU (Apenas variante nvidia)

## Secure Boot (Enrollment MOK)

Se Secure Boot estiver habilitado, registre a chave para módulos kernel NVIDIA:

```bash
ujust enroll-secure-boot-key
```

## Montagem de Nuvem (Opcional)

Se usar rclone para sincronização de arquivos:

```bash
# Configurar remservices de nuvem
rclone config

# Habilitar serviço user (substitua 'remote' pelo nome configurado)
systemctl --user enable --now rclone@remote.service
```

## 5. Validar Atualizações Automáticas

Verifique se os timers de atualização estão ativos:

```bash
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-flatpak-update.timer
```

Todos devem mostrar `active (waiting)`.

## Validar Argumentos do Kernel

```bash
# Verificar argumentos atuais
rpm-ostree kargs
```

Para edição (se necessário):

```bash
sudo rpm-ostree kargs --editor
```

## Inspeção de Mudanças

Ver arquivos de configuração modificados:

```bash
sudo ostree admin config-diff
```

## Validação de Serviços

```bash
# Firewall ativo
sudo systemctl status firewalld

# DNS resolvido
sudo systemctl status systemd-resolved

# Libvirt (se KVM habilitado)
sudo systemctl status libvirtd
```
