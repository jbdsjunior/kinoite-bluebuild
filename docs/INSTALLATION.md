# Installation Guide (Fedora Kinoite OCI / bootc)

This guide documents best practices, disk partitioning strategies, BIOS prerequisites, TPM 2.0 automated unlocking (without repeated boot passphrases), and deployment steps tailored for high-performance AMD workstations running Fedora Kinoite with the `kinoite-amd` custom image.

---

## 1. Hardware Context & Installation Architecture

| Hardware Component | Baseline Configuration | Installation Role |
| :--- | :--- | :--- |
| **Processor (CPU)** | AMD Ryzen 9 5950X (16C/32T, Zen 3, dual-CCD) | fTPM 2.0 security processor, CPPC scheduler, SVM virtualization |
| **Motherboard & BIOS** | Gigabyte X570 AORUS PRO WIFI, BIOS F39 | Pure UEFI, Re-Size BAR, IOMMU grouping, fTPM key storage |
| **Memory (RAM)** | 64 GB DDR4 (4×16 GB, mixed 1R+2R ranks, Profile A) | 32 GB dynamic zram-generator swap (zero disk swap required) |
| **Primary NVMe SSD** | 1 TB NVMe PCIe Gen4 (`nvme0n1`) | Target installation drive (LUKS2 + Btrfs/XFS layout) |
| **Secondary HDD** | 1 TB SATA HDD (`sda`, XFS) | Cold storage and offline backup target (never host active VMs) |
| **Graphics (GPU)** | AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23) | Re-Size BAR 8192M contiguous aperture via SAM |

---

## 2. BIOS Prerequisites (Gigabyte X570 AORUS PRO WIFI)

Before booting the Fedora Kinoite installation media, enter the UEFI setup (`<Delete>` during boot) and confirm the following parameters:

### 2.1 Boot & Security Settings
- **`CSM Support`**: `Disabled` (mandatory for pure UEFI operation and Re-Size BAR).
- **`Secure Boot`**: `Enabled` (Standard mode; required for TPM 2.0 PCR 7 cryptographic binding).
- **`AMD CPU fTPM`**: `Enabled` (uses Zen 3 processor-integrated secure cryptoprocessor).
- **`Fast Boot`**: `Disabled` (ensures memory training and bus device initialization).

### 2.2 I/O Ports & Virtualization
- **`Above 4G Decoding`**: `Enabled`.
- **`Re-Size BAR Support`**: `Auto` or `Enabled` (exposes full 8192 MB VRAM buffer via Smart Access Memory).
- **`SVM Mode`**: `Enabled` (hardware CPU virtualization for KVM and Podman).
- **`IOMMU`**: `Enabled` (in AMD CBS options; exposes PCI passthrough and container device isolation).

### 2.3 Memory & IMC Stability Baseline (Profile A)
- **`Extreme Memory Profile (X.M.P.)`**: `Profile1` (DDR4-3200 MT/s).
- **`FCLK Frequency`**: `1600MHz` (strict 1:1 synchronous with MEMCLK 1600 MHz).
- **`UCLK DIV1 MODE`**: `UCLK==MEMCLK` (forces 1:1 memory controller divider; eliminates 10 ns latency penalty).
- **`CPU VCORE SOC`**: `1.100 V` Manual (hard ceiling 1.150 V; prevents motherboard `Auto` overvoltage to 1.25 V).
- **`DRAM Voltage`**: `1.350 V` Manual (prevents quadratic thermal overshoot $P \propto V^2$ across 4 contiguous DIMM slots).
- **`Power Supply Idle Control`**: `Typical Current Idle` (strictly required on Zen 3 to prevent C6 idle lockups).
- **`CPPC` + `CPPC Preferred Cores`**: `Enabled` (required for `amd-pstate-epp` kernel driver).

---

## 3. Storage Architecture & Filesystem Strategy

### 3.1 Filesystem Analysis for Your Workload

| Workload | Recommended Filesystem | Architectural Justification |
| :--- | :--- | :--- |
| **System Root (`/`)** | **Btrfs (`zstd:1`)** | Native to Fedora Kinoite and OSTree/bootc transactional deployments. Transparent compression reduces read bandwidth. |
| **User Home (`/var/home`)** | **Btrfs (`zstd:1`)** | Shared dynamic pool with `/`. Source code, repositories, and documents compress by 30–40% with negligible CPU overhead. |
| **Containers (`/var/lib/containers`)** | **Btrfs with NoCOW (`+C`)** | Rootless Podman overlayfs operates with zero fragmentation once parent directory has `+C` attribute. |
| **Virtual Machines (KVM/QEMU)** | **Btrfs NoCOW + RAW sparse** *(or dedicated XFS)* | VMs on default CoW suffer catastrophic fragmentation (> 300.000 extents). Mitigate by using RAW sparse images with `cache='none'` and `discard='unmap'` in a NoCOW subvolume. |

### 3.2 Partition Scheme on 1 TB NVMe (`nvme0n1`)

In the Fedora Anaconda installer, select **Custom Partitioning (Advanced)** with the following layout:

```
[ 1 TB NVMe PCIe Gen4 SSD: /dev/nvme0n1 ]
├── /dev/nvme0n1p1: 1024 MiB | /boot/efi | Format: EFI System Partition (vfat)
├── /dev/nvme0n1p2: 2048 MiB | /boot     | Format: ext4 (unencrypted, for GRUB & kernel signatures)
└── /dev/nvme0n1p3: ~950 GiB | LUKS2 Encrypted Volume (aes-xts-plain64)
    │
    └── [ Btrfs Encrypted Volume Pool ]
        ├── Subvolume: root    mount: /                      [options: compress=zstd:1]
        ├── Subvolume: home    mount: /var/home              [options: compress=zstd:1]
        └── Subvolume: vms     mount: /var/lib/libvirt/images [options: nodatacow]
```

> [!NOTE]
> **Zero Disk Swap:** Do not create a physical swap partition on the NVMe. The system automatically provisions a **32 GB compressed RAM swap device** (`/dev/zram0`) via `systemd-zram-generator` with `vm.swappiness = 150`, avoiding NVMe write wear and eliminating swap I/O latency.

---

## 4. TPM 2.0 Automated Unlock (No Password Prompt on Boot)

### 4.1 How It Works
Modern Fedora utilizes native `systemd-cryptenroll` to bind the LUKS2 encrypted root drive to the **fTPM 2.0 processor** embedded in the AMD Ryzen 9 5950X:
1. When booting through UEFI with Secure Boot active, the firmware evaluates platform measurements.
2. If signatures and Secure Boot state match, the fTPM unseals the volume decryption key directly to `systemd-cryptsetup` in the initramfs.
3. The disk unlocks in less than 50 milliseconds, booting seamlessly to the KDE Plasma graphical login.
4. If the NVMe drive is removed or placed into an unauthorized machine, the TPM refuses to release the key, and the system prompts for the manual recovery passphrase.

---

### 4.2 PCR Selection: Why PCR 7 is Mandatory
- **PCR 7**: Measures **Secure Boot state** and the UEFI certificate database (`PK`, `KEK`, `db`). It remains **100% stable across normal kernel updates**, `bootc` image upgrades, and initramfs regenerations.
- **PCR 4 & PCR 8**: Measure the bootloader binary and kernel command-line. In an immutable/bootc environment, binding to PCR 4 or 8 breaks the auto-unlock on every single kernel update, repeatedly forcing manual passphrase prompts.

> [!IMPORTANT]
> Bind **exclusively to PCR 7** (`--tpm2-pcrs=7`) to guarantee seamless boots without maintenance overhead.

---

### 4.3 Step-by-Step Configuration (Post-Install)

Execute the following commands after completing the standard Fedora Kinoite installation:

#### Step 1: Generate an Offline Recovery Key
Before enrolling the TPM, generate an alphanumeric recovery key to prevent accidental lockouts:

```bash
# Locate your encrypted partition (e.g., /dev/nvme0n1p3)
sudo systemd-cryptenroll --recovery-key /dev/nvme0n1p3
```
*Securely copy or print the 48-character recovery key and store it offline.*

#### Step 2: Enroll the fTPM 2.0 with PCR 7
```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
```
*Enter your existing disk passphrase when prompted to authorize the new keyslot.*

#### Step 3: Verify the Enrolled Keyslots
```bash
sudo cryptsetup luksDump /dev/nvme0n1p3
```
*Expected: Keyset displays your primary Passphrase in Keyslot 0, the Recovery Key in Keyslot 1, and `systemd-tpm2` in Keyslot 2.*

#### Step 4: Ensure `/etc/crypttab` Enables TPM2 Auto-Unlock
Open `/etc/crypttab` and ensure the `tpm2-device=auto` option is present:

```text
luks-<UUID> UUID=<UUID> none discard,tpm2-device=auto
```

#### Step 5: Regenerate the Initramfs
```bash
sudo dracut -f --regenerate-all
```

Reboot the workstation. The system will unlock the encrypted NVMe automatically and launch straight into the KDE Plasma desktop.

---

### 4.4 Handling Future Motherboard BIOS Updates
When updating the motherboard BIOS (e.g., updating from F39 to F40 in the future):
1. The BIOS flash resets the fTPM configuration registers.
2. On the **first boot after a BIOS update**, the TPM will not unseal the key. Simply type your manual Passphrase (or Recovery Key) once at the boot prompt.
3. Once booted into the desktop, re-enroll the TPM to seal with the new BIOS measurements:
   ```bash
   sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
   sudo dracut -f --regenerate-all
   ```

---

## 5. Transitioning to the Custom OCI Image (`bootc`)

Once the base system is installed and TPM auto-unlock is confirmed:

### 5.1 Switch to the Repository Image
Execute the atomic transition to the hardened, tuned image:

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
```

Wait for the container layer download and deployment verification. Once finished, reboot:

```bash
systemctl reboot
```

### 5.2 Validate the Deployed System
After rebooting into the custom image:

```bash
bootc status
```
*Expected: The booted deployment displays `ghcr.io/jbdsjunior/kinoite-amd:latest`.*

---

## 6. Post-Installation Optimization & Maintenance

Run the unified, declarative system maintenance utility to enforce sysctl parameters, Btrfs chunk reclamation, and NoCOW policies across user and system directories:

```bash
# Full system optimization and Btrfs maintenance:
sys-optimize
```

For ongoing operations, troubleshooting, and advanced hardware validation, continue to [`POST_INSTALL.md`](POST_INSTALL.md).
