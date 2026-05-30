# Post-Installation Guide (Kinoite BlueBuild)

This guide describes post-rebase validation and adjustments for safe operation on an immutable system.

---
### (Optional) Verify Cosign signature (recommended)

Project public key: [`cosign.pub`](cosign.pub).

Example (AMD)

```bash
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest
```

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

| Alias               | Command/Action                                                                       |
| :------------------ | :----------------------------------------------------------------------------------- |
| `update`            | Run `topgrade`                                                                       |
| `rollback`          | `sudo bootc rollback`                                                                |
| `kargs`             | `rpm-ostree kargs`                                                                   |
| `kargs-edit`        | `sudo rpm-ostree kargs --editor`                                                     |
| `config-diff`       | `sudo ostree admin config-diff`                                                      |
| `fw-status`         | `sudo systemctl status firewalld`                                                    |
| `dns-status`        | `sudo systemctl status systemd-resolved`                                             |
| `kvm-status`        | `sudo systemctl status libvirtd`                                                     |
| `tmpfiles-system`   | `sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf`        |
| `tmpfiles-user`     | `systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf` |
| `status-all`        | `fw-status && dns-status`                                                            |
| `kvm-setup`         | `sudo setup-kvm.sh`                                                                  |

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

## 6) OCI-native operation and kernel argument changes

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

## 7) Disaster Recovery / Rollback

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
4. Reboot and validate update timer and core services:

```bash
sudo systemctl status firewalld
sudo systemctl status systemd-resolved
```

### Return to stock Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## 8) Rclone cloud mounts for KDE Plasma (optional)

The image ships systemd user units for rclone FUSE mounts that start with the KDE Plasma graphical session, restart after transient failures, and write logs to the user journal. The default mount points are:

| Service | Expected rclone remote | Mount point | Optional override file |
|---|---|---|---|
| `rclone-google-drive.service` | `GoogleDrive:` | `~/Cloud/GoogleDrive` | `~/.config/rclone/env/google-drive.env` |
| `rclone-onedrive.service` | `OneDrive:` | `~/Cloud/OneDrive` | `~/.config/rclone/env/onedrive.env` |
| `rclone@<remote>.service` | `<remote>:` | `~/Cloud/<remote>` | `~/.config/rclone/env/<remote>.env` |

Configure the cloud remotes first. Name them `GoogleDrive` and `OneDrive` to use the dedicated units without overrides, or set `RCLONE_REMOTE=<remote>:` in the matching environment file.

The units are installable from `default.target` as well as the KDE graphical-session targets. This keeps enabled mounts starting with the user manager at login even when Plasma does not reliably re-trigger `graphical-session.target` wants.

```bash
rclone config
mkdir -p ~/.config/rclone/env
printf 'RCLONE_BWLIMIT=40M\n' > ~/.config/rclone/env/google-drive.env
printf 'RCLONE_BWLIMIT=40M\n' > ~/.config/rclone/env/onedrive.env
systemctl --user daemon-reload
systemctl --user enable --now rclone-google-drive.service rclone-onedrive.service
```

For remotes named `google-drive` and `onedrive`, enable the templated instances instead. After receiving this image update on an existing install, run `reenable` once so systemd creates the new `default.target` wants symlinks; after that, normal logins should start the mounts automatically.

```bash
systemctl --user daemon-reload
systemctl --user reenable --now rclone@google-drive.service rclone@onedrive.service
```

The units use `--vfs-cache-mode full`, `--dir-cache-time 12h`, bounded VFS cache size/age, transfer/checker limits, API TPS limits, and `--bwlimit 40M` by default to balance desktop responsiveness with cloud API stability. They also load `/usr/share/rclone/kde-trash-excludes.filter`, which explicitly excludes KDE/Freedesktop trash paths such as `.local/share/Trash`, `.Trash-*`, `Trash`, `Trashes`, `Lixeira`, and `$RECYCLE.BIN` so Dolphin/KDE trash folders are neither created through the mount nor synchronized to Google Drive or OneDrive.

Check logs and status with:

```bash
systemctl --user status rclone-google-drive.service rclone-onedrive.service
journalctl --user -u rclone-google-drive.service -u rclone-onedrive.service -f
```

## 9) Post-install health check

This validates staged rpm-ostreed policy and rootless Podman readiness.

---

## 10) Podman automatic cleanup timers

Validate root-scope timer:

```bash
sudo systemctl status podman-system-prune.timer
```

Validate rootless timer:

```bash
systemctl --user status podman-user-prune.timer
```

Run one-shot cleanup manually when needed:

```bash
sudo systemctl start podman-system-prune.service
systemctl --user start podman-user-prune.service
```

Expected policy:

- `flatpak-system-update.timer` and `flatpak-user-update.timer`: `OnBootSec=5m`, `OnUnitActiveSec=15m`.
- `rpm-ostreed-automatic.timer`: `OnBootSec=10m`, `OnUnitActiveSec=45m`.
- `podman-system-prune.timer` and `podman-user-prune.timer`: boot-triggered + every `1d` (`OnUnitActiveSec=1d`).
- Update and prune services run with low scheduling pressure (`Nice=19`, `IOSchedulingClass=idle`) and network-online ordering.

---
