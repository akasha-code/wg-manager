# GitHub Actions for Version Management

**📚 Documentation**: [🇺🇸 Main README](../../README.md) | [🇪🇸 README Español](../../README.es.md)

This directory contains GitHub Actions workflows for automatic version management.

## Available Workflows

### 1. version-bump.yml 
**Automatic Semantic Versioning (Advanced)**

- **Trigger**: Push to main or PR merge
- **Functionality**: 
  - Analyzes commit messages to determine change type
  - Automatically generates new versions following semver
  - Creates tags automatically
  - Updates VERSION file
  - Creates GitHub releases
- **Requirements**: Special write permissions

### 2. version-safe.yml (Recommended)
**Safe Versioning with Limited Permissions**

- **Trigger**: Push to main or manual
- **Functionality**:
  - Creates tags automatically without modifying main
  - Generates GitHub releases
  - Allows manual triggers with bump type selection
  - Works with standard GitHub permissions
- **Advantages**: No permission issues, more reliable

### 3. simple-version.yml
**Simple Date-based Versioning**

- **Trigger**: Push to main
- **Functionality**:
  - Generates versions based on date (YYYY.MM.BUILD_NUMBER)
  - Automatically updates VERSION file
  - Simpler but less semantic

## Recommended Usage

### Option A: Version Safe (No permission issues)
1. Use `version-safe.yml`
2. Automatic push creates tags
3. For manual control: use "Actions" → "Version Bump (Safe)" → "Run workflow"

### Option B: Version Bump (If you have special permissions)
1. Use `version-bump.yml`
2. Commits with conventions:
   ```bash
   git commit -m "feat: add new language support"      # → minor bump
   git commit -m "fix: resolve installation error"     # → patch bump
   git commit -m "feat!: change API structure"         # → major bump
   ```

## Commit Conventions (for version-bump.yml)

- `feat: new functionality` → increments MINOR
- `fix: bug fix` → increments PATCH  
- `feat!: breaking change` → increments MAJOR
- Any commit with `BREAKING CHANGE` → increments MAJOR

## Troubleshooting

### Error: "Permission denied" 
- **Cause**: Protected main branch or insufficient permissions
- **Solution**: Use `version-safe.yml` which only creates tags

### Error: "Resource not accessible"
- **Cause**: Token without write permissions
- **Solution**: Verify that workflow has `permissions: contents: write`

### Warning: "set-output command is deprecated"
- **Cause**: Use of deprecated syntax in GitHub Actions
- **Solution**: ✅ **Fixed** - Updated to use `$GITHUB_OUTPUT`

## Recent Updates

- ✅ **October 2025**: Fixed deprecated command warnings
- ✅ **Environment Files Support**: Migrated from `set-output` to `$GITHUB_OUTPUT`
- ✅ **Future Compatibility**: Workflows prepared for modern GitHub Actions

## Configuration

The workflows are ready to use. To activate:

1. **Safe method (recommended)**:
   - Use `version-safe.yml`
   - No special configuration required
   - Works immediately

2. **Advanced method**:
   - Use `version-bump.yml` 
   - May require adjusting branch protection rules

## VERSION File

- The `VERSION` file is maintained manually or by `simple-version.yml`
- Tags are created automatically by `version-safe.yml` or `version-bump.yml`
- The `get_version()` function in `install.sh` reads from the VERSION file