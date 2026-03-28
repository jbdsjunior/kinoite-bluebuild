# Post-Installation Guide: NVIDIA & Hybrid (`kinoite-nvidia`)

This guide contains the specific runtime validation, container integration, and Secure Boot considerations for hosts with an NVIDIA GPU (including AMD + NVIDIA hybrid systems).

> **Prerequisite:** Ensure you have completed the baseline operational steps in [`POST_INSTALL.md`](POST_INSTALL.md) before proceeding.

## 1) Validate NVIDIA Stack

Verify the NVIDIA driver is loaded and the discrete GPU is detected:

```bash
nvidia-smi
```

Check if the Container Device Interface (CDI) has already been generated:

```bash
sudo nvidia-ctk cdi list 2>/dev/null || echo "CDI not generated yet"
```

## 2) Enable GPU Access for Containers (CDI)

Generate the CDI definition required for rootless container GPU access. This is mandatory for compute offloading in local LLM and AI workloads:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

Validate the container integration by running a temporary CUDA container:

```bash
podman run --rm --device [nvidia.com/gpu=all](https://nvidia.com/gpu=all) nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## 3) Secure Boot (MOK Enrollment)

If your system has Secure Boot enabled, the out-of-tree NVIDIA kernel modules must be signed and trusted. Enroll the repository key:

```bash
ujust enroll-secure-boot-key
```

Reboot your workstation. You will be prompted by the firmware UI to complete the MOK (Machine Owner Key) enrollment flow before the OS boots.
