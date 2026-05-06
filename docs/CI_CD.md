# CI/CD and Automation (GitHub Actions)

This document covers **only** GitHub Actions pipelines and how they operate.

## Overview

| Workflow | Trigger | Goal |
| :-- | :-- | :-- |
| `build-amd.yml` | `workflow_dispatch` (manual or triggered by `check-updates.yml`) | Run Trivy security gate, then build and publish AMD image |
| `build-nvidia.yml` | `workflow_dispatch` (manual or triggered by `check-updates.yml`) | Run Trivy security gate, then build and publish NVIDIA image |
| `check-updates.yml` | `schedule` (every 2h) + `workflow_dispatch` | Detect new upstream digest and trigger builds |
| `cleanup.yml` | daily `schedule` + `workflow_dispatch` | Clean up old images and workflow runs |

---

## Image Builds

### AMD
- Workflow: `.github/workflows/build-amd.yml`
- Trigger: `workflow_dispatch` (manual or invoked by `check-updates.yml`)
- Timeout: 45 minutes
- Main action: `blue-build/github-action@v1`
- Recipe: `recipe-amd.yml`
- Signing: `cosign_private_key: ${{ secrets.SIGNING_SECRET }}`

### NVIDIA
- Workflow: `.github/workflows/build-nvidia.yml`
- Trigger: `workflow_dispatch` (manual or invoked by `check-updates.yml`)
- Timeout: 45 minutes
- Main action: `blue-build/github-action@v1`
- Recipe: `recipe-nvidia.yml`
- Signing: `cosign_private_key: ${{ secrets.SIGNING_SECRET }}`

### Relevant build settings

- `verify_install: true`
- `use_cache: true`
- `retry_push_count: 3`
- `build_chunked_oci: false` (current state)

### Minimum recommended sanity checks (quick audit)

Before opening a PR with workflow/recipe changes:

1. Validate workflow and recipe YAML:

```bash
ruby -ryaml -e "Dir.glob('{recipes,.github/workflows}/**/*.yml').sort.each{|f| YAML.load_file(f); puts \"OK #{f}\"}"
```

2. Verify recipe paths in build workflows:

```bash
rg -n "recipe:\\s+recipe-(amd|nvidia)\\.yml" .github/workflows/build-*.yml
```

3. Verify project restriction (rechunk disabled):

```bash
rg -n "build_chunked_oci:\\s+false" .github/workflows/build-*.yml
```

---

## Automated Digest Update

Workflow: `.github/workflows/check-updates.yml`

- Schedule: `0 */2 * * *` (every 2 hours)
- Matrix: `amd` and `nvidia`
- Flow:
  1. Read `base-image` from `recipes/recipe-<flavor>.yml`
  2. Get remote digest using `skopeo inspect`
  3. Compare through cache key `upstream-<flavor>-<digest>`
  4. If digest is new, trigger `gh workflow run build-<flavor>.yml`

> Practical outcome: image builds remain manual by design, but the checker can **automatically orchestrate** build triggers when upstream changes.

---

## Security (Shift-Left)

Security scan is embedded in each build workflow as a mandatory gate:

- Job `security-scan` runs **before** `build-amd` / `build-nvidia`
- Build jobs depend on `needs: security-scan`
- Trivy filesystem mode (`scan-type: fs`)
- Severities: `CRITICAL,HIGH`
- `ignore-unfixed: true`
- SARIF upload to GitHub Security tab

Practical outcome: builds only run when the security gate passes successfully.

---

## Operational Hygiene

Workflow: `.github/workflows/cleanup.yml`

- Removes old GHCR image versions (keeps 7)
- Removes old workflow runs (retains a minimum set for investigation)

---

## Recommended Practices

1. **Keep documentation split by domain**
   - Project usage: `README.md`
   - Post-install operations: `docs/POST_INSTALL.md`
   - CI/CD: `docs/CI_CD.md`
   - Hardware profile: `docs/HARDWARE_BASELINE.md`
2. **Avoid documentation drift**
   - Any change in `.github/workflows/*.yml` should update `docs/CI_CD.md`.
3. **Audit continuously**
   - Review triggers, permissions, and secrets every quarter.
