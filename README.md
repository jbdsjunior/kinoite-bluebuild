# Custom Fedora Kinoite (BlueBuild)

![Status Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

A custom, immutable **Fedora Kinoite** image built with [BlueBuild](https://blue-build.org/) and based on [Universal Blue](https://universal-blue.org/).

This project delivers a polished **KDE Plasma** experience with pre-configured optimizations for gaming, development, and content creation, ensuring stability through atomic updates.

## ✨ Variants

| Image Name         | Hardware Support | Description                                                                   |
| :----------------- | :--------------- | :---------------------------------------------------------------------------- |
| **kinoite-amd**    | **AMD / Intel**  | Standard image. Optimized for AMD (P-State) and Intel (Media Driver) GPUs.    |
| **kinoite-nvidia** | **Nvidia**       | Includes proprietary Nvidia drivers, CUDA, and hardware acceleration patches. |

## 🚀 Key Features

- **⚡ Performance Tuned:** optimized kernel arguments (`amd_pstate`, `BBR` congestion control) and `sysctl` tweaks for low latency.
- **📦 Fast Updates:** Builds use **OCI Chunking (`zstd:chunked`)**, drastically reducing download sizes for daily updates.
- **🎬 Multimedia Ready:** Full ffmpeg/codecs support (via Negativo17) and hardware acceleration (VAAPI/VDPAU) for AMD, Intel, and Nvidia.
- **🛡️ Secure & Atomic:** Signed images with verify-on-boot support. Configured for **Composefs** integration (filesystem integrity).
- **💻 Developer Friendly:** Includes `distrobox`, `podman`, `topgrade`, and `fastfetch` out of the box.
- **☁️ Cloud Integration:** Pre-configured `rclone` systemd user service for seamless cloud storage mounting.

---

## 📥 Installation

To switch from a standard Fedora Kinoite installation to this custom image, follow the steps below.

### 1. Initial Rebase (Import Keys)

First, rebase to the unverified image to import the signing keys.

**For AMD / Intel:**

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest

```

**For Nvidia:**

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

**⚠️ Reboot your system immediately after this step.**

### 2. Enable Secure Verification

After rebooting, switch to the signed image to ensure all future updates are verified and secure.

**For AMD / Intel:**

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest

```

**For Nvidia:**

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

**Reboot one last time** to finalize the installation.

---

## 🛠️ Post-Installation Setup

### Virtualization (KVM/QEMU)

To enable virtualization and optimize BTRFS performance for VM images (disabling Copy-on-Write), run the included helper:

```bash
kinoite-setup-kvm.sh

```

_Note: A reboot is required for group permission changes to take effect._

### Cloud Storage (Rclone)

This image includes a systemd template for Rclone.

1. Configure your remote (e.g., GDrive, OneDrive):

```bash
rclone config

```

2. Enable the background mount service (replace `remote-name` with the name you chose):

```bash
systemctl --user enable --now rclone-mount@remote-name.service

```

_Mount point:_ `~/Cloud/remote-name`

---

## 🔄 Verification & Maintenance

### Manually Verify Image

You can check the image signature against the repository public key:

```bash
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest

```

### Rollback

If you need to return to the official Fedora Kinoite image:

```bash
rpm-ostree rebase fedora:fedora/$(rpm -E %fedora)/x86_64/kinoite

```

---
