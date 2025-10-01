# CI/CD Setup Documentation

This document explains the automated CI/CD pipeline for the Calendar Bridge Flutter plugin.

## Overview

The CI/CD pipeline consists of three main workflows:

1. **Test Matrix** (`test.yml`) - Runs tests across multiple platforms and Flutter versions
2. **CI/CD Pipeline** (`ci-cd.yml`) - Main pipeline that tests, versions, and publishes
3. **Auto Release** (`auto-release.yml`) - Alternative comprehensive release workflow

## Workflows

### 1. Test Matrix (`test.yml`)

**Triggers:**
- Push to `main`, `master`, or `develop` branches
- Pull requests to `main` or `master`
- Manual dispatch

**Matrix Testing:**
- **Operating Systems:** Ubuntu, macOS, Windows
- **Flutter Versions:** 3.3.0, 3.10.0, stable, beta (Ubuntu only)

**Steps:**
- Checkout code
- Setup Flutter
- Install dependencies
- Format check
- Static analysis
- Run tests with coverage
- Build examples for each platform
- Upload coverage to Codecov (Ubuntu + stable only)

### 2. CI/CD Pipeline (`ci-cd.yml`)

**Triggers:**
- Push to `main` or `master` branches
- Pull requests (analysis and test only)
- Manual dispatch

**Jobs:**
1. **Analyze** - Format and static analysis checks
2. **Test** - Matrix testing across platforms
3. **Publish** - Automated versioning and publishing (main/master only)

**Publishing Logic:**
- Checks if current version exists on pub.dev
- If exists: increments patch version, updates changelog, commits changes
- If not exists: publishes current version
- Creates GitHub release with auto-generated notes
- Publishes to pub.dev with force flag

### 3. Auto Release (`auto-release.yml`)

**Features:**
- More comprehensive version checking
- Detailed commit analysis
- Advanced changelog generation
- Git tag management
- GitHub release creation

## Setup Requirements

### 1. GitHub Secrets

Add these secrets to your GitHub repository:

```bash
PUB_JSON - Your pub.dev credentials JSON
```

To get `PUB_JSON`:
1. Run `dart pub token` on your local machine
2. Copy the contents of `~/.config/dart/pub-credentials.json`
3. Add it as a secret in GitHub

### 2. Permissions

Ensure the GitHub Actions have proper permissions:
- Contents: write (for creating releases and pushing commits)
- Pull requests: write (for PR comments)

## Manual Version Management

Use the included version manager script:

```bash
# Check current version status
./scripts/version_manager.sh check

# Increment patch version (1.0.0 -> 1.0.1)
./scripts/version_manager.sh increment patch

# Increment minor version (1.0.0 -> 1.1.0)
./scripts/version_manager.sh increment minor

# Increment major version (1.0.0 -> 2.0.0)
./scripts/version_manager.sh increment major

# Force increment without pub.dev checks
./scripts/version_manager.sh force-increment patch
```

## Changelog Management

The pipeline automatically:
1. Gets commits since the last published version
2. Formats them into changelog entries
3. Prepends to `CHANGELOG.md`
4. Includes commit hashes for reference

### Manual Changelog Format

```markdown
## 1.0.1 - 2024-10-02

- Add new calendar feature (`abc1234`)
- Fix timezone handling bug (`def5678`)
- Update documentation (`ghi9012`)
```

## Publishing Process

### Automatic (Recommended)

1. Make your changes and commit them
2. Push to `main` or `master` branch
3. The pipeline will:
   - Run tests
   - Check version status
   - Increment version if needed
   - Update changelog
   - Publish to pub.dev
   - Create GitHub release

### Manual

1. Use version manager script to increment version
2. Commit changes: `git commit -m "chore: bump version to x.y.z"`
3. Create tag: `git tag vx.y.z`
4. Push: `git push origin main --tags`
5. Publish: `dart pub publish --force`

## Troubleshooting

### Common Issues

**1. Publication fails with "version already exists"**
- Check if the version was already published
- Use `./scripts/version_manager.sh check` to verify status

**2. Tests fail in CI but pass locally**
- Check Flutter version differences
- Verify all dependencies are properly specified
- Check platform-specific issues

**3. Changelog not updating**
- Ensure there are commits since the last published version
- Check if Git tags exist for previous versions

**4. Permission denied errors**
- Verify GitHub token has proper permissions
- Check if branch protection rules are blocking pushes

### Debug Commands

```bash
# Check current version and pub.dev status
./scripts/version_manager.sh check

# View recent commits
git log --oneline -10

# Check pub.dev API manually
curl -s "https://pub.dev/api/packages/calendar_bridge"

# Validate pubspec.yaml
dart pub get --dry-run
```

## Configuration Files

### Labels (`labels.yml`)
Defines GitHub issue/PR labels for automatic categorization in release notes.

### Release Configuration (`release.yml`)
Configures automatic release note generation based on PR labels.

## Best Practices

1. **Use semantic versioning** (MAJOR.MINOR.PATCH)
2. **Write descriptive commit messages** (they appear in changelogs)
3. **Test locally before pushing** to main branches
4. **Use feature branches** for development
5. **Label PRs appropriately** for better release notes
6. **Review changelogs** before major releases

## Monitoring

- Check GitHub Actions tab for workflow status
- Monitor pub.dev package page for publication status
- Review GitHub releases for proper changelog generation
- Watch for email notifications about failed workflows