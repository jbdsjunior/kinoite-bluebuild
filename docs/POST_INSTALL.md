# Post-Installation Guide (Kinoite BlueBuild)

This guide describes post-rebase validation and adjustments for safe operation on an immutable OCI-native system.

---

### (Optional) Verify Cosign signature (recommended)

Project public key: [`cosign.pub`](../cosign.pub).

**Example (AMD)**

```bash
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest

```

## 1) Initial Validation (after reboot)

### System state

```bash
bootc status

```

Expected: the booted deployment points to `ghcr.io/jbdsjunior/kinoite-amd:latest`, and `bootc status` reports the same image reference.

---

## 2) Available Global Aliases

| Alias                 | Command/Action                                                                       |
| --------------------- | ------------------------------------------------------------------------------------ |
| `update`              | Run `topgrade -cy --only system flatpak`                                             |
| `sysup`               | `sudo bootc update`                                                                  |
| `rollback`            | `sudo bootc rollback`                                                                |
| `status-bootc`        | `sudo bootc status`                                                                  |
| `reload-profile`      | `exec $SHELL`                                                                        |
| `kargs`               | `rpm-ostree kargs`                                                                   |
| `kargs-edit`          | `sudo rpm-ostree kargs --editor`                                                     |
| `config-diff`         | `sudo ostree admin config-diff`                                                      |
| `status-fw`           | `sudo systemctl status firewalld`                                                    |
| `status-dns`          | `sudo systemctl status systemd-resolved`                                             |
| `status-kvm`          | `sudo systemctl status libvirtd`                                                     |
| `status-bootc-update` | `systemctl status bootc-fetch-apply-updates.timer`                                   |
| `tmpfiles-system`     | `sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf`        |
| `tmpfiles-user`       | `systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf` |

---

## 3) Starship and terminal font

The image installs `firacode-nerd-fonts` from Terra and ships a fontconfig preference for `FiraCode Nerd Font` / `FiraCode Nerd Font Mono` as the default monospace Nerd Font. This is required for the Starship prompt icons in `/usr/share/starship/starship.toml` to render correctly.

If a terminal profile already pins another font, set it manually to `FiraCode Nerd Font` or `FiraCode Nerd Font Mono` after first login.

```bash
fc-match monospace
fc-match "FiraCode Nerd Font"

```

Expected: both commands resolve to the installed FiraCode Nerd Font family, unless your user profile overrides fontconfig or the terminal pins another font.

---

## 4) Essential Services

```bash
sudo systemctl status firewalld
sudo systemctl status systemd-resolved

```

If you use virtualization:

```bash
sudo systemctl status libvirtd

```

---

## 5) Virtualization (KVM/libvirt)

Permissions are managed declaratively via Polkit rules included in the image. Only users in the `wheel` group can manage libvirt without additional authentication. Add non-administrator users deliberately instead of granting access to every active local session.

---

## 6) BTRFS NoCOW for I/O-heavy workloads

Apply system tmpfiles:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf

```

Apply user tmpfiles:

```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf

```

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
sudo systemctl status firewalld
systemctl status bootc-fetch-apply-updates.timer

```

### Return to stock Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest

```

---

## 9) Rclone cloud mounts for KDE Plasma (optional)

The image ships one dynamic systemd user template for rclone FUSE mounts. Each `rclone@<remote>.service` instance starts with the KDE Plasma graphical session, uses `Type=notify` for perfect initialization timing, and writes logs to the user journal.

| Service instance             | Expected rclone remote | Mount point           | Optional override file                 |
| ---------------------------- | ---------------------- | --------------------- | -------------------------------------- |
| `rclone@GoogleDrive.service` | `GoogleDrive:`         | `~/Cloud/GoogleDrive` | `~/.config/rclone/env/GoogleDrive.env` |
| `rclone@OneDrive.service`    | `OneDrive:`            | `~/Cloud/OneDrive`    | `~/.config/rclone/env/OneDrive.env`    |
| `rclone@<remote>.service`    | `<remote>:`            | `~/Cloud/<remote>`    | `~/.config/rclone/env/<remote>.env`    |

Configure the cloud remotes first. The instance name maps directly to the rclone remote name. To mount a differently named remote or adjust limits, set `RCLONE_REMOTE=<remote>:` in the matching environment file.

```bash
rclone config
mkdir -p ~/.config/rclone/env
printf 'RCLONE_BWLIMIT=40M\n' > ~/.config/rclone/env/GoogleDrive.env
systemctl --user daemon-reload
systemctl --user enable --now rclone@GoogleDrive.service

```

**Tuning Notes:** The template uses `--vfs-cache-mode full` and is optimized for local RAM constraints (`MemoryMax=4G`) and KDE Dolphin compatibility (small `8M` read chunks to prevent thumbnail generation freezes). It also excludes `/.Trash-1000/**` so KDE's per-mount trash directory is not synchronized.

Check logs and status with:

```bash
systemctl --user status rclone@GoogleDrive.service
journalctl --user -u rclone@GoogleDrive.service -f

```

---

## 10) Post-install health check

This validates staged `bootc` policy, maintenance timers, and rootless Podman readiness after the first reboot.

```bash
systemctl status bootc-fetch-apply-updates.timer flatpak-system-update.timer podman-auto-update.timer
systemctl --user status flatpak-user-update.timer
podman info --format '{{.Host.Security.Rootless}}'

```

Expected timer policy:

- `bootc-fetch-apply-updates.timer`: active with `OnBootSec=15m`, `OnUnitActiveSec=24h`.
- `flatpak-system-update.timer` and `flatpak-user-update.timer`: active with `OnBootSec=15m`, `OnUnitActiveSec=24h`.
- `podman-auto-update.timer`: active with scheduled container auto-updates.
- `podman info` returns `true` when run as the desktop user.

---

## 11) Podman automatic update timer

Validate the system timer:

```bash
systemctl status podman-auto-update.timer

```

Run a one-shot container auto-update manually when needed:

```bash
sudo systemctl start podman-auto-update.service

```

Expected policy:

- Update and prune services run with low scheduling pressure (`Nice=19`, `IOSchedulingClass=idle`).
- Flatpak updates, rclone mounts, and `bootc` automatic staging wait for `network-online.target` and evaluate `ConditionACPower`.
- Podman auto-update uses the packaged systemd service and requires containers to opt in with the appropriate auto-update labels.

---
