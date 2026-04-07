# Post-Installation Guide: NVIDIA & Hybrid (`kinoite-nvidia`)

This guide contains the specific runtime validation, container integration, and Secure Boot considerations for hosts with an NVIDIA GPU (including AMD + NVIDIA hybrid systems).

> **Prerequisite:** Complete the baseline operational steps in [`POST_INSTALL.md`](POST_INSTALL.md) before proceeding.

## 1. Secure Boot (MOK Enrollment)

If your system has Secure Boot enabled, the out-of-tree NVIDIA kernel modules must be signed and trusted. Enroll the repository key:

```bash
ujust enroll-secure-boot-key
```

Reboot your workstation. You will be prompted by the firmware UI to complete the MOK (Machine Owner Key) enrollment flow before the OS boots.
