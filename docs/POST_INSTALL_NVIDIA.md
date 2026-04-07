# Post-Installation Guide: NVIDIA & Hybrid (`kinoite-nvidia`)

Runtime validation, container GPU integration, and Secure Boot for hosts with NVIDIA GPUs.

> **Prerequisite:** Complete the baseline steps in [`POST_INSTALL.md`](POST_INSTALL.md) first.

## 1. Secure Boot (MOK Enrollment)

If Secure Boot is enabled, enroll the repository key for out-of-tree NVIDIA kernel modules:

```bash
ujust enroll-secure-boot-key
```

Reboot and complete the MOK (Machine Owner Key) enrollment in the firmware UI.
