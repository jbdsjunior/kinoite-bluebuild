<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite/actions/workflows/build-nvidia.yml/badge.svg)

# Custom Fedora Kinoite (BlueBuild)

</div>

This project provides a customized, immutable **Fedora Kinoite (KDE Plasma)** image built with [BlueBuild](https://blue-build.org/) for a bootable container workflow (bootc-compatible image delivery). It is engineered for a high-performance experience with out-of-the-box optimizations for **Gaming**, **Development**, and **Privacy**.

## ✨ Key Features & Highlights

### 🎮 Performance & Gaming

- **Kernel Tuning:** `amd_pstate=active`, `transparent_hugepage=madvise`, and virtualization-friendly kernel args are applied by recipe.
- **Network Optimization:** **BBR** congestion control enabled for faster downloads and reduced bufferbloat.
- **Hardware Acceleration:** Ready-to-use support for AMD (Radeon stack) and NVIDIA (hybrid AMD+NVIDIA profile with proprietary drivers/CUDA).
- **Memory Management:** Aggressive ZRAM and `vm.swappiness` tuning to prevent system lockups under heavy load.
- **Multimedia Codecs:** GStreamer + FFmpeg stack enabled for wide codec compatibility (including H.264/H.265 and AAC).
- **DevOps Tooling:** Podman/Buildah/Skopeo and Git/GitHub CLI preinstalled for container-first workflows.

### 🛡️ Privacy & Security

- **DNS Hardening:** Control D (p2) as primary with Cloudflare fallback, plus privacy-focused defaults (`DNSOverTLS=opportunistic`, `DNSSEC=allow-downgrade`) for better network compatibility.
- **Anti-Tracking:** Wi-Fi MAC Address randomization and protection against local name leaks (`ResolveUnicastSingleLabel=no`).
- **Firewall:** `firewalld` enabled and configured by default.

### 🛠️ Modern CLI Tools (Rust)

Classic GNU tools replaced with modern, faster Rust alternatives:

<!-- - **`eza`** (replaces `ls`): File listing with git integration and icons.
- **`bat`** (replaces `cat`): File viewer with syntax highlighting.
- **`zoxide`** (replaces `cd`): Smarter directory navigation. -->
- **`fastfetch`** & **`starship`**: Instant system information and a responsive shell prompt.
- **LLM-Friendly Prompt:** A minimal `starship` layout to keep terminal output clean and easier to parse for assistants.

---

## 💿 Variants

Choose the image that matches your hardware:

| Image Name | Description |
| :--- | :--- |
| **kinoite-amd** | Optimized for AMD-only systems (CPU/GPU stack and kernel tuning focused on Ryzen/Radeon hosts). |
| **kinoite-nvidia** | Optimized for AMD + NVIDIA hybrid systems. It uses `ghcr.io/blue-build/base-images/fedora-kinoite-nvidia` as base and adds this repo's shared tuning/tooling modules. |

**Dual-GPU (AMD + NVIDIA) recommendation:** use **`kinoite-nvidia`** to unlock CUDA/LLM acceleration on the 3080 Ti, while the AMD iGPU/dGPU can still be used by the display stack when desired.

---

## 🚀 Installation

The transition to this custom image is done in two stages to ensure that signing keys are correctly imported and verified.

### 1. Initial Rebase (Unverified)

First, switch to the unverified version to import the repository's signing keys.

**For AMD:**

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest

```

**For Nvidia:**

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

> ⚠️ **Action Required:** Reboot your system immediately after this step.

### 2. Enable Verification (Signed)

After rebooting, switch to the signed image to ensure all future updates are cryptographically verified.

**For AMD:**

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest

```

**For Nvidia:**

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

> ⚠️ **Action Required:** Reboot one last time to finalize the installation.

### 3. Ongoing Updates (Topgrade-First, 2026+)

This image uses `topgrade` as the primary day-2 update workflow:

- `topgrade-system-update.timer` (user scope, daily)
- `topgrade-boot-update.timer` (user scope, shortly after boot)
- `topgrade-flatpak-update.timer` (user scope, every 6 hours)

```bash
# Check timers
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer

# Manual run (optional)
sudo topgrade -cy --skip-notify --only system
topgrade -cy --skip-notify --only flatpak

# Switch image/tag manually when needed
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

> You can recover with `rpm-ostree rollback` after reboot if needed.

---

## 🛠️ Post-Installation Setup

### Virtualization (KVM/QEMU)

The system automatically configures user VM directories with the `No_COW` (+C) attribute for maximum BTRFS performance.

To add your user to the necessary virtualization groups (`libvirt`, `kvm`), simply run:

```bash
kinoite-setup-kvm.sh

```

*Please logout or restart after running this command.*

### 🤖 LLMs com GPU NVIDIA (CUDA)

A imagem **`kinoite-nvidia`** inclui o **`nvidia-container-toolkit`** para acelerar workloads de LLMs via Podman/Distrobox.

Exemplo rápido para registrar/atualizar o CDI do NVIDIA manualmente (se necessário):

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

Depois, execute containers com GPU:

```bash
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### 🔐 NVIDIA + Secure Boot (MOK)

Na variante **`kinoite-nvidia`**, os drivers NVIDIA já vêm da imagem base `ghcr.io/blue-build/base-images/fedora-kinoite-nvidia`.
Se o Secure Boot estiver ativo na máquina, execute o helper oficial da Universal Blue no host:

No host, importe a chave pública MOK com:

```bash
ujust enroll-secure-boot-key
```

Depois reinicie e conclua o fluxo **Enroll MOK** na tela azul do firmware.

### Cloud Storage (Rclone)

Mount your cloud drives (GDrive, OneDrive, etc.) as local folders:

1. Configure your remote: `rclone config`
2. Enable automatic mounting:

```bash
# Replace 'remote-name' with the name you configured in step 1
systemctl --user enable --now rclone-mount@remote-name.service

```

*Your files will be available at `~/Cloud/remote-name`.*

---

### ⚡ Kernel Arguments (Recommended Workflow)

Most kernel arguments are already managed in recipe modules (`recipes/common-kargs.yml` and `recipes/common-kvm.yml`).

For permanent changes:

1. Edit the recipe/module in this repo.
2. Build/publish a new image.
3. Apply it on host with the regular system update flow (`topgrade --only system`) or a signed `rpm-ostree rebase` when switching image tags/variants.

Use direct host-side `rpm-ostree kargs` only as a temporary troubleshooting override.

---

## 🆘 Troubleshooting

### 🏨 Public Wi-Fi / Hotels (Captive Portals)

This image uses DNS privacy defaults focused on compatibility (`DNSOverTLS=opportunistic` and `DNSSEC=allow-downgrade`). Public captive portals (hotels/airports) can still fail in some networks.

**Temporary Workaround:**
If you cannot connect to a public Wi-Fi, run the following command to temporarily relax security settings:

```bash
# Allow opportunistic TLS and downgrade security for Captive Portals
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo bash -c 'cat <<EOF > /etc/systemd/resolved.conf.d/permissive-dns.conf
[Resolve]
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF'
sudo systemctl restart systemd-resolved

```

**When back home (Secure Network):**
Re-enable your default profile by deleting the override file:

```bash
sudo rm /etc/systemd/resolved.conf.d/permissive-dns.conf
sudo systemctl restart systemd-resolved

```

---

## 💻 Local Development

If you wish to build or test changes locally using Distrobox:

1. **Create Container:** `distrobox assemble create`
2. **Enter Environment:** `distrobox enter bluebuild`
3. **Build Recipe:**

```bash
bluebuild build recipes/recipe-amd.yml

```

### ✅ Local Validation

Before publishing new images, validate recipe references and Linux config syntax:

```bash
./scripts/validate-project.sh
```

This checks shell script syntax, TOML/XML syntax, systemd unit validity (when `systemd-analyze` is available), and BlueBuild recipe references (`from-file` and `source` paths).

---

## ⚖️ License

This project is licensed under the **Apache License 2.0**.
