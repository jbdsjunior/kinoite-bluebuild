# Post-Installation Guide (Kinoite BlueBuild)

This guide describes post-rebase validation and adjustments for safe operation on an immutable system.

---

## 1) Initial Validation (after reboot)

### System state

```bash
rpm-ostree status
bootc status
```

Expected: `active (waiting)` with recurring interval `OnUnitInactiveSec=45m` and randomized delay.

> ⚠️ **Warning:** this timer is **user-scoped**. Run the command as the logged-in desktop user.

---

## 2) Available Global Aliases

| Alias | Command/Action |
| :-- | :-- |
| `update` | Run `topgrade` |
| `rollback` | `sudo bootc rollback` |
| `kargs` | `rpm-ostree kargs` |
| `kargs-edit` | `sudo rpm-ostree kargs --editor` |
| `config-diff` | `sudo ostree admin config-diff` |
| `update-status` | `systemctl --user status topgrade-update.timer topgrade-update.service` |
| `fw-status` | `sudo systemctl status firewalld` |
| `dns-status` | `sudo systemctl status systemd-resolved` |
| `kvm-status` | `sudo systemctl status libvirtd` |
| `secureboot-enroll` | `ujust enroll-secure-boot-key` (NVIDIA) |
| `tmpfiles-system` | `sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf` |
| `tmpfiles-user` | `systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf` |
| `status-all` | `update-status && fw-status && dns-status` |
| `kvm-setup` | `sudo setup-kvm.sh` |

---

## 3) Essential Services

```bash
sudo systemctl status firewalld
sudo systemctl status systemd-resolved
```

If you use virtualization:

```bash
sudo systemctl status libvirtd
```

---

## 4) Virtualization (KVM/libvirt)

Configure permissions and groups:

```bash
sudo setup-kvm.sh
```

Or use:

```bash
kvm-setup
```

Log out and log back in to apply group changes.

---

## 5) BTRFS NoCOW for I/O-heavy workloads

Apply system tmpfiles:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
```

Apply user tmpfiles:

```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

---

## 6) NVIDIA (nvidia variant only)

If Secure Boot is enabled, enroll the MOK key:

```bash
ujust enroll-secure-boot-key
```

Then reboot and validate kernel modules and graphics stack according to your workflow.

---

## 7) OCI-native operation and kernel argument changes

List current kernel arguments:

```bash
rpm-ostree kargs
```

Edit kernel arguments:

```bash
sudo rpm-ostree kargs --editor
```

Inspect drift/configuration:

```bash
sudo ostree admin config-diff
```

> ⚠️ **Warning:** on immutable systems, prefer declarative changes in `recipes/*.yml` and versioned files instead of repeated manual host adjustments.

---

## 8) Disaster Recovery / Rollback

### When to use

- Boot failure after update
- Kernel panic
- Broken graphical session
- Critical driver regression

### Procedure

1. Boot into the previous deployment (boot menu), if needed.
2. Run rollback:

```bash
sudo bootc rollback
```

3. Reboot.
4. Validate update timer and core services:

```bash
systemctl --user status topgrade-update.timer
sudo systemctl status firewalld
sudo systemctl status systemd-resolved
```

### Return to stock Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## 9) Rclone Mount (optional)

```bash
rclone config
systemctl --user enable --now rclone@<remote-name>.service
```


## 10) Post-install health check

This validates staged rpm-ostreed policy, topgrade user timer visibility/enabled state, and rootless Podman readiness.

---

## 11) Podman automatic cleanup timers

Validate root-scope timer:

```bash
sudo systemctl status podman-prune-root.timer
```

Validate rootless timer:

```bash
systemctl --user status podman-prune-user.timer
```

Run one-shot cleanup manually when needed:

```bash
sudo systemctl start podman-prune-root.service
systemctl --user start podman-prune-user.service
```

Expected policy:

- `flatpak-system-update.timer` and `flatpak-user-update.timer`: `OnBootSec=5m`, `OnUnitActiveSec=15m`.
- `rpm-ostreed-automatic.timer`: `OnBootSec=10m`, `OnUnitActiveSec=45m`.
- `podman-prune-root.timer` and `podman-prune-user.timer`: boot-triggered + every `1d` (`OnUnitActiveSec=1d`).
- Update and prune services run with low scheduling pressure (`Nice=19`, `IOSchedulingClass=idle`) and network-online ordering.

---
