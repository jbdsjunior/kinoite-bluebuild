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
- **Sysctl Hardening & Resilience (`/usr/lib/sysctl.d/90-kernel-tuning.conf`)**: Enforces `kernel.kptr_restrict=1`, `kernel.panic=10`, `kernel.panic_on_oops=1` and `kernel.sysrq=1` (`dev.tty.ldisc_autoload=0` is already the Fedora 44 default; the NMI watchdog is disabled by the `nowatchdog` karg).
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

---

## 14) BIOS Calibration — Gigabyte X570 AORUS PRO WIFI + Ryzen 9 5950X + 64 GB DDR4

### 14.0 Detected hardware (source of every value below)

| Item | Value (from `udevadm info -e` / DMI / kernel log) |
| :--- | :--- |
| Board / BIOS | X570 AORUS PRO WIFI, **F39** (10/28/2025), AGESA ComboV2 1.2.0.x, microcode `0xa201213` |
| A1 / B1 (`DIMM 0`) | Generic `DDR4 16GB 3200MHz`, **single-rank (1R)** |
| A2 / B2 (`DIMM 1`) | KingSpec `KS3200D4R13516G`, 16 GB, **dual-rank (2R)**, DDR4-3200 1.2V JEDEC |
| ECC | **No** — `amd64_edac` does not load; DRAM errors are invisible to `rasdaemon` |
| Topology | 2 DIMMs/channel, **3 ranks/channel, mixed kits** — hardest load for the Zen 3 IMC |

**Slot Placement Verification (Daisy-Chain Trace Topology):**
- **Channel A:** Slot A1 = 1R (Generic 16 GB), Slot A2 = 2R (KingSpec KS3200D4R13516G)
- **Channel B:** Slot B1 = 1R (Generic 16 GB), Slot B2 = 2R (KingSpec KS3200D4R13516G)
*Signal integrity rationale:* On daisy-chain motherboards (such as the Gigabyte X570 AORUS PRO), slots A2 and B2 are the physical termination ends of the memory traces. Placing the heavier dual-rank (2R) modules in A2 and B2 provides clean impedance termination, minimizing signal reflections back into trace stubs. Inverting placement (2R in A1/B1 and 1R in A2/B2) severely degrades signal eye margins and triggers data bus bit flips.

> [!WARNING]
> Root-cause note for the 2026-10-05 10:30 freeze: the oops dumps showed corrupted kernel instruction bytes read from **two different cores on both CCDs** (CPU 17 / CCD1 and CPU 4 / CCD0), while the same `.text` read back intact moments later. That pattern is **transient corruption in the memory/fabric path**, not a single bad core nor a permanently bad DRAM cell. Top suspect: mixed 1R+2R 4-DIMM topology with `Auto` VSOC/ProcODT. Secondary: any PBO/Curve Optimizer offset; idle C6 voltage sag.

> [!TIP]
> **Maximum performance *and* stability fix (hardware):** replace the 4 mixed DIMMs with a **matched 2×32 GB dual-rank DDR4-3600 CL16/CL18 kit** in A2/B2. Same 64 GB, 1 DIMM/channel with rank interleaving, FCLK 1800 1:1 — lower latency, higher bandwidth and a far larger stability margin than any BIOS tuning of the current set can deliver.

Menu labels below follow F3x builds; minor wording may differ. Change one block at a time, `F10` to save, and validate (§14.3) before the next block.

### 14.1 Profile A — Stable baseline (apply now)

**CPU & power** (`Tweaker → Advanced CPU Settings` and `Settings → AMD CBS`)

| Setting | Value | Why |
| :--- | :--- | :--- |
| Precision Boost Overdrive | `Auto` (stock 142 W PPT) | No extra voltage/current while stability is unproven |
| Curve Optimizer | `Disabled` (all cores 0) | Negative CO is the #1 cause of random Zen 3 oopses at light load |
| Core Performance Boost | `Auto` | Required for boost **and** for the BIOS to publish ACPI `_CPC` |
| AMD Cool&Quiet function | `Enabled` | Disabling it on Gigabyte also removes P-state/CPPC tables |
| Global C-state Control | `Enabled` | Required for idle power and boost headroom |
| Power Supply Idle Control | `Typical Current Idle` | Prevents C6 idle voltage sag (classic Zen 3 idle freeze) |
| CPPC / CPPC Preferred Cores (`AMD CBS → NBIO Common Options → SMU Common Options`) | `Enabled` / `Enabled` | Without them: `amd_pstate: the _CPC object is not present in SBIOS` and no boost |
| CPU Vcore Loadline Calibration | `Auto` | Avoid `Extreme/Turbo` overshoot |
| SMT Mode | `Auto` | 32 threads |

**Memory, Voltages & Infinity Fabric** (`Tweaker`, `Tweaker → Advanced Memory Settings`, `Settings → AMD CBS → UMC Common Options`, `Settings → AMD Overclocking`)

| Setting | Value | Why |
| :--- | :--- | :--- |
| Extreme Memory Profile (X.M.P.) | `Disabled` | Kits differ; XMP of one kit is not valid for the other |
| System Memory Multiplier | `32.00` (DDR4-3200) | Both kits rated 3200 |
| Timings | `Auto` (SPD/JEDEC ≈ 22-22-22-52) | Slowest common denominator for mixed kits |
| Infinity Fabric Frequency (FCLK) | `1600 MHz` | Synchronous 1:1 with MEMCLK 1600 |
| UCLK DIV1 MODE | `UCLK==MEMCLK` | Avoid 2:1 latency penalty |
| DRAM Voltage (CH A/B) | `1.350 V` | +150 mV margin over 1.2 V JEDEC; standard safe DDR4 value |
| CPU VCORE SOC | `1.100 V` (hard ceiling `1.150 V`) | Feeds the IMC driving 3 ranks/channel |
| VCORE SOC Loadline Calibration | `Auto` / `Medium` | Stable SOC under load steps |
| VDDG IOD (`AMD Overclocking → DDR/FCLK`) | `1.000 V` (1000 mV) | Stabilizes memory controller/fabric interconnect (keep $\ge 40$ mV below VSOC) |
| VDDG CCD (`AMD Overclocking → DDR/FCLK`) | `0.950 V` (950 mV) | Stabilizes core-to-fabric interconnect |
| cLDO VDDP (`AMD Overclocking → DDR/FCLK`) | `0.900 V` (900 mV) | Standard DRAM PHY signaling voltage |
| ProcODT | `40.0 Ω` (fallback `43.6 Ω` or `36.9 Ω`) | Typical sweet spot for 4 DIMMs / mixed ranks |
| RttNom / RttWr / RttPark | `Disabled` / `RZQ/3 (80 Ω)` / `RZQ/5 (48 Ω)` | Optimal bus termination for 4 DIMMs (fallback: RttPark `RZQ/1 (240 Ω)`) |
| CAD_BUS Clk / AddrCmd / CsOdt / Cke DrvStr | `24 Ω` / `24 Ω` / `24 Ω` / `24 Ω` | Standard drive strength for daisy-chain 4-DIMM traces |
| Gear Down Mode | `Enabled` | Command-bus margin with 4 DIMMs (mandatory) |
| Cmd2T | `Auto` (1T with GDM) | Fast command rate under GDM |
| Power Down Enable | `Disabled` | Removes DRAM power-down transitions as an instability source |
| Memory Context Restore | `Disabled` | Forces full retraining every boot; no masked marginal training |

**PCIe, GPU, Boot & Thermal**

| Setting | Path | Value | Why |
| :--- | :--- | :--- | :--- |
| CSM Support | `Boot` | `Disabled` | Pure UEFI mode required for Re-Size BAR |
| Fast Boot | `BIOS` | `Disabled` | Guarantees full device and memory enumeration on every boot |
| Above 4G Decoding | `Settings → IO Ports` | `Enabled` | Enables 64-bit PCIe BAR allocation |
| Re-Size BAR Support | `Settings → IO Ports` | `Auto` / `Enabled` | Full 8 GB VRAM BAR (`BAR=8192M`) on Radeon RX 6600 XT via SAM |
| SVM Mode | `Tweaker → Advanced CPU Settings` | `Enabled` | Hardware virtualization for KVM and Podman |
| IOMMU | `Settings → Miscellaneous` / `AMD CBS` | `Enabled` | Device isolation and passthrough via `iommu=pt` |
| PCIe Slot Configuration | `Settings → IO Ports` | `Auto` (Gen4) | Gen4 link speed for GPU and NVMe SSD |
| PCH Fan Profile | `Smart Fan 5` | `Silent` | Keeps X570 chipset cool while eliminating high-pitch fan noise |

**Escalation only if freezes persist with Profile A:** `DF Cstates = Disabled` (`AMD CBS → NBIO Common Options → SMU Common Options`; ≈ +10 W idle), then ProcODT `43.6 Ω`, then VSOC `1.125 V`. As a last resort drop to DDR4-2933 / FCLK 1467 — or remove the 1R pair (A1/B1) and run 32 GB 2R to confirm the topology is the cause.

### 14.2 Profile B — Performance step (only after Profile A passes §14.3 cleanly)

Apply one item at a time and re-run §14.3 after each:

1. **PBO with stock limits:** `Precision Boost Overdrive = Enabled`, `PBO Limits = Auto`, `Scalar = Auto`. Never `Motherboard` limits.
2. **Curve Optimizer per core**, never all-core: start at `-5` only on the cores reported as *non-preferred*, keep preferred cores (highest `acpi_cppc/highest_perf`) at `0`.
3. **Memory timings:** `CL20-20-20-40` at 1.35 V → validate → optionally `CL18-22-22-42`. Do **not** raise frequency above 3200 with this mixed set.

Rollback at any point: `F7` (Load Optimized Defaults) and re-apply Profile A, or `Save & Exit → Save Profiles` (store Profile A as profile 1 before starting Profile B).

### 14.3 Validation (mandatory after every BIOS change)

```bash
# Runtime state
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver        # amd-pstate-epp
cat /sys/devices/system/cpu/amd_pstate/status                  # active
cat /sys/devices/system/cpu/cpufreq/boost                      # 1
journalctl -k -b 0 | grep -E "amdgpu.*BAR=|iommu: Default domain"   # BAR=8192M, Passthrough
sysctl kernel.panic kernel.panic_on_oops kernel.sysrq          # 10 / 1 / 1

# Stress (immutable host: run tools inside a toolbox)
toolbox create -y stab
toolbox run -c stab sudo dnf install -y stressapptest stress-ng
toolbox run -c stab stressapptest -s 3600 -M 52000 -W          # 1 h memory + fabric stress, must end "Status: PASS"
toolbox run -c stab stress-ng --cpu 32 --cpu-method all --verify --timeout 30m --metrics-brief

# Evidence after stress
journalctl -k -b 0 -p 3 --no-pager                             # no MCE / oops
sudo ras-mc-ctl --errors                                       # no new MCE records
```

Offline DRAM test (only way to see DRAM errors on non-ECC): boot **MemTest86** (UEFI, Secure Boot-signed USB) and require **≥ 4 full passes with 0 errors**.

Emergency (desktop frozen, kernel alive): `Alt + SysRq` then `R E I S U B` — unraw keyboard, terminate, kill, sync, remount read-only, reboot.
