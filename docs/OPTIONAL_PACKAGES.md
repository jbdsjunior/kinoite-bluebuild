# Optional Packages Guide

This document explains which optional packages and Flatpaks are commented out by default, and when you should enable them.

## How to Enable Optional Packages

1. Edit the corresponding YAML file in `recipes/`
2. Uncomment the desired packages (remove the `# ` prefix)
3. Rebuild your image following the [local development guide](../bluebuild/README.md)

---

## Flatpak Packages (`common-flatpaks.yml`)

### KDE Multimedia and Productivity Tools

| Package | Description | Enable When |
| :--- | :--- | :--- |
| `org.kde.elisa` | Music player | You want a native KDE music player |
| `org.kde.gwenview` | Image viewer | You need a lightweight image viewer |
| `org.kde.haruna` | Video player | You prefer Haruna over other video players |
| `org.kde.kcalc` | Calculator | You want a simple calculator app |
| `org.kde.krdc` | Remote desktop client | You need RDP/VNC remote desktop access |
| `org.kde.okular` | Document viewer | You need PDF/ePub document viewing |

### Browsers

| Package | Description | Enable When |
| :--- | :--- | :--- |
| `com.brave.Browser` | Brave browser | You want privacy-focused browsing with ad-blocking |
| `com.google.Chrome` | Google Chrome | You need Chrome-specific features or sync |
| `com.microsoft.Edge` | Microsoft Edge | You prefer Edge for work/sync with Microsoft account |
| `org.mozilla.firefox` | Firefox | You want Firefox as backup browser (system uses RPM version by default) |

> **Note:** Browser RPMs are installed via vendor repositories. Flatpak versions provide sandboxing but may have different performance characteristics.

### System Utilities

| Package | Description | Enable When |
| :--- | :--- | :--- |
| `com.github.tchx84.Flatseal` | Flatpak permissions manager | You manage multiple Flatpak apps and need fine-grained control |
| `io.github.flattool.Warehouse` | Flatpak management tool | You want an alternative Flatpak manager |
| `io.missioncenter.MissionCenter` | System monitor | You want a graphical system resource monitor |
| `it.mijorus.gearlever` | AppImage manager | You frequently use AppImage applications |

### Development Tools

| Package | Description | Enable When |
| :--- | :--- | :--- |
| `com.visualstudio.code` | VS Code (Flatpak) | You prefer Flatpak sandboxing for VS Code |
| `com.ranfdev.DistroShelf` | Distrobox GUI | You want a graphical interface for Distrobox management |

### Communication and Others

| Package | Description | Enable When |
| :--- | :--- | :--- |
| `org.qbittorrent.qBittorrent` | qBittorrent | You need a BitTorrent client |

---

## RPM Packages (`common-packages.yml`)

Check `recipes/common-packages.yml` for commented RPM packages. Common patterns:

- **Development tools**: Enable if you do local compilation or container development
- **Multimedia codecs**: Already covered by negativo17 repository
- **Virtualization tools**: KVM/libvirt already enabled via `common-kvm.yml`

---

## User Scope vs System Scope Flatpaks

The default configuration installs Flatpaks at **system scope** for all users. Consider **user scope** when:

- Multiple users share the system with different app preferences
- You want per-user Flatpak configurations
- You're testing applications before making them available system-wide

To switch to user scope, edit `common-flatpaks.yml`:

```yaml
- scope: user
  notify: false
  install:
    - org.example.App
```

---

## Best Practices

1. **Minimal by default**: Only enable what you need to reduce attack surface and update time
2. **Test in Distrobox**: Before rebuilding your entire image, test Flatpaks manually with `flatpak install`
3. **Document your changes**: Keep a note of which packages you enabled for future reference
4. **Consider alternatives**: Some functionality may be available via Distrobox containers instead of native packages
