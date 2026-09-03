# Security Policy

## Supported Images and Releases

This project builds customized Fedora Kinoite container images using BlueBuild. Security updates are tracked and applied automatically through upstream base image updates and daily package builds.

| Variant | Reference Target | Supported |
| :--- | :--- | :---: |
| `kinoite-amd:latest` | `ghcr.io/jbdsjunior/kinoite-amd:latest` | :white_check_mark: |

## Image Verification and Integrity

All container images produced by this project are cryptographically signed using **Cosign**.
You can verify the image authenticity before rebasing or switching:

```bash
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest
```

Automated image vulnerability scans are performed on every build using **Trivy**, flagging and reporting high/critical severity CVEs via GitHub Security SARIF reports.

## Reporting a Vulnerability

If you discover a security vulnerability or misconfiguration within this repository:

1. **Do not open a public issue.**
2. Please submit a private advisory through GitHub's [Security Advisories](https://github.com/jbdsjunior/kinoite-bluebuild/security/advisories/new) or contact the maintainer directly.
3. Include detailed steps to reproduce the issue and any potential impact.

Security reports will be reviewed promptly, and fixes will be rolled out via automated rebuilds and signed image deployments.
