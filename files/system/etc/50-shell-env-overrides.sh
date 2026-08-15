# Force explicit VA-API backend for AMD hardware
export LIBVA_DRIVER_NAME=radeonsi
# Enable Wayland native rendering for Mozilla/Firefox
export MOZ_ENABLE_WAYLAND=1
# Disable sandbox restrictions that break RDD (Remote Data Decoder) processing
export MOZ_DISABLE_RDD_SANDBOX=1
