<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Imagem imutavel do Fedora Kinoite (KDE Plasma) gerada com [BlueBuild](https://blue-build.org/), com foco em desempenho, fluxo container-first e operacao diaria simples em 2026.

## Estado atual (2026)

- Duas imagens separadas: `kinoite-amd` e `kinoite-nvidia` (como voce esta usando hoje).
- Build e publicacao automatizadas via GitHub Actions.
- Atualizacao diaria com `topgrade` (system + flatpak) por timers em escopo de usuario.
- Ajustes de kernel/sysctl para desktop pesado, desenvolvimento e virtualizacao.
- Privacidade de rede com `systemd-resolved` e NetworkManager hardening.

## Variantes de imagem

| Imagem | Base image | Quando usar |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | Hosts AMD-only (sem NVIDIA dedicada). |
| `kinoite-nvidia` | `ghcr.io/blue-build/base-images/fedora-kinoite-nvidia` | Hosts com GPU NVIDIA (incluindo AMD + NVIDIA). |

## O que esta incluido

- Kernel args via receita: `amd_pstate=active`, `transparent_hugepage=madvise`, IOMMU/KVM, BTRFS rootflags.
- Tunings de sistema: BBR, swappiness alto para ZRAM, limites de inotify e `vm.max_map_count`.
- Pacotes base extras: `topgrade`, `starship`, `fastfetch`, `distrobox`, stack multimidia (GStreamer/FFmpeg), KVM/libvirt, `rclone`.
- Servicos padrao: `firewalld`, `systemd-resolved`, timers de update com lock por `flock`.
- Arquivos de sistema versionados no repo (`files/system/...`) para comportamento reproduzivel.

## Instalacao (fluxo recomendado)

Use sempre duas etapas: primeiro rebase unverified, depois signed.

### 1) Rebase inicial (unverified)

AMD:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
```

NVIDIA:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reinicie.

### 2) Rebase assinado (verified)

AMD:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

NVIDIA:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reinicie novamente.

### 3) Operacao diaria

Timers usados no host:

- `topgrade-system-update.timer` (diario)
- `topgrade-boot-update.timer` (apos boot)
- `topgrade-flatpak-update.timer` (a cada 6h)

```bash
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer
```

Para manter timers de usuario ativos mesmo sem sessao grafica aberta:

```bash
sudo loginctl enable-linger "$USER"
```

Execucao manual (quando quiser):

```bash
sudo topgrade -cy --skip-notify --only system
topgrade -cy --skip-notify --only flatpak
```

Rollback rapido se necessario:

```bash
sudo rpm-ostree rollback
```

Checagem rapida da imagem atual:

```bash
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
```

## Pos-instalacao

### Virtualizacao (KVM/libvirt)

```bash
kinoite-setup-kvm.sh
```

Depois saia e entre na sessao novamente para recarregar grupos (`libvirt`, `kvm`).

### NVIDIA para containers (CUDA/CDI)

Na `kinoite-nvidia`, gere CDI manualmente se precisar:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### NVIDIA + Secure Boot (MOK)

Se Secure Boot estiver habilitado:

```bash
ujust enroll-secure-boot-key
```

Reinicie e finalize o enroll da MOK na tela de firmware.

### Rclone mount como service de usuario

```bash
rclone config
systemctl --user enable --now rclone-mount@remote-name.service
```

O mount sera criado em `~/Cloud/remote-name`.

## Troubleshooting rapido

### Captive portal (hotel/aeroporto)

Se o portal nao abrir, desative temporariamente DoT/DNSSEC:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/90-captive-portal.conf >/dev/null <<'EOF'
[Resolve]
DNSOverTLS=no
DNSSEC=no
EOF
sudo systemctl restart systemd-resolved
```

Depois, para voltar ao padrao da imagem:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/90-captive-portal.conf
sudo systemctl restart systemd-resolved
```

## Desenvolvimento local

```bash
distrobox assemble create
distrobox enter bluebuild
bluebuild build recipes/recipe-amd.yml
bluebuild build recipes/recipe-nvidia.yml
```

Validacao local antes de publicar:

```bash
./scripts/validate-project.sh
```

Esse script valida referencias BlueBuild (`from-file` e `source`), consistencia entre README/recipes/workflows, sintaxe shell/TOML/XML, unit files (quando `systemd-analyze` estiver disponivel) e lint de shell/YAML quando as ferramentas estiverem instaladas.

## Estrutura do repositorio

- `recipes/`: receitas BlueBuild e modulos compartilhados.
- `files/system/`: configuracoes copiadas para a imagem final.
- `files/scripts/`: utilitarios instalados na imagem (ex.: setup KVM).
- `scripts/validate-project.sh`: sanity check local para CI/manual.
- `.github/workflows/`: build AMD/NVIDIA, monitor de updates de base e cleanup.

## Licenca

Projeto licenciado sob **Apache License 2.0**.
