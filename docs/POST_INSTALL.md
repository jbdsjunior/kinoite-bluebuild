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

**Expected image kargs** (Baseline nativa pura do Fedora Kinoite 44):

A imagem opera com os kargs padrão da distribuição (`rhgb quiet root=...`). Todos os recursos do Ryzen Zen 3 (`amd-pstate-epp`), isolamento IOMMU (`CONFIG_IOMMU_DEFAULT_DMA_LAZY=y`), unmerged slab e invariant TSC são compilados nativamente no kernel do Fedora 44 (`7.2.x`). Nenhum karg customizado é injetado.

Verify the deployed boot configuration:

```bash
cat /proc/cmdline
```

Para sanear o host físico e remover quaisquer kargs customizados, obsoletos ou causadores de instabilidade:

```bash
sudo rpm-ostree kargs \
  --delete-if-present=amd_pstate=active \
  --delete-if-present=tsc=reliable \
  --delete-if-present=nowatchdog \
  --delete-if-present=iommu=pt \
  --delete-if-present=btusb.enable_autosuspend=n \
  --delete-if-present=btusb.enable_autosuspend=0 \
  --delete-if-present=slab_nomerge \
  --delete-if-present=vsyscall=none \
  --delete-if-present=preempt=full \
  --delete-if-present=page_alloc.shuffle=1
```

Rollback / inspeção: `rpm-ostree kargs` (retorna apenas a linha padrão da distribuição após reboot).

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

- Expected value is `150` (aggressive ZRAM compaction).
- On Fedora 41+ the Plasma power profiles run through `tuned-ppd`. Declarative symlinks provisioned in `/etc/sysctl.d/` via tmpfiles (`60-sysctl-protection.conf`) ensure that TuneD's native `reapply_sysctl = 1` mechanism enforces `vm.swappiness = 150` and low-latency NVMe dirty ratios even when switching between **Balanced** and **Performance** profiles.

### 10.1 Sanitizing Host Configuration Drift (`/etc`)

To audit local modifications in `/etc` relative to the immutable base image:

```bash
sudo ostree admin config-diff
```

To purge transient systemd cgroup clamps (`/etc/systemd/system.control/`), insecure udev overrides (`70-vxe.rules`), unmanaged YUM repos, and stale installer markers:

```bash
sudo ./scripts/clean-system-drift.sh
```

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
- **Sysctl Hardening & Resilience (`/usr/lib/sysctl.d/90-kernel-tuning.conf`)**: Enforces `kernel.kptr_restrict=1`, `kernel.panic=10`, `kernel.panic_on_oops=1`, `kernel.hardlockup_panic=1`, `kernel.softlockup_panic=1` and `kernel.sysrq=1` (NMI watchdog and lockup detectors actively enabled to guarantee stack trace dump and clean 10s auto-reboot).
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

### 14.0 Hardware Context & Signal Integrity Analysis

| Component / Interface | Hardware Metric (from DMI / SMBIOS / kernel log) | Operational Impact |
| :--- | :--- | :--- |
| **Motherboard & BIOS** | Gigabyte X570 AORUS PRO WIFI, **BIOS F39** (10/28/2025), AGESA ComboV2 1.2.0.x, microcode `0xa201213` | 12+2 VRM phases with Direct Touch heatpipe; pure UEFI support |
| **CPU Architecture** | AMD Ryzen 9 5950X (16C/32T, Zen 3, dual-CCD Vermeer B0/B2) | 105 W TDP / 142 W stock PPT; dual-CCD data fabric crossbar |
| **DRAM Slots A1 / B1 (`DIMM 0`)** | Generic `DDR4 16GB 3200MHz`, **single-rank (1R)** | Secondary trace taps (stubs) in daisy-chain topology |
| **DRAM Slots A2 / B2 (`DIMM 1`)** | KingSpec `KS3200D4R13516G`, 16 GB, **dual-rank (2R)**, DDR4-3200 1.2V JEDEC | Primary physical trace terminations in daisy-chain topology |
| **ECC Support** | **No** — `amd64_edac` driver does not load; DRAM bit-flips are invisible to `rasdaemon` | Integrity verification requires active testing (MemTest86 / `stressapptest`) |
| **Bus Topology** | 2 DIMMs/channel, **3 ranks/channel, mixed kits** (64 GB total) | Heavy electrical load on Zen 3 IMC; requires fixed termination & voltages |

```
Physical Daisy-Chain Memory Trace Architecture:
[ CPU Socket ] ---> [ Slot A1 / DIMM 0: 1R Generic 16GB ] ----> [ Slot A2 / DIMM 1: 2R KingSpec 16GB (PHYSICAL TERMINATION) ]
               ---> [ Slot B1 / DIMM 0: 1R Generic 16GB ] ----> [ Slot B2 / DIMM 1: 2R KingSpec 16GB (PHYSICAL TERMINATION) ]
```

**Daisy-Chain Signal Integrity Rules:**
- On daisy-chain motherboards (like the Gigabyte X570 AORUS PRO), traces travel from the CPU past slot 1 (A1/B1) and terminate physically at slot 2 (A2/B2).
- The heavier dual-rank (2R) modules **must strictly reside in A2 and B2** to absorb signal reflections at the termination boundary.
- Placing 2R modules in A1/B1 and 1R modules in A2/B2 is strictly forbidden: the mismatched capacitive load causes impedance discontinuities, reflection into trace stubs, eye margin collapse, and DQ bus data corruption.

> [!WARNING]
> **Root-Cause Analysis of the 2026-10-05 10:30 Freeze:**
> Kernel oops logs showed corrupted instruction bytes simultaneously fetched from **two distinct cores across separate CCDs** (CPU 17 on CCD1 and CPU 4 on CCD0), with identical memory addresses reading back intact moments later.
> This signature confirms **transient signal corruption along the memory bus or Infinity Fabric crossbar**, caused by leaving IMC voltages (`VSOC`, `VDDG`) and bus terminations (`ProcODT`, `RTT`) on `Auto` with a mixed 4-DIMM 3-rank/channel topology.

> [!TIP]
> **Hardware Upgrade Recommendation (Maximum Headroom):**
> Replacing the 4 mixed DIMMs with a **matched 2×32 GB dual-rank DDR4-3600 CL16/CL18 kit** in slots A2/B2 provides 64 GB with 1 DIMM/channel and rank interleaving, unlocking synchronous FCLK 1800 MHz 1:1 with vastly superior electrical margins and lower latency than any 4-DIMM mixed configuration can achieve.

**Thermal Dynamics & Capacitive Refresh Invariants (4-DIMM High Density):**
- **Joule Dissipation & Voltage Sensitivity ($P \propto V^2$):** With 4 DIMMs packed tightly into adjacent slots, radiant dissipation between sticks is severely restricted. Overvolting DRAM beyond 1.350 V increases thermal output quadratically ($P \propto V^2$).
- **Socket AM4 Copper Plane Coupling (cIOD to Slots A1/A2):** The I/O Die (SoC) on the Ryzen 9 5950X dissipates significant heat into the AM4 socket. Motherboard `Auto` settings typically overvolt `CPU VCORE SOC` to 1.20 V – 1.25 V under XMP loads. This thermal load conducts directly into the internal copper power planes of the motherboard immediately adjacent to memory slots A1 and A2, baking the inner DIMMs from below. Setting a strict manual cap of `1.100 V` on `VSOC` isolates and suppresses this thermal transfer.
- **Capacitive Charge Retention & Refresh Timings (`tRFC` / `tREFI`):** DRAM cells store bits as charge in microscopic trench capacitors. High operating temperatures accelerate charge leakage exponentially. Refresh timings (`tRFC` and `tREFI`) must remain on `Auto` to ensure sufficient recharge cycles and prevent temperature-induced bit flips.
- **Auto Self Refresh (ASR) / Extended Temperature Range:** Enabling ASR in AMD CBS allows the IMC to enforce a 2x refresh cadence when DIMM temperatures approach 85 °C, preserving data integrity under prolonged load.
- **Active Chassis Airflow:** Dedicated chassis airflow over the 4 memory modules is strictly required to prevent heat pockets from forming between the tightly packed modules.

---

### 14.1 Profile A — Stable Baseline Calibration (Step-by-Step)

Follow this precise menu navigation in Gigabyte BIOS F39. Save Profile A to an internal profile slot before adjusting further.

#### Step 0: BIOS Access & Mode Switch
1. Power on or restart the workstation.
2. Tap `<Delete>` repeatedly during the AORUS splash screen to enter BIOS setup.
3. If the interface starts in **Easy Mode**, press `<F2>` to switch to **Advanced Mode**.

---

#### Step 1: `Tweaker` Tab (Clocks, Timings, Bus Terminations & Voltages)

Navigate to the **`Tweaker`** tab using the top navigation bar:

1. **Memory Frequency & Multipliers:**
   - `Extreme Memory Profile (X.M.P.)`: `Profile1` (Enabled as standard default; loads factory DDR4-3200 MT/s rated timings and 1.35 V DRAM baseline).
   - `System Memory Multiplier`: `Auto` (automatically locked to `32.00` by XMP Profile1).
   - `FCLK Frequency`: `1600MHz` (synchronous 1:1 with MEMCLK 1600 MHz).
   - `UCLK DIV1 MODE`: `UCLK==MEMCLK` (forces memory controller to 1600 MHz, avoiding the ~10 ns 2:1 latency penalty).

2. **Advanced Memory Settings (`Tweaker → Advanced Memory Settings`):**
   - `Memory Boot Mode`: `Normal`.
   - `Standard Timing Control`: `Auto` (applies calibrated XMP Profile1 primary timings; refresh parameters `tRFC` and `tREFI` must remain strictly on `Auto` to ensure capacitor recharge cycles).
   - `Command Rate (Cmd2T)`: `Auto` (operates at 1T under GDM).
   - `Gear Down Mode`: `Enabled` (mandatory for address/command bus margins under XMP timings on 4 DIMMs).
   - `Power Down Enable`: `Disabled` (eliminates CKE power-down transitions and memory wakeup latency).
   - `Memory Context Restore`: `Disabled` (enforces full DRAM training on every cold boot; prevents masked marginal timings).
   - `CAD Bus Timing Configuration`:
     - `ClkDrvStr`: `24 Ω`
     - `AddrCmdDrvStr`: `24 Ω`
     - `CsOdtDrvStr`: `24 Ω`
     - `CkeDrvStr`: `24 Ω`
   - `Data Bus Timing Configuration`:
     - `ProcODT`: `40.0 Ω` (sweet spot for 4 DIMMs / 3 ranks with XMP; fallback: `43.6 Ω`).
     - `RttNom`: `Disabled` (or `RZQ/7 (34 Ω)`).
     - `RttWr`: `RZQ/3 (80 Ω)`.
     - `RttPark`: `RZQ/5 (48 Ω)` (fallback: `RZQ/1 (240 Ω)`).

3. **Advanced Voltage Settings (`Tweaker → Advanced Voltage Settings`):**
   - `DRAM Voltage (CH A/B)`: `1.350 V` (verified XMP operating voltage; strict ceiling at `1.350 V` to contain quadratic thermal dissipation $P \propto V^2$; stable undervolt to `1.300 V`–`1.320 V` is permitted if validated).
   - `CPU VCORE SOC`: `1.100 V` (Manual mode; hard ceiling `1.150 V` — strictly prevents motherboard `Auto` from overvolting to 1.20 V–1.25 V, which dumps excessive heat into the AM4 socket copper plane adjacent to memory slots A1/A2).
   - *Technical Note on Sub-Voltages:* Setting `VSOC` to `1.100 V` mandates calibrating `VDDG IOD` to `1.000 V` (keeping $\ge 40$ mV margin below VSOC to prevent Fabric disconnects), `VDDG CCD` to `0.950 V`, and `cLDO VDDP` to `0.900 V` in Step 2 (`Settings → AMD Overclocking`). Never leave VDDG on `Auto` when reducing VSOC.
   - `CPU/VRM Settings`:
     - `Vcore Loadline Calibration`: `Auto`.
     - `VCORE SOC Loadline Calibration`: `Auto` (or `Medium` to prevent voltage droop under heavy memory load).

4. **Advanced CPU Settings (`Tweaker → Advanced CPU Settings`):**
   - `Core Performance Boost`: `Auto` (enables core boost and triggers ACPI `_CPC` table publication).
   - `SVM Mode`: `Enabled` (hardware virtualization for KVM and Podman).
   - `AMD Cool&Quiet function` / `PSS Support`: `Enabled` (required for dynamic frequency states).
   - `Global C-state Control`: `Enabled` (allows deep package sleep and maximum single-thread boost headroom).
   - `Power Supply Idle Control`: `Typical Current Idle` (strictly required on Zen 3 to prevent C6 idle voltage sag and sudden freezes).

---

#### Step 2: `Settings` Tab (I/O, Platform Security, AMD CBS & Overclocking)

Navigate to the **`Settings`** tab:

1. **PCIe & BAR Allocation (`Settings → IO Ports`):**
   - `Above 4G Decoding`: `Enabled` (enables 64-bit PCIe memory address space).
   - `Re-Size BAR Support`: `Auto` or `Enabled` (allocates full 8192 MB contiguous BAR on Radeon RX 6600 XT via SAM).
   - `PCIe Slot Configuration`: `Auto` (runs PCIe Gen4 link speed for GPU and NVMe).

2. **Platform Security & Latency (`Settings → Miscellaneous`):**
   - `AMD CPU fTPM`: `Enabled`.
   - `TSME (Transparent SME)`: `Disabled` (disables real-time hardware DRAM encryption, eliminating a 2–4 ns latency penalty and regaining ~3% memory bandwidth).

3. **AMD CBS Sub-menu (`Settings → AMD CBS`):**
   - `CPU Common Options`: `Global C-state Control = Enabled`.
   - `NBIO Common Options`: `IOMMU = Enabled` (pairs with host `iommu=pt` karg).
   - `UMC Common Options → DDR Common Options → DRAM Controller Configuration` (or directly `DRAM Controller Configuration` depending on AGESA layout):
     - `Auto Self Refresh (ASR)` / `Extended Temperature Range`: `Enabled` (forces 2x refresh cadence when approaching 85 °C to guard against capacitive charge leakage bit flips).
   - `SMU Common Options`:
     - `CPPC`: `Enabled` (mandatory for `amd-pstate-epp` driver).
     - `CPPC Preferred Cores`: `Enabled` (exposes silicon binning to Linux scheduler).
     - `DF Cstates`: `Auto` (if idle freezes persist after Profile A, change to `Disabled`).

4. **AMD Overclocking Sub-menu (`Settings → AMD Overclocking` — Accept the AMD disclaimer):**
   - `DDR and Infinity Fabric Frequency/Timings`:
     - `Infinity Fabric Frequency and Dividers`: `1600 MHz`.
     - `UCLK DIV1 MODE`: `UCLK==MEMCLK`.
     - `VDDG IOD Voltage Control`: `1000 mV` (`1.000 V` — keeps $\ge 40$ mV below VSOC to stabilize the IMC-to-Fabric bridge).
     - `VDDG CCD Voltage Control`: `950 mV` (`0.950 V` — core-to-fabric interconnect voltage).
     - `cLDO VDDP Voltage Control`: `900 mV` (`0.900 V` — standard DDR PHY signaling voltage).
   - `Precision Boost Overdrive`:
     - `Precision Boost Overdrive`: `Auto` (stock 142 W PPT limits for baseline).
     - `Curve Optimizer`: `Disabled` (all offsets set to 0).

---

#### Step 3: `Boot` & `Save & Exit` Tabs

1. **Boot Options (`Boot`):**
   - `CSM Support`: `Disabled` (pure UEFI mode mandatory for Re-Size BAR).
   - `Fast Boot`: `Disabled` (guarantees thorough device and memory bus retraining on every boot).

2. **Save Baseline Profile (`Save & Exit`):**
   - Navigate to `Save Profiles` → Select Slot 1 → Name it: `Profile 1 - Stable Baseline 64GB`.
   - Press `<F10>` (`Save and Exit Setup`) → Confirm `Yes` to reboot.

---

### 14.2 Profile B — Maximum Performance Step (Validated Tuning)

Apply Profile B adjustments **only after Profile A completes §14.3 validation with zero errors**.
Perform one optimization at a time and validate (§14.3) after each step.

#### Phase 1: Secondary Timing Tightening (Beyond Default XMP Profile1)
Profile A already runs factory XMP DDR4-3200 with calibrated voltages. If seeking additional memory latency reduction beyond the SPD profile:

1. In `Tweaker → Advanced Memory Settings → Standard Timing Control`:
   - Set `CAS Latency (tCL)`: `20`
   - Set `tRCDRD`: `20`
   - Set `tRCDWR`: `20`
   - Set `tRP`: `20`
   - Set `tRAS`: `40`
   - Keep `tRC`, `tRFC`, and `tREFI` strictly on `Auto` (manual tightening of refresh parameters in a 4-DIMM mixed topology is strictly prohibited; prevents temperature-induced capacitive refresh retention bit flips on 8Gb ICs).
   - Keep `Gear Down Mode = Enabled`.
2. Save (`F10`) and execute §14.3 validation.
3. *Optional secondary tightening (only if Phase 1 passes 1 h stress testing):*
   - Test `CL18-22-22-42` at `1.350 V`. If training fails or errors appear, immediately revert to `CL20-20-20-40`.

#### Phase 2: Precision Boost Overdrive (PBO) Advanced Calibration
1. Navigate to `Settings → AMD Overclocking → Precision Boost Overdrive`:
   - `Precision Boost Overdrive`: `Advanced`.
   - `PBO Limits`: `Manual`.
   - **Recommended Balanced Limits (Thermal & Sustained Clock Efficiency):**
     - `PPT`: `142 W` (AMD stock envelope; keeps VRM and CPU temperatures $< 70^\circ\text{C}$ while sustaining up to 4.95 GHz single-thread boost).
     - `TDC`: `95 A`
     - `EDC`: `140 A`
   - *High-Throughput Profile (only with premium 280/360mm AIO cooling and load temperatures $< 75^\circ\text{C}$):*
     - `PPT`: `175 W`, `TDC`: `120 A`, `EDC`: `150 A`.
   - **Prohibited:** Never select `Motherboard` limits (395 W) or increase `PBO Scalar` above `1X / Auto`.
   - `Max CPU Boost Clock Override`: `0 MHz` (leave stock; avoid pushing clock offsets that destabilize the curve).

#### Phase 3: Curve Optimizer Per-Core Allocation (CPPC Silicon Hierarchy)
The Ryzen 9 5950X silicon binning on this host demonstrates distinct CCD capabilities via ACPI CPPC:

```
CPPC Silicon Hierarchy (Detected on Host):
CCD0 Preferred Golden/Silver Cores (Scores 211–236):
  Core 0 (CPU 0/16): 236  |  Core 3 (CPU 3/19): 236  |  Core 6 (CPU 6/22): 231  |  Core 5 (CPU 5/21): 226
  Core 4 (CPU 4/20): 221  |  Core 2 (CPU 2/18): 216  |  Core 1 (CPU 1/17): 211  |  Core 7 (CPU 7/23): 206

CCD1 Secondary Cores (Scores 166–201):
  Core 10 (CPU 10/26): 201 | Core 8 (CPU 8/24): 196  | Core 11 (CPU 11/27): 191 | Core 9 (CPU 9/25): 186
  Core 15 (CPU 15/31): 181 | Core 14 (CPU 14/30): 176 | Core 13 (CPU 13/29): 171 | Core 12 (CPU 12/28): 166
```

> [!CAUTION]
> **Inviolable Curve Optimizer Invariant:**
> The top-ranked cores (Core 0, Core 3, Core 6, Core 5) already operate near the minimum voltage threshold required to sustain boost frequencies up to 5.0 GHz.
> Applying negative Curve Optimizer offsets to these cores causes **immediate light-workload kernel oopses** during low-power C-state transitions.

**Per-Core Calibration Procedure:**
- In `Settings → AMD Overclocking → Precision Boost Overdrive → Curve Optimizer`:
  - `Curve Optimizer`: `Per Core`.
  - **CCD0 (Cores 0 to 7):** Set strictly to `0` (neutral, no negative offset).
  - **CCD1 (Cores 8 to 15):** Set to `Negative` with a value of `5` (`-5`).
  - Validate with §14.3. If 100% stable through all stress and idle cycles, CCD1 cores may optionally be tested at `-10`.

---

### 14.3 Validation & Hardware Audit (Mandatory)

Execute the following checks in terminal after booting into Fedora Kinoite:

```bash
# 0. Verify configured memory frequency (3200 MT/s) and topology across all 4 DIMM slots
sudo dmidecode -t memory | grep -E "Locator:|Speed:|Configured Memory Speed:|Part Number:|Rank:"
# Expected: 4 DIMMs active, Speed: 3200 MT/s, Configured Memory Speed: 3200 MT/s

# 1. Verify CPU scaling driver, CPPC active status and boost capability
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver        # Expected: amd-pstate-epp
cat /sys/devices/system/cpu/amd_pstate/status                  # Expected: active
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference # Expected: performance
cat /sys/devices/system/cpu/cpufreq/boost                      # Expected: 1

# 2. Inspect CPPC highest_perf ranking across all 32 hardware threads
paste <(for i in /sys/devices/system/cpu/cpu*/topology/core_id; do echo "CPU $(basename $(dirname $(dirname $i)) | sed 's/cpu//'): core $(cat $i)"; done) \
      <(for i in /sys/devices/system/cpu/cpu*/acpi_cppc/highest_perf; do echo "highest_perf: $(cat $i)"; done) | sort -k6,6nr | head -n 16

# 3. Confirm Smart Access Memory (Re-Size BAR 8192M) and IOMMU Passthrough
journalctl -k -b 0 | grep -E "amdgpu.*BAR=|iommu: Default domain"
# Expected: amdgpu ... Detected VRAM RAM=8176M, BAR=8192M
# Expected: iommu: Default domain type: Passthrough

# 4. Verify kernel resilience parameters
sysctl kernel.panic kernel.panic_on_oops kernel.sysrq
# Expected: kernel.panic = 10, kernel.panic_on_oops = 1, kernel.sysrq = 1

# 5. Stress Testing (Run within a dedicated Fedora toolbox container)
toolbox create -y memtest
toolbox run -c memtest sudo dnf install -y stressapptest stress-ng

# Execute 1-hour active DRAM + Infinity Fabric stress test (allocates ~52 GB RAM)
toolbox run -c memtest stressapptest -s 3600 -M 52000 -W
# Mandatory requirement: Process must conclude with "Status: PASS"

# Execute 30-minute 32-thread CPU verification stress test
toolbox run -c memtest stress-ng --cpu 32 --cpu-method all --verify --timeout 30m --metrics-brief

# 6. Post-Stress Hardware Diagnostic Verification
journalctl -k -b 0 -p 3 --no-pager                             # Must show 0 MCE or oops records
sudo ras-mc-ctl --errors                                       # Confirms rasdaemon log is clean
```

**Offline DRAM Verification (Non-ECC Requirement):**
- Prepare a bootable USB with **PassMark MemTest86** (UEFI signed).
- Execute a minimum of **4 complete passes** across all 64 GB.
- Acceptance criteria: **0 errors**. Any error mandates adjusting `ProcODT` to `43.6 Ω`, increasing `VSOC` to `1.125 V`, or inspecting module seating.

**Emergency Desktop Recovery:**
If a desktop freeze occurs while the kernel is responsive, invoke the Linux SysRq REISUB sequence:
`Alt + SysRq` followed by sequentially pressing: `R` → `E` → `I` → `S` → `U` → `B` (unraw keyboard, terminate, kill, sync filesystem caches to NVMe, remount read-only, clean reboot).

