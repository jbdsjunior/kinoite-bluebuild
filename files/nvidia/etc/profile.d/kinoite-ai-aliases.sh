#!/bin/bash
# NVIDIA-specific aliases for AI/compute monitoring.
alias gpu-display='watch -n 1 nvtop'
alias gpu-compute='nvidia-smi -l 1'
alias ai-logs='journalctl -u podman -f'
alias mps-status='echo "get_default_active_thread_percentage" | nvidia-cuda-mps-control'
