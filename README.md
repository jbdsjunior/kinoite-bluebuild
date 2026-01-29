---

title: Custom Fedora Kinoite (BlueBuild)

This project provides a customized, immutable Fedora Kinoite image built with [BlueBuild](https://blue-build.org/) and based on [Universal Blue](https://universal-blue.org/). It is designed for a high-performance KDE Plasma experience with out-of-the-box optimizations for gaming and development.

![Status-Updates](https://github.com/jbdsjunior/kinoite/actions/workflows/check-updates.yml/badge.svg) ![Status-AMD](https://github.com/jbdsjunior/kinoite/actions/workflows/build-amd.yml/badge.svg) ![Status-NVIDIA](https://github.com/jbdsjunior/kinoite/actions/workflows/build-nvidia.yml/badge.svg)

## 💿 Variants

Choose the image that matches your hardware:

- **kinoite-amd**: Optimized for AMD (P-State) and Intel (Media Driver) GPUs.
- **kinoite-nvidia**: Includes proprietary Nvidia drivers, CUDA, and hardware acceleration patches.

## 🚀 Installation

The transition to this custom image is done in two stages to ensure that signing keys are correctly imported and verified.

## 1. Initial Rebase

First, switch to the unverified version to import the repository's signing keys.

### For AMD/Intel

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
```

### For Nvidia

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

> **Action Required:** Reboot your system immediately after this step.

## 2. Enable Verification

After rebooting, switch to the signed image to ensure all future updates are cryptographically verified.

### AMD/Intel

```bash

rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

### Nvidia

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest

```

> **Action Required:** Reboot one last time to finalize the installation.

---

## 🛠️ Post-Installation Setup

### Virtualization (KVM/QEMU)

To configure virtualization groups and optimize BTRFS performance for VM storage, run the included helper:

```bash
kinoite-setup-kvm.sh

```

*Note: This script disables Copy-on-Write (No_COW) for VM directories to improve performance.*

### Cloud Storage (Rclone)

Mount your cloud drives (GDrive, OneDrive, etc.) as local folders:

1. **Configure:** `rclone config`.
2. **Enable Mount:**

## Replace 'remote-name' with your configured remote

```bash

systemctl --user enable --now rclone-mount@remote-name.service

```

*Your files will be available at `~/Cloud/remote-name`.*

---

### 💻 Local Development

If you wish to build or test changes locally using Distrobox:

1. **Create Container:** `distrobox assemble create`.
2. **Enter Environment:** `distrobox enter bluebuild`.
3. **Build Image:**

## Build the AMD variant

```bash
bluebuild build recipes/recipe-amd.yml

```

---

## ⚖️ License

This project is licensed under the **Apache License 2.0**.

---
