# Post-Installation: NVIDIA Variant

## Secure Boot (Enrollment MOK)

If Secure Boot is enabled, register the key for NVIDIA kernel modules:

```bash
ujust enroll-secure-boot-key
```

Reboot after enrollment to apply.

## Validate NVIDIA GPU

### Check Driver Installation

```bash
# Verify NVIDIA kernel modules are loaded
lsmod | grep nvidia

# Check driver version
nvidia-smi
```

Expected output: NVIDIA-SMI display with GPU name, driver version, and CUDA version.

### CUDA Validation

```bash
# Install CUDA toolkit if not present
sudo dnf install cuda-toolkit

# Verify CUDA compiler
nvcc --version
```

### Vulkan Validation

```bash
vulkaninfo --summary
```

Expected: `GPU0` should list your NVIDIA device with Vulkan driver support.

### Hardware Acceleration (VA-API/NVDEC)

```bash
# Check VA-API support
vainfo --display drm

# Check NVDEC via FFmpeg
ffmpeg -hide_banner -decoders 2>/dev/null | grep -i nvdec
```

## NVIDIA-Specific Post-Install Steps

1. **Verify GSP firmware** (enabled by default on driver 500+):

   ```bash
   sudo dmesg | grep -i "nvidia.*gsp"
   ```

2. **Check power management** (should be `auto` for runtime PM):

   ```bash
   cat /sys/bus/pci/devices/0000:*/power/control
   ```

3. **Validate NVIDIA container toolkit** (if using containers):

   ```bash
   podman run --rm --device nvidia.com/gpu=all docker.io/nvidia/cuda:latest nvidia-smi
   ```

## Troubleshooting

### Black Screen After Update

Boot into previous deployment:

```bash
sudo bootc rollback
```

### Modules Not Loading

Rebuild initramfs:

```bash
sudo rpm-ostree initramfs --enable
```

Reboot to apply.

### Secure Boot Key Not Enrolled

```bash
mokutil --sb-state
mokutil --list-enrolled
```

If key is missing, re-enroll via `ujust enroll-secure-boot-key` and reboot.
