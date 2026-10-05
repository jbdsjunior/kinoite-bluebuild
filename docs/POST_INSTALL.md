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

| Alias                   | Command/Action                                                                    |
| ----------------------- | --------------------------------------------------------------------------------- |
| `update`                | Run `topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak`            |
| `update-all`            | Run `topgrade -cy --no-ask-retry --auto-retry 2`                                  |
| `sysup`                 | `sudo bootc update`                                                               |
| `rollback`              | `sudo bootc rollback`                                                             |
| `status-bootc`          | `sudo bootc status`                                                               |
| `reload-profile`        | `exec $SHELL`                                                                     |
| `ls`, `ll`, `la`        | Enhanced file listings with git status and icons via `eza`                        |
| `lt`, `tree`            | Hierarchical directory trees via `eza --tree`                                     |
| `cat`                   | Syntax-highlighted pagerless and borderless file viewing via `bat -p`             |
| `top`, `htop`           | Modern interactive GPU & 32-thread CPU monitor via `btop`                         |
| `grep`                  | `grep --color=auto`                                                               |
| `cp`, `mv`, `rm`        | Safe interactive file operations with confirmation (`-i`)                         |
| `fzf`                   | Fuzzy interactive search (integrated with Ctrl+R history, Ctrl+T files, Alt+C cd) |
| `kargs`                 | `rpm-ostree kargs`                                                                |
| `kargs-edit`            | `sudo rpm-ostree kargs --editor`                                                  |
| `config-diff`           | `sudo ostree admin config-diff`                                                   |
| `status-ostree`         | `rpm-ostree status`                                                               |
| `status-fw`             | `systemctl status firewalld`                                                      |
| `status-dns`            | `systemctl status systemd-resolved`                                               |
| `status-kvm`            | `systemctl status virtqemud.socket virtqemud.service`                             |
| `status-tailscale`      | `tailscale status`                                                                |
| `status-podman`         | `systemctl status podman-auto-update.timer`                                       |
| `status-podman-user`    | `systemctl --user status podman-auto-update.timer`                                |
| `status-flatpak-system` | `systemctl status flatpak-system-update.timer`                                    |
| `status-flatpak-user`   | `systemctl --user status flatpak-user-update.timer`                               |
| `status-bootc-update`   | `systemctl status bootc-fetch-apply-updates.timer`                                |
| `status-soar`           | `systemctl --user status soar-upgrade-packages.timer`                             |
| `gpu-top`               | Interactive real-time GPU/VRAM engine monitor via `nvtop`                         |
| `gpu-stat`              | Low-level AMD Radeon hardware activity monitor via `radeontop`                    |
| `tmpfiles-system`       | `sudo systemd-tmpfiles --create`                                                  |
| `tmpfiles-user`         | `systemd-tmpfiles --user --create`                                                |
| `tmpfiles-all`          | `sudo systemd-tmpfiles --create && systemd-tmpfiles --user --create`              |
| `podman-cleanup`        | Clean up unused Podman containers, images, and volumes                            |
| `podman-ps`             | `podman ps -a`                                                                    |
| `distrobox-list`        | `distrobox list`                                                                  |

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
sudo systemd-tmpfiles --create

```

Apply user tmpfiles:

```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf

```

This sets the BTRFS NoCOW (`+C`) attribute on libvirt/GNOME Boxes images, Podman/Distrobox container layers, and rclone cache before heavy multi-gigabyte files are written, preventing disk fragmentation.

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

**Expected image kargs** (declared in `recipes/common-kargs.yml`, delivered through `/usr/lib/bootc/kargs.d/bluebuild-kargs.toml`):

`amd_pstate=active` · `tsc=reliable` · `nowatchdog` · `iommu=pt` · `btusb.enable_autosuspend=n` · `slab_nomerge` · `vsyscall=none`

Verify the deployed boot configuration:

```bash
cat /proc/cmdline
```

> ⚠️ **Bootstrap gap (bootc `kargs.d`):** bootc applies image kargs as a *diff* between the running deployment's `kargs.d` and the new image's. Systems whose first custom deployment predates bootc `kargs.d` support never receive them (empty diff). One-time host fix — applies to the running deployment and becomes the baseline for future upgrades:

```bash
sudo rpm-ostree kargs \
  --append-if-missing=amd_pstate=active \
  --append-if-missing=tsc=reliable \
  --append-if-missing=nowatchdog \
  --append-if-missing=iommu=pt \
  --append-if-missing=btusb.enable_autosuspend=n \
  --append-if-missing=slab_nomerge \
  --append-if-missing=vsyscall=none \
  --delete-if-present=preempt=full \
  --delete-if-present=page_alloc.shuffle=1
```

Rollback (per argument, then reboot): `sudo rpm-ostree kargs --delete-if-present=<karg>`

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

### Unit Parameterization and Runtime Overrides

Operational parameters (`--vfs-cache-max-size`, `--vfs-cache-max-age`, `--buffer-size`, `--poll-interval`, `--tpslimit`) are declared as environment defaults in `/usr/lib/systemd/user/rclone@.service` and tuned per provider. For in-depth architectural justification and cache policy mechanics, see [`docs/TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md#55-subsistema-de-montagens-de-nuvem-fuse-rclone).

### Remote Mappings and Per-Remote Environment Files

Before `ExecStart`, the unit loads the authoritative base configuration `EnvironmentFile=-%h/.config/rclone/env/%i.env` followed by an optional local override file `EnvironmentFile=-%h/.config/rclone/env/%i.local.env`. Default templates from `/usr/share/rclone/env/` are authoritatively synchronized to `~/.config/rclone/env/%i.env` on boot via systemd user tmpfiles (`/usr/share/user-tmpfiles.d/70-rclone-env.conf`), while persistent custom flags, credentials, or overrides can be placed in `~/.config/rclone/env/%i.local.env` without being overwritten on boot.

| Service instance             | Expected rclone remote | Mount point           | Environment configuration file         | System starter template                 |
| ---------------------------- | ---------------------- | --------------------- | -------------------------------------- | --------------------------------------- |
| `rclone@GoogleDrive.service` | `GoogleDrive:`         | `~/Cloud/GoogleDrive` | `~/.config/rclone/env/GoogleDrive.env` | `/usr/share/rclone/env/GoogleDrive.env` |
| `rclone@OneDrive.service`    | `OneDrive:`            | `~/Cloud/OneDrive`    | `~/.config/rclone/env/OneDrive.env`    | `/usr/share/rclone/env/OneDrive.env`    |
| `rclone@<remote>.service`    | `<remote>:`            | `~/Cloud/<remote>`    | `~/.config/rclone/env/<remote>.env`    | Custom user-defined                     |

#### Google Drive Configuration (`GoogleDrive.env`)

Optimized for official desktop client feature parity, rapid cloud synchronization, and local disk cleanliness:

```env
RCLONE_TPSLIMIT=10
RCLONE_TPSLIMIT_BURST=10
RCLONE_TRANSFERS=4
RCLONE_CHECKERS=8
RCLONE_BUFFER_SIZE=16M
RCLONE_VFS_READ_AHEAD=32M
RCLONE_VFS_CACHE_MAX_SIZE=15G
RCLONE_VFS_CACHE_MAX_AGE=24h
RCLONE_VFS_CACHE_MIN_FREE_SPACE=15G
RCLONE_VFS_CACHE_POLL_INTERVAL=1m
RCLONE_VFS_WRITE_BACK=5s
RCLONE_DIR_CACHE_TIME=24h
RCLONE_POLL_INTERVAL=15s
RCLONE_DRIVE_SKIP_GDOCS=true
RCLONE_DRIVE_USE_TRASH=true
RCLONE_DRIVE_CHUNK_SIZE=64M
```

- `RCLONE_DRIVE_USE_TRASH=true`: Files deleted locally are moved to the Google Drive Cloud Trash bin (with 30-day retention), mirroring the official Google Drive desktop client and preventing accidental data loss.
- `RCLONE_POLL_INTERVAL=15s`: Employs Google Drive Changes API with 15-second polling for near real-time synchronization of remote changes made from mobile or web.
- `RCLONE_VFS_WRITE_BACK=5s`: Commits locally saved files to cloud storage within 5 seconds of file close.
- `RCLONE_VFS_CACHE_MAX_AGE=24h` & `RCLONE_VFS_CACHE_MIN_FREE_SPACE=15G`: Prevents local disk exhaustion by evicting cached files inactive for more than 24 hours, and immediately pruning the cache if host free space falls below 15 GB.
- `RCLONE_DRIVE_SKIP_GDOCS=true`: Prevents I/O read errors on native Google Docs/Sheets files that cannot be downloaded without an export conversion. (To expose Docs as clickable web shortcuts like the official client, set `RCLONE_DRIVE_SKIP_GDOCS=false` and `RCLONE_FLAGS="--drive-export-formats link.html"` in `GoogleDrive.local.env`).
- `RCLONE_DRIVE_CHUNK_SIZE=64M`: High throughput chunk size (power of 2) for large file uploads.

#### Microsoft OneDrive Configuration (`OneDrive.env`)

Optimized to avoid Microsoft Graph API HTTP 429 throttling while maintaining identical disk hygiene:

```env
RCLONE_TPSLIMIT=5
RCLONE_TPSLIMIT_BURST=6
RCLONE_TRANSFERS=2
RCLONE_CHECKERS=4
RCLONE_BUFFER_SIZE=16M
RCLONE_VFS_READ_AHEAD=32M
RCLONE_VFS_CACHE_MAX_SIZE=15G
RCLONE_VFS_CACHE_MAX_AGE=24h
RCLONE_VFS_CACHE_MIN_FREE_SPACE=15G
RCLONE_VFS_CACHE_POLL_INTERVAL=1m
RCLONE_VFS_WRITE_BACK=5s
RCLONE_DIR_CACHE_TIME=24h
RCLONE_POLL_INTERVAL=1m
RCLONE_ONEDRIVE_CHUNK_SIZE=50M
RCLONE_ONEDRIVE_DELTA=true
```

- `RCLONE_TPSLIMIT=5` / `RCLONE_TPSLIMIT_BURST=6`: Enforces strict transaction rate limits to eliminate API 429 "Too Many Requests" throttling penalties.
- `RCLONE_POLL_INTERVAL=1m`: Safe polling cadence using the OneDrive Delta API for incremental change detection without triggering rate limits.
- `RCLONE_ONEDRIVE_CHUNK_SIZE=50M`: Optimized upload chunk size (exact multiple of 320 KiB: 160 × 320 KiB = 52.428.800 bytes).
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

The image authoritatively ships `/etc/xdg/baloofilerc` with `$HOME/Cloud` excluded and locked via KConfig immutability (`[$ei]`). This prevents Baloo from scanning cloud mountpoints even if a local user configuration exists. If cloud files were previously indexed before applying this configuration, purge the metadata:

```bash
balooctl6 purge
```

### KDE Dolphin File Deletion and Cloud Trash

In KDE Dolphin, standard deletion attempts to move files into a per-mount trash folder (`.Trash-1000`). To prevent cloud drives from being polluted with hidden trash folders while maintaining safety:

1. The system configures `ShowDeleteCommand=true` in `/etc/xdg/kdeglobals`, which adds the **"Excluir" (Delete)** option directly to Dolphin's context menu.
2. Use **`Shift + Delete`** or right-click and select **"Excluir"** when removing files inside `~/Cloud/`:
   - Files are unlinked immediately via standard POSIX `unlink`, bypassing local `.Trash-1000` directory overhead.
   - On **Google Drive**, rclone automatically redirects deleted files to the **Google Drive Cloud Trash** (`RCLONE_DRIVE_USE_TRASH=true`), where files are retained for 30 days and can be restored from the web UI if needed.
   - On **OneDrive** and other remotes, files are unlinked cleanly without local FUSE trash clutter.

### Monitoring and Status

Quick operational aliases (defined in `60-kinoite-aliases.sh`):

```bash
status-rclone   # systemctl --user status "rclone@*"
logs-rclone     # journalctl --user -u "rclone@*" -f
restart-rclone  # systemctl --user restart "rclone@*"
```

Or target specific remotes:

```bash
systemctl --user status rclone@GoogleDrive.service
journalctl --user -u rclone@GoogleDrive.service -f
```

> [!TIP]
> **Dolphin Thumbnails / Previews**: Because `~/Cloud/` is a FUSE mount, generating thumbnails for folders with heavy videos or RAW images can consume bandwidth and cache space. In Dolphin, configure **Settings → Configure Dolphin → General → Previews** to limit preview file sizes or disable video previews for remote mounts.

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

Memory policy note (`vm.swappiness`):

- Expected value is `150` (aggressive ZRAM) unless a performance tuned profile is active.
- On Fedora 41+ the Plasma power profiles run through `tuned-ppd`: selecting **Performance** activates tuned's `throughput-performance`, which intentionally overrides `vm.swappiness` to `10` and raises `vm.dirty_*` limits at runtime. This is a deliberate KDE power-profile choice, not configuration drift.

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
- Scheduled update timers (`bootc`, Flatpak system/user, Podman auto-update system/user, `soar`) wait for `network-online.target`, evaluate `ConditionACPower`, and enforce network resilience via `/usr/libexec/kinoite/network-guard` against metered connections and captive portals.
- Podman auto-update uses packaged system and user systemd services and requires containers to opt in with the appropriate auto-update labels (`io.containers.autoupdate=image` or `registry`).

---

## 12) Security Hardening and Kernel Module Verification

The image includes declarative security drop-ins:

- **Modprobe Blacklist (`/usr/lib/modprobe.d/60-security-blacklist.conf`)**: Disables obsolete/vulnerable network protocols (`sctp`, `tipc`), vulnerable legacy file systems (`jffs2`, `hfs`, `hfsplus`), and obsolete firewire drivers via `/bin/false` (CIS Benchmark compliance).
- **SSHD Hardening (`/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`)**: Disables root login, enforces key-only authentication (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`), enforces `MaxAuthTries 3`, disables X11 forwarding, and sets 5-minute client alive timeouts.
- **Firewall (`/usr/lib/firewalld/zones/tailscale.xml`)**: Tailscale mesh interface (`tailscale0`) is assigned to its own dedicated firewall zone.
- **Sysctl Hardening (`/usr/lib/sysctl.d/90-kernel-tuning.conf`)**: Enforces `dev.tty.ldisc_autoload=0`, `kernel.kptr_restrict=1`, and `kernel.nmi_watchdog=0` (eliminates CPU watchdog jitter across 32 threads).
- **Peripheral Udev Access (`/usr/lib/udev/rules.d/70-peripherals.rules`)**: Grants unprivileged `uaccess` to USB/HID devices (MCHOSE X9 headset, VXE mouse, BY Tech keyboard, ITE RGB controller).
- **Libvirt Polkit Rules (`/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`)**: Grants passwordless virtualization management strictly to members of the `wheel` administrative group without colliding with upstream RPM files.
- **Resilient Encrypted DNS (`/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`)**: Cloudflare primary DoT resolvers (`cloudflare-dns.com`) with automated DNSSEC integrity and opportunistic TLS.
- **Docker CLI Compatibility (`/etc/containers/nodocker`)**: Suppresses Podman emulation warning for seamless Docker CLI workflows.

Verify kernel module blacklist:

```bash
modprobe -n -v sctp
# Output: install /bin/false
```

---

## 13) AMD GPU and ROCm Runtime Verification

Systemd user sessions automatically load `/usr/lib/environment.d/60-kinoite-environment.conf`:

```bash
echo $HSA_OVERRIDE_GFX_VERSION
# Expected: 10.3.0

vulkaninfo --summary | grep driverName
# Expected: radv
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
