<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite/actions/workflows/build-nvidia.yml/badge.svg)

# Custom Fedora Kinoite (BlueBuild)

</div>

This project provides a customized, immutable **Fedora Kinoite (KDE Plasma)** image built with [BlueBuild](https://blue-build.org/) and based on [Universal Blue](https://universal-blue.org/). It is engineered for a high-performance experience with out-of-the-box optimizations for **Gaming**, **Development**, and **Privacy**.

## ✨ Key Features & Highlights

### 🎮 Performance & Gaming

- **Kernel Tuning:** Full preemption (`preempt=full`) and `nowatchdog` enabled for lower latency and consistent frametimes.
- **Network Optimization:** **BBR** congestion control enabled for faster downloads and reduced bufferbloat.
- **Hardware Acceleration:** Ready-to-use support for NVIDIA (Proprietary) or AMD (P-State active) + Intel QuickSync enabled for video decoding.
- **Memory Management:** Aggressive ZRAM and `vm.swappiness` tuning to prevent system lockups under heavy load.
- **Multimedia Codecs:** GStreamer + FFmpeg stack enabled for wide codec compatibility (including H.264/H.265 and AAC).
- **DevOps Tooling:** Podman/Buildah/Skopeo and Git/GitHub CLI preinstalled for container-first workflows.

### 🛡️ Privacy & Security

- **DNS Hardening:** DNS over TLS (DoT) and DNSSEC enabled by default (Cloudflare/ControlD) to prevent ISP snooping.
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
| **kinoite-amd** | Optimized for AMD (P-State) and Intel (Media Driver) GPUs. Ideal for Ryzen/Radeon systems. |
| **kinoite-nvidia** | Includes proprietary Nvidia drivers, CUDA, and patches for Wayland/X11 compatibility. |

**Dual-GPU (AMD + NVIDIA) recommendation:** use **`kinoite-nvidia`** to unlock CUDA/LLM acceleration on the 3080 Ti, while the AMD iGPU/dGPU can still be used by the display stack when desired.

---

## 🚀 Installation

The transition to this custom image is done in two stages to ensure that signing keys are correctly imported and verified.

### 1. Initial Rebase (Unverified)

First, switch to the unverified version to import the repository's signing keys.

**For AMD/Intel:**

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

**For AMD/Intel:**

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest

```

**For Nvidia:**

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

> ⚠️ **Action Required:** Reboot one last time to finalize the installation.

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

Exemplo rápido (uma vez) para registrar o CDI do NVIDIA:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

Depois, execute containers com GPU:

```bash
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

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

### ⚡ Kernel Optimization (Manual)

If you want to ensure all performance, filesystem, GPU, and virtualization optimizations are strictly applied (or if you are migrating from another image), run the following command:

```bash
rpm-ostree kargs \
  --append-if-missing="rootflags=subvol=root,noatime,compress=zstd:1" \
  --append-if-missing="transparent_hugepage=madvise" \
  --append-if-missing="amd_pstate=active" \
  --append-if-missing="mitigations=auto" \
  --append-if-missing="nowatchdog" \
  --append-if-missing="nvidia-drm.modeset=1" \
  --append-if-missing="rd.driver.blacklist=nouveau,nova_core" \
  --append-if-missing="modprobe.blacklist=nouveau,nova_core" \
  --append-if-missing="amd_iommu=on" \
  --append-if-missing="iommu=pt" \
  --append-if-missing="kvm_amd.npt=1" \
  --append-if-missing="kvm_amd.avic=1" \
  --append-if-missing="kvm_amd.nested=1" \
  --append-if-missing="kvm_amd.sev=1"

```

> **Note:** A reboot is required after applying kernel arguments.

---

## 🆘 Troubleshooting

### 🏨 Public Wi-Fi / Hotels (Captive Portals)

This image enforces **DNS over TLS** for maximum security. This may prevent "Captive Portal" login screens (common in hotels and airports) from appearing.

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
Re-enable strict security by deleting the override file:

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
bluebuild build recipes/images/amd.yml

```

---

## ⚖️ License

This project is licensed under the **Apache License 2.0**.
