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
| `top`, `htop`        | Modern interactive GPU & 32-thread CPU monitor via `btop`                            |
| `grep`                | `grep --color=auto`                                                                  |
| `cp`, `mv`, `rm`      | Safe interactive file operations with confirmation (`-i`)                            |
| `fzf`                 | Fuzzy interactive search (integrated with Ctrl+R history, Ctrl+T files, Alt+C cd)    |
| `kargs`               | `rpm-ostree kargs`                                                                   |
| `kargs-edit`          | `sudo rpm-ostree kargs --editor`                                                     |
| `config-diff`         | `sudo ostree admin config-diff`                                                      |
| `status-ostree`       | `rpm-ostree status`                                                                  |
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
| `podman-ps`           | `podman ps -a`                                                                       |
| `distrobox-list`      | `distrobox list`                                                                     |



---

## 3) Starship, terminal UX, and font rendering

The image installs `jetbrainsmono-nerd-fonts` and `firacode-nerd-fonts` with system-wide subpixel LCD antialiasing (`hintslight`, `rgba=rgb`, `lcddefault`, `embeddedbitmap=false`, `autohint=false`), FreeType stem darkening (`FREETYPE_PROPERTIES`), and fontconfig aliases mapping macOS and web system fonts (`system-ui`, `-apple-system`, `BlinkMacSystemFont`, `ui-sans-serif`, `SF Pro Text`, `SF Pro Display`, `SF Pro`, `Segoe UI`) to `Inter Variable`, and code fonts (`monospace`, `ui-monospace`, `Menlo`, `Monaco`, `SF Mono`, `SFMono`, `SFMono-Regular`, `Cascadia Code`, `Cascadia Mono`) to `JetBrainsMono Nerd Font` and `FiraCode Nerd Font`. Electron applications run natively under Wayland (`ELECTRON_OZONE_PLATFORM_HINT=auto`) to eliminate fractional scaling blur. Konsole is configured by default with the `Kinoite` profile (`TerminalMargin=4`, `LineSpacing=1`, smooth blinking cursor, link underlines, full URL/path word selection), `Kinoite Tokyo Night` color scheme, and background blur.

Test font resolution:

```bash
fc-match sans-serif
fc-match system-ui
fc-match -- "-apple-system"
fc-match "SF Pro Text"
fc-match monospace
fc-match ":family=ui-monospace"
```

Expected: `fc-match sans-serif`, `fc-match system-ui`, `fc-match -- "-apple-system"`, and `fc-match "SF Pro Text"` resolve to `Inter Variable`, and `fc-match monospace` and `fc-match ":family=ui-monospace"` resolve to `JetBrainsMono Nerd Font`, rendering all Starship and modern CLI glyphs crisply.

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

This sets the BTRFS NoCOW (`+C`) attribute on libvirt/GNOME Boxes images, Podman/Distrobox container layers, rclone cache, and local LLM model caches (`~/.ollama/models`, `~/.cache/huggingface`) before heavy multi-gigabyte files are written, preventing disk fragmentation.

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

The image ships a modernized, dynamic systemd user template (`rclone@<remote>.service`) for rclone FUSE mounts. Each instance starts with the KDE Plasma graphical session, uses `Type=notify` for accurate mount readiness, and logs directly to the systemd user journal.

### Modernized Unit Architecture & Parameterization

Default resource and performance parameters in `[Service]` are parametrized and interpolated directly into `ExecStart`:

- `RCLONE_BUFFER_SIZE=16M` (interpolated into `--buffer-size`)
- `RCLONE_TRANSFERS=4` (interpolated into `--transfers`)
- `RCLONE_CHECKERS=8` (interpolated into `--checkers`)
- `RCLONE_TPSLIMIT=10` (interpolated into `--tpslimit`)
- `RCLONE_TPSLIMIT_BURST=10` (interpolated into `--tpslimit-burst`)
- `RCLONE_VFS_READ_AHEAD=32M` (interpolated into `--vfs-read-ahead`)
- `RCLONE_VFS_READ_CHUNK_SIZE_LIMIT=512M` (interpolated into `--vfs-read-chunk-size-limit`)
- `RCLONE_BWLIMIT=0` (interpolated into `--bwlimit`)
- Clean teardown: `ExecStop=-/usr/bin/fusermount3 -uz ${RCLONE_MOUNT}` and `ExecStopPost=-/usr/bin/rmdir --ignore-fail-on-non-empty ${RCLONE_MOUNT}`
- Extra flags: `$RCLONE_FLAGS` is appended to `ExecStart` for any custom arguments.

### Remote Mappings and Per-Remote Environment Files

Before `ExecStart`, the unit loads `EnvironmentFile=-%h/.config/rclone/env/%i.env`. Starter templates from `/usr/share/rclone/env/` are automatically provisioned to `~/.config/rclone/env/` on login via systemd user tmpfiles (`/usr/share/user-tmpfiles.d/70-rclone-env.conf`), or manually via the `tmpfiles-user` alias.

| Service instance             | Expected rclone remote | Mount point           | Environment configuration file         | System starter template                |
| ---------------------------- | ---------------------- | --------------------- | -------------------------------------- | -------------------------------------- |
| `rclone@GoogleDrive.service` | `GoogleDrive:`         | `~/Cloud/GoogleDrive` | `~/.config/rclone/env/GoogleDrive.env` | `/usr/share/rclone/env/GoogleDrive.env` |
| `rclone@OneDrive.service`    | `OneDrive:`            | `~/Cloud/OneDrive`    | `~/.config/rclone/env/OneDrive.env`    | `/usr/share/rclone/env/OneDrive.env`    |
| `rclone@<remote>.service`    | `<remote>:`            | `~/Cloud/<remote>`    | `~/.config/rclone/env/<remote>.env`    | Custom user-defined                    |

#### Google Drive Configuration (`GoogleDrive.env`)

Optimized for Google Drive API quotas and safety:

```env
RCLONE_TPSLIMIT=10
RCLONE_TPSLIMIT_BURST=10
RCLONE_TRANSFERS=4
RCLONE_CHECKERS=8
RCLONE_BUFFER_SIZE=16M
RCLONE_VFS_READ_AHEAD=32M
RCLONE_DRIVE_SKIP_GDOCS=true
RCLONE_DRIVE_USE_TRASH=true
RCLONE_DRIVE_CHUNK_SIZE=64M
```

- `RCLONE_DRIVE_SKIP_GDOCS=true`: Prevents I/O read errors on native Google Docs/Sheets files that cannot be downloaded without an export conversion.
- `RCLONE_DRIVE_USE_TRASH=true`: Sends deleted files to Google Drive web trash rather than permanently deleting them immediately.
- `RCLONE_DRIVE_CHUNK_SIZE=64M`: Improves upload throughput for large files.

#### Microsoft OneDrive Configuration (`OneDrive.env`)

Optimized to avoid Microsoft Graph API HTTP 429 throttling:

```env
RCLONE_TPSLIMIT=5
RCLONE_TPSLIMIT_BURST=6
RCLONE_TRANSFERS=2
RCLONE_CHECKERS=4
RCLONE_BUFFER_SIZE=16M
RCLONE_VFS_READ_AHEAD=32M
RCLONE_ONEDRIVE_CHUNK_SIZE=50M
RCLONE_ONEDRIVE_DELTA=true
```

- `RCLONE_TPSLIMIT=5` / `RCLONE_TPSLIMIT_BURST=6`: Enforces strict transaction rate limits to eliminate API 429 "Too Many Requests" throttling penalties.
- `RCLONE_TRANSFERS=2` / `RCLONE_CHECKERS=4`: Conservative concurrency to maintain stable connection pools.
- `RCLONE_ONEDRIVE_CHUNK_SIZE=50M`: Optimized upload chunk size (must be a multiple of 320 KiB).
- `RCLONE_ONEDRIVE_DELTA=true`: Uses the OneDrive delta API for fast incremental change detection.

### Quick Setup

1. Configure your remote in rclone (name must match the service instance name, e.g. `GoogleDrive` or `OneDrive`):

```bash
rclone config
```

2. Ensure environment templates are provisioned in user home:

```bash
tmpfiles-user
```

3. Enable and start the user mount service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now rclone@GoogleDrive.service
# or for OneDrive:
systemctl --user enable --now rclone@OneDrive.service
```

### Baloo File Indexer Exclusion (Crucial)

KDE Baloo file indexer must **never** index cloud FUSE mountpoints (`$HOME/Cloud`). If Baloo scans cloud mounts, it attempts to read and index all remote files, triggering massive network bandwidth usage, local CPU spikes, and rapid API quota exhaustion / temporary account bans from Google and Microsoft.

The image automatically ships `/etc/xdg/baloofilerc` with `$HOME/Cloud` excluded by default. For existing users or active sessions, apply the exclusion to your user configuration and purge any previously indexed metadata:

```bash
kwriteconfig6 --file baloofilerc --group General --key "exclude folders[\$e]" "$HOME/Cloud"
balooctl6 purge
```

### KDE Dolphin Trash Recommendation (Shift + Delete)

In KDE Dolphin, normal deletion moves files into a local or per-mount trash folder (`.Trash-1000`). Because `/.Trash-1000/**` is intentionally excluded in the rclone mount configuration to prevent sync loops and quota waste, standard trash operations on cloud mounts can be slow or trigger filesystem errors.

**Recommendation:** Always use **`Shift + Delete`** when removing files in `~/Cloud/`:
- On **Google Drive**: When `Shift + Delete` is invoked, rclone receives the delete call and moves the item into Google Drive's cloud trash bin because `RCLONE_DRIVE_USE_TRASH=true` is enabled.
- On **OneDrive**: The file is removed remotely without local FUSE trash overhead.

### Monitoring and Status

Check service status and follow logs:

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
- Scheduled update timers (`bootc`, Flatpak system/user, Podman auto-update system/user, `soar`) wait for `network-online.target`, evaluate `ConditionACPower`, and enforce `ExecCondition` resilience against metered connections and captive portals.
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

