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
| `update`              | Run `topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak`               |
| `update-all`          | Run `topgrade -cy --no-ask-retry --auto-retry 2`                                     |
| `sysup`               | `sudo bootc update`                                                                  |
| `rollback`            | `sudo bootc rollback`                                                                |
| `status-bootc`        | `sudo bootc status`                                                                  |
| `reload-profile`      | `exec $SHELL`                                                                        |
| `ls`, `ll`, `la`      | Enhanced file listings with git status and icons via `eza`                           |
| `lt`, `tree`          | Hierarchical directory trees via `eza --tree`                                        |
| `cat`                 | Syntax-highlighted pagerless and borderless file viewing via `bat -p`                |
| `top`                 | Modern interactive GPU & 32-thread CPU monitor via `btop`                            |
| `fzf`                 | Fuzzy interactive search (integrated with Ctrl+R history, Ctrl+T files, Alt+C cd)    |
| `kargs`               | `rpm-ostree kargs`                                                                   |
| `kargs-edit`          | `sudo rpm-ostree kargs --editor`                                                     |
| `config-diff`         | `sudo ostree admin config-diff`                                                      |
| `status-fw`           | `systemctl status firewalld`                                                         |
| `status-dns`          | `systemctl status systemd-resolved`                                                  |
| `status-kvm`          | `systemctl status virtqemud.socket virtqemud.service`                                |
| `status-tailscale`    | `tailscale status`                                                                   |
| `status-podman`       | `systemctl status podman-auto-update.timer`                                          |
| `status-podman-user`  | `systemctl --user status podman-auto-update.timer`                                   |
| `status-flatpak-system`| `systemctl status flatpak-system-update.timer`                                       |
| `status-flatpak-user` | `systemctl --user status flatpak-user-update.timer`                                  |
| `status-bootc-update` | `systemctl status bootc-fetch-apply-updates.timer`                                   |
| `status-soar`         | `systemctl --user status soar-upgrade-packages.timer`                                |
| `gpu-top`             | Interactive real-time GPU/VRAM engine monitor via `nvtop`                            |
| `gpu-stat`            | Low-level AMD Radeon hardware activity monitor via `radeontop`                       |
| `tmpfiles-system`     | `sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf`        |
| `tmpfiles-user`       | `systemd-tmpfiles --user --create`                                                   |
| `tmpfiles-all`        | Execute both system and user BTRFS NoCOW tmpfiles rules                              |
| `podman-cleanup`      | Clean up unused Podman containers, images, and volumes                               |



---

## 3) Starship, terminal UX, and font rendering

The image installs `jetbrainsmono-nerd-fonts` and `firacode-nerd-fonts` with system-wide subpixel LCD antialiasing (`hintslight`, `rgba=rgb`, `lcddefault`, `embeddedbitmap=false`) and FreeType stem darkening (`FREETYPE_PROPERTIES`) for crisp, macOS-equivalent typography. Electron applications are configured to run natively under Wayland (`ELECTRON_OZONE_PLATFORM_HINT=auto`) to eliminate fractional scaling blur. Konsole is configured by default with the `Kinoite` profile (`TerminalMargin=4`, `LineSpacing=1`), `Kinoite Tokyo Night` color scheme, and background blur using `JetBrainsMono Nerd Font` (with `FiraCode Nerd Font` available).

Test font resolution:

```bash
fc-match monospace
fc-match "JetBrainsMono Nerd Font"
fc-match "FiraCode Nerd Font"

```

Expected: `fc-match monospace` resolves to `JetBrainsMono Nerd Font` (or `FiraCode Nerd Font`), rendering all Starship and modern CLI glyphs crisply.

---

## 4) Essential Services

```bash
sudo systemctl status firewalld
sudo systemctl status systemd-resolved

```

If you use virtualization:

```bash
systemctl status virtqemud.socket virtqemud.service

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
systemctl --user status flatpak-user-update.timer podman-auto-update.timer
podman info --format '{{.Host.Security.Rootless}}'

```

Expected timer policy:

- `bootc-fetch-apply-updates.timer`: active with `OnBootSec=5m`, `OnUnitActiveSec=45m` (starting 5m post-boot, cycling every 45m, 0 delay jitter).
- `flatpak-system-update.timer` and `flatpak-user-update.timer`: active with `OnBootSec=5m`, `OnUnitActiveSec=45m` (starting 5m post-boot, cycling every 45m, 0 delay jitter).
- `podman-auto-update.timer` (system and user session): active with `OnBootSec=5m`, `OnUnitActiveSec=45m` (starting 5m post-boot, cycling every 45m, 0 delay jitter).
- `soar` auto-upgrade timer: active with `OnBootSec=5m`, `OnUnitActiveSec=45m` (starting 5m post-boot, cycling every 45m, 0 delay jitter).
- `podman info` returns `true` when run as the desktop user.

---

## 11) Podman automatic update timer

Validate system and user timers:

```bash
systemctl status podman-auto-update.timer
systemctl --user status podman-auto-update.timer

```

Run a one-shot container auto-update manually when needed:

```bash
sudo systemctl start podman-auto-update.service
systemctl --user start podman-auto-update.service

```

Expected policy:

- Update and prune services run with low scheduling pressure (`Nice=19`, `IOSchedulingClass=idle`).
- Flatpak updates, rclone mounts, `bootc` automatic staging, and Podman updates wait for `network-online.target`, evaluate `ConditionACPower`, and enforce `ExecCondition` resilience against metered connections and captive portals.
- Podman auto-update uses packaged system and user systemd services and requires containers to opt in with the appropriate auto-update labels (`io.containers.autoupdate=image` or `registry`).

---

## 12) Security Hardening and Kernel Module Verification

The image includes declarative security drop-ins:

- **Modprobe Blacklist (`/usr/lib/modprobe.d/60-security-blacklist.conf`)**: Disables obsolete/vulnerable network protocols (`dccp`, `sctp`, `rds`, `tipc`), vulnerable legacy file systems (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`), and obsolete firewire drivers.
- **SSHD Hardening (`/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`)**: Disables root login, enforces `MaxAuthTries 3`, disables X11 forwarding, and sets 5-minute client alive timeouts.
- **Firewall (`/usr/lib/firewalld/zones/tailscale.xml`)**: Tailscale mesh interface (`tailscale0`) is assigned to its own dedicated firewall zone.
- **Sysctl Hardening (`/usr/lib/sysctl.d/90-kernel-tuning.conf`)**: Enforces `dev.tty.ldisc_autoload=0`, `kernel.yama.ptrace_scope=1`, `kernel.kptr_restrict=1`, and `fs.suid_dumpable=0`.

Verify kernel module blacklist:

```bash
modprobe -n -v sctp
# Output: install /bin/true
```

---

## 13) AMD GPU and ROCm Runtime Verification

Systemd user sessions automatically load `/usr/lib/environment.d/60-kinoite-environment.conf`:

```bash
echo $HSA_OVERRIDE_GFX_VERSION
# Expected: 10.3.0

echo $AMD_VULKAN_ICD
# Expected: RADV
```

Verify GPU acceleration and monitoring:

```bash
# Verify VA-API hardware video decode on RX 6600 XT
vainfo

# Verify OpenCL platforms
clinfo

# Interactive GPU engine & VRAM monitor
gpu-top
```

---

