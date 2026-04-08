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

#### Sistema

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
```

#### User

```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

### NVIDIA GPU (Apenas variante nvidia)

#### Secure Boot (Enrollment MOK)

If Secure Boot is enabled, register the key for NVIDIA kernel modules:

```bash
ujust enroll-secure-boot-key
```

## Validar Atualizações Automáticas

Verifique se os timers de atualização estão ativos:

```bash
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-flatpak-update.timer
```

Todos devem mostrar `active (waiting)`.

## Validar Argumentos do Kernel

#### Verificar argumentos atuais

```bash
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

#### Firewall ativo

```bash
sudo systemctl status firewalld
```

#### DNS resolvido

```bash
sudo systemctl status systemd-resolved
```

#### Libvirt (se KVM habilitado)

```bash
sudo systemctl status libvirtd
```
