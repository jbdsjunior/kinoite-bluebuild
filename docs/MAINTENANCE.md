# Maintenance Guide (BlueBuild + bootc, 2026)

This repository builds two Fedora Kinoite image variants with BlueBuild:

- `recipes/recipe-amd.yml`
- `recipes/recipe-nvidia.yml`

## 1. Day-2 host operations

Use `bootc` as the default lifecycle interface for hosts running these images:

- `bootc upgrade`
- `bootc switch <image-ref>`
- `bootc rollback`

Keep `rpm-ostree` mainly for compatibility operations such as recovery/rollback inspection.

## 2. Recipe organization and ownership

Keep `recipes/common.yml` as the orchestration entrypoint and split feature scopes into `common-*.yml` files.

Current order in `recipes/common.yml` is intentional:

1. `files`
2. package/repo/content modules
3. kargs
4. `initramfs`
5. systemd

`initramfs` should stay near the end so kernel/boot related changes are included in a single regeneration.

## 3. Safe change policy

Before merging any change that affects boot or networking:

1. Validate YAML and shell scripts in CI (`validate` workflow).
2. Build both variants (`build-amd`, `build-nvidia`).
3. Test at least one local rebase/switch in a VM.
4. Confirm rollback path works (`bootc rollback` or `rpm-ostree rollback`).

## 4. Update cadence

- Dependency and action updates: daily (Dependabot).
- Upstream base digest checks: every 4 hours (`check-updates` workflow).
- Registry cleanup: daily (`cleanup` workflow).

## 5. Fedora major upgrades checklist

When Fedora base jumps to a new major stream:

1. Rebuild both images with no recipe changes.
2. Verify `dnf` module package names still exist (especially codecs and drivers).
3. Re-validate kernel args relevance (`common-kargs.yml`, `common-kvm.yml`, `common-nvidia.yml`).
4. Confirm `prepare-root.conf` behavior and composefs expectations.
5. Perform real hardware smoke test for AMD and NVIDIA paths.

## 6. Where to put configuration files

Follow bootc guidance:

- Prefer `/usr` for image-owned immutable defaults.
- Use `/etc` for mutable machine-specific configuration.
- Use `tmpfiles.d` for directories under `/var` that must exist on deployed systems.

This repository already follows this pattern for most files and should keep it as a rule for future changes.

For user-level Topgrade automation specifically:

- Base units live in `/usr/lib/systemd/user/topgrade.{service,timer}`.
- Project tuning lives in `/usr/lib/systemd/user/topgrade.{service,timer}.d/`.
