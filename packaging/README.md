# Packaging Guide for WireGuard Manager

This guide explains how to package WireGuard Manager for different Linux distributions.

## 📦 Arch Linux (AUR)

### Prerequisites
- Arch Linux system or Docker container
- AUR account with SSH key configured
- `base-devel` package group installed

### Building locally
```bash
cd packaging/arch
makepkg -si  # Build and install
makepkg --printsrcinfo > .SRCINFO  # Generate metadata
```

### Publishing to AUR
1. **First time setup**:
   ```bash
   git clone ssh://aur@aur.archlinux.org/wg-manager.git aur-wg-manager
   cd aur-wg-manager
   cp ../packaging/arch/PKGBUILD .
   cp ../packaging/arch/.SRCINFO .
   git add PKGBUILD .SRCINFO
   git commit -m "Initial import of wg-manager"
   git push
   ```

2. **Updates**:
   ```bash
   # Update pkgver and pkgrel in PKGBUILD
   # Update checksums if needed
   makepkg --printsrcinfo > .SRCINFO
   git add PKGBUILD .SRCINFO
   git commit -m "Update to version X.Y.Z"
   git push
   ```

### AUR Package URL
Once published: https://aur.archlinux.org/packages/wg-manager

## 📦 Debian/Ubuntu

### Prerequisites
- Debian/Ubuntu system
- `build-essential`, `debhelper`, `devscripts` packages

### Building locally
```bash
# Copy debian files to project root
cp -r packaging/debian .

# Build source package
dpkg-buildpackage -S -us -uc

# Build binary package  
dpkg-buildpackage -b -us -uc

# Check quality
lintian ../*.deb
```

### Publishing to Ubuntu PPA

1. **Setup**:
   ```bash
   # Install tools
   sudo apt install dput-ng

   # Setup GPG key (if not done)
   gpg --gen-key
   gpg --send-keys YOUR_KEY_ID
   ```

2. **Upload to PPA**:
   ```bash
   # Sign the package
   debsign ../*.changes

   # Upload to your PPA
   dput ppa:your-username/wg-manager ../*.changes
   ```

### PPA URL
Example: https://launchpad.net/~your-username/+archive/ubuntu/wg-manager

## 🤖 Automated Packaging

The GitHub Action `.github/workflows/package.yml` automatically:

- ✅ Builds AUR package files on release
- ✅ Calculates correct checksums
- ✅ Generates `.SRCINFO` metadata
- ✅ Builds Debian source and binary packages
- ✅ Runs quality checks with lintian

### Triggering builds
```bash
# On release (automatic)
git tag v1.0.0
git push origin v1.0.0

# Manual trigger
gh workflow run package.yml -f version=1.0.0
```

## 📋 Checklist for Release

### Before packaging
- [ ] Update VERSION file
- [ ] Update changelog files
- [ ] Test installation script
- [ ] Run shellcheck on all scripts
- [ ] Update documentation
- [ ] Create git tag

### AUR Release
- [ ] Update PKGBUILD version
- [ ] Calculate new checksums
- [ ] Generate .SRCINFO
- [ ] Test build with `makepkg -si`
- [ ] Push to AUR repository

### Debian Release  
- [ ] Update debian/changelog
- [ ] Test build with `dpkg-buildpackage`
- [ ] Run lintian checks
- [ ] Upload to PPA (Ubuntu)
- [ ] Submit to Debian mentors (for official repo)

## 🎯 Distribution Status

| Distribution | Status | Repository | Maintainer |
|--------------|--------|------------|------------|
| Arch Linux  | 🟡 Planned | AUR | @akasha-code |
| Ubuntu      | 🟡 Planned | PPA | @akasha-code |
| Debian      | 🟡 Planned | mentors | @akasha-code |
| Fedora      | 🔴 Not started | - | - |
| openSUSE    | 🔴 Not started | - | - |

## 📞 Support

For packaging issues:
- Open an issue on GitHub
- Contact maintainer: your-email@example.com
- Check distribution-specific guidelines

## 📚 References

- [AUR Submission Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Ubuntu PPA Help](https://help.launchpad.net/Packaging/PPA)
- [Arch PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD)
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)