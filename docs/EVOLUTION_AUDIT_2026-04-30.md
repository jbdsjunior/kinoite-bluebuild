# Evolution Audit — 2026-04-30

## Scope
- BlueBuild recipes in `recipes/`
- CI/CD workflows in `.github/workflows/`
- System payload under `files/system/`
- Operational scripts and docs

## Findings and recommended actions

### 1) Immutable architecture / BlueBuild layering
- **Finding:** `recipes/common-repos.yml` enables several third-party repositories by default (`terra`, browser vendors, VS Code). This increases supply-chain exposure for every build variant.
- **Risk:** Medium.
- **Recommendation:** Keep only required repos enabled by default and move optional repos behind variant-specific modules.
- **Safer approach:** Native Fedora/uBlue repos first; external repos only when required by explicit package list.

### 2) CI/CD supply-chain posture
- **Finding:** Some workflows used older checkout actions.
- **Change applied:** Updated `actions/checkout` to `@v6` in `check-updates.yml` and `security-scan.yml` for Node 24 compatibility.
- **Risk:** Low.
- **Recommendation:** Pin third-party actions to immutable SHAs where possible.

### 3) YAML lint signal quality
- **Finding:** Default `yamllint` rules generated false positives for GitHub Actions syntax (`on:` truthy/document-start).
- **Change applied:** Added `.yamllint` policy tuned for this repository and wired lint workflow to use it.
- **Risk:** Low.
- **Recommendation:** Keep rules strict for correctness and relaxed only for known ecosystem syntax constraints.

### 4) Script safety (`setup-kvm.sh`)
- **Finding:** user existence was not validated before `usermod` in previous state.
- **Change applied:** explicit `id "$TARGET_USER"` guard before mutation.
- **Risk:** Low.
- **Recommendation:** Add a dry-run mode (`--check`) in a future PR.

### 5) I/O tmpfiles policy integrity
- **Finding:** `60-io-tuning-system.conf` had formatting risk (missing trailing newline in prior revision).
- **Change applied:** normalized file ending.
- **Risk:** Low.

### 6) GPU hybrid tuning and container inference readiness
- **Finding:** Current kargs include AMD IOMMU and nested KVM; no explicit CDI verification automation for NVIDIA toolkit.
- **Risk:** Medium for inference workloads.
- **Recommendation:** Add a post-install verification script for:
  - `nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`
  - `podman run --rm --device nvidia.com/gpu=all ... nvidia-smi`

### 7) rpm-ostreed policy
- **Finding:** `AutomaticUpdatePolicy=stage` is aligned with immutable desktop best practice.
- **Risk:** Low.
- **Recommendation:** Keep staged updates and validate via periodic `bootc status` checks.

## Rollback / recovery
For any regression introduced by image updates:

```bash
sudo bootc rollback
sudo systemctl reboot
```

For configuration drift checks:

```bash
sudo ostree admin config-diff
```

## Reference baseline
- Fedora Docs: rpm-ostree / bootc operational model.
- BlueBuild docs: module-list schema and build workflow model.
- GitHub Actions changelog: Node 20 deprecation and Node 24 migration.
