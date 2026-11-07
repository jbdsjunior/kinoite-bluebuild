# Security Policy

## Supported Images and Releases

This project builds customized Fedora Kinoite container images using BlueBuild. Security updates are tracked and applied automatically: upstream base image updates are polled every 6 hours (`check-updates.yml`) and each new upstream digest triggers a signed rebuild of both flavors (`build.yml`).

| Variant                    | Reference Target                              |     Supported      |
| :------------------------- | :-------------------------------------------- | :----------------: |
| `kinoite-amd:latest`       | `ghcr.io/jbdsjunior/kinoite-amd:latest`       | :white_check_mark: |
| `kinoite-dual:latest`      | `ghcr.io/jbdsjunior/kinoite-dual:latest`      | :white_check_mark: |

## Image Verification and Integrity

All container images produced by this project are cryptographically signed using **Cosign**.
You can verify the image authenticity before rebasing or switching:

```bash
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-dual:latest
```

Once running the custom image, signature verification is also enforced at the container-runtime level
by switching with `bootc switch --enforce-container-sigpolicy <image>` (two-step transition described in
[`docs/POST_INSTALL.md`](docs/POST_INSTALL.md)). From that point on, every update must carry a valid
Cosign signature or the deployment is rejected.

Repository changes are gated by `validate.yml` (yamllint, shellcheck and `bash -n`) on every pull request,
and all third-party GitHub Actions are pinned to immutable commit SHAs.

## Supply Chain and Secret Governance

To protect both user workstation privacy and project infrastructure integrity:
- **Zero Credentials in Code:** Secrets, OAuth tokens, SSH keys, and WireGuard/OpenVPN profiles are strictly excluded via `.gitignore` and enforced before commits.
- **Minimal Workflow Permissions:** All GitHub Actions run with strictly scoped least-privilege tokens (`contents: read`, pinned action commit SHAs).
- **Public Key Only:** Only the public verification key (`cosign.pub`) is tracked in the repository. Signing keys remain secured within GitHub Actions Secrets (`SIGNING_SECRET`).

## Reporting a Vulnerability

If you discover a security vulnerability or misconfiguration within this repository:

1. **Do not open a public issue.**
2. Please submit a private advisory through GitHub's [Security Advisories](https://github.com/jbdsjunior/kinoite-bluebuild/security/advisories/new) or contact the maintainer directly.
3. Include detailed steps to reproduce the issue and any potential impact.

Security reports will be reviewed promptly, and fixes will be rolled out via automated rebuilds and signed image deployments.
