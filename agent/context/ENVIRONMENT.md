# Environment Context — kinoite-bluebuild

## Deployment Target

- **OS:** Fedora Kinoite (KDE Plasma desktop, immutable via bootc/rpm-ostree)
- **Build Framework:** BlueBuild (bootc-based OCI image builder)
- **Registry:** GitHub Container Registry (GHCR) — `ghcr.io/jbdsjunior/`
- **Image Variants:**
  - `kinoite-amd` — base: `quay.io/fedora/fedora-kinoite:latest`
  - `kinoite-nvidia` — base: `ghcr.io/ublue-os/kinoite-nvidia:latest`
- **Platform:** `linux/amd64` only
- **Signing:** Cosign (keyless via OIDC or static key), public key in `cosign.pub`

## Hardware Target

| Component | Target | Minimum |
|---|---|---|
| CPU | AMD Ryzen 9 5950X | AMD Ryzen 5000 / Intel 12th Gen |
| RAM | 64 GB | 32 GB |
| Storage | 1 TB NVMe | 256 GB NVMe |
| GPU (Primary) | AMD RX 6600 XT (Wayland) | RX 6000 series |
| GPU (Secondary) | NVIDIA RTX 3080 Ti (Compute) | RTX 3000 series |

> ⚠️ **Warning:** Optimized for 64 GB RAM. Lower-spec hardware may experience instability.

## Framework Constraints

- **BlueBuild modules:** All configuration uses BlueBuild module schema (`module-list-v1.json`)
- **rpm-ostree:** Immutable root filesystem; overlays via `files/system/` copy to `/`
- **bootc:** Client-side switching via `sudo bootc switch <image>`
- **Composefs:** Enabled with fs-verity for image integrity
- **systemd:** Services and timers declared in `/usr/lib/systemd/` (not `/etc/`)
- **tmpfiles.d:** System in `/usr/lib/tmpfiles.d/`, user in `/usr/share/user-tmpfiles.d/`
- **profile.d:** Shell init scripts in `/etc/profile.d/`

## External Dependencies

### RPM Repositories
| Repo | Source | Priority |
|---|---|---|
| negativo17 | bling module | 90 |
| Terra (Fyra Labs) | repos.fyralabs.com | 120 |
| Brave | S3 Amazon | 150 |
| Google Chrome | dl.google.com | 150 |
| Microsoft Edge | packages.microsoft.com | 150 |
| VS Code | packages.microsoft.com | 150 |

### COPRs
| COPR | Packages |
|---|---|
| atim/starship | starship |
| lilay/topgrade | topgrade |

### CI/CD
| Workflow | Trigger | Purpose |
|---|---|---|
| build-amd | workflow_dispatch | Manual AMD image build |
| build-nvidia | workflow_dispatch | Manual NVIDIA image build |
| check-updates | cron */2h | Auto-trigger builds on base image change |
| cleanup | cron daily 00:00 UTC | GHCR image + workflow run cleanup |
| dependabot | daily | github-actions dependency updates |

## Prohibited Actions

- Never merge AMD and NVIDIA build workflows
- Never collapse variant logic — maintain strict separation
- Both variants must inherit from `common-base.yml` independently
- Each variant declares its own `base-image` and `image-version`
