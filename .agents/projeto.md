meta:
  project: kinoite-bluebuild
  repository_type: immutable-oci-image
  os_host: ubuntu-24.04.3-lts
  runtime_stack:
    - bluebuild
    - bootc
    - rpm-ostree
    - systemd
    - podman
  constraints:
    - all comments and docs in technical english
    - image changes are declarative via recipes and files/system
    - rollback path must be documented for system-level mutations
  hardware_profile:
    cpu: amd_ryzen_9_5950x
    primary_gpu: amd_rx_6600_xt
    secondary_gpu: nvidia_rtx_3080_ti
    memory_gb: 64
  ci_cd:
    workflows_path: .github/workflows
    lint_workflow: lint.yml

# Operational Constraints
- Prefer immutable-safe changes under recipes and files/system.
- Keep topgrade timer cadence at 45 minutes unless explicitly changed.
- Validate shell scripts with `bash -n` before commit.
- Stage rollback instructions for system-level changes.
