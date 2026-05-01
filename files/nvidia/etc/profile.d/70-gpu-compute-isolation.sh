#!/bin/sh
# Force primary GLES/Vulkan renders to the AMD GPU globally
# Replace pci-0000_XX_XX_X with your actual AMD PCI ID (find via: ls /sys/class/drm/ | grep render)
export DRI_PRIME=pci-0000_0c_00_0
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json