# Security Policy

## Supported Images and Releases

This project builds customized Fedora Kinoite container images using BlueBuild. Security updates are tracked and applied automatically through upstream base image updates and daily package builds.

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

## Supply Chain and Secret Governance

To protect both user workstation privacy and project infrastructure integrity:
- **Zero Credentials in Code:** Secrets, OAuth tokens, SSH keys, and WireGuard/OpenVPN profiles are strictly excluded via `.gitignore` and enforced before commits.
- **Least-Privilege Workflow Tokens:** each workflow declares the minimum scope it needs and third-party actions are pinned to commit SHAs:

  | Workflow | `contents` | `packages` | `actions` |
  | :--- | :---: | :---: | :---: |
  | `build.yml` (calls `build-image.yml`) | read | write | – |
  | `build-image.yml` (reusable) | read | write | – |
  | `check-updates.yml` | read | – | write |
  | `cleanup.yml` | read | write | write |

  `packages: write` is required exclusively to push signed images to GHCR and `actions: write` to dispatch/delete workflow runs. Only `SIGNING_SECRET` is forwarded to the reusable build workflow (no `secrets: inherit`).
- **Public Key Only:** Only the public verification key (`cosign.pub`) is tracked in the repository. Signing keys remain secured within GitHub Actions Secrets (`SIGNING_SECRET`).

## Reporting a Vulnerability

If you discover a security vulnerability or misconfiguration within this repository:

1. **Do not open a public issue.**
2. Please submit a private advisory through GitHub's [Security Advisories](https://github.com/jbdsjunior/kinoite-bluebuild/security/advisories/new) or contact the maintainer directly.
3. Include detailed steps to reproduce the issue and any potential impact.

Security reports will be reviewed promptly, and fixes will be rolled out via automated rebuilds and signed image deployments.
