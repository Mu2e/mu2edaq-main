# Tagging a Release

Releases are tagged across all submodules and the parent repository using
`mu2edaq-tag-release.sh`. The script creates an annotated tag in each
repository and pushes it to `origin`.

## Quick start

```bash
./mu2edaq-tag-release.sh v1.2.3
```

This tags every submodule first, then `mu2edaq-main` itself, and pushes all
tags immediately.

## Tag naming convention

Use [semantic versioning](https://semver.org/) prefixed with `v`:

```
v<major>.<minor>.<patch>
```

| Increment | When |
|---|---|
| `major` | Incompatible API or configuration changes |
| `minor` | New features, backwards-compatible |
| `patch` | Bug fixes and minor corrections |

## Step-by-step workflow

### 1. Ensure submodules are up to date

```bash
./mu2edaq-bootstrap.sh status
```

Confirm the submodule commits you want to tag are checked out and that the
parent repo's pointers are committed and pushed.

### 2. Preview the tag operation

```bash
./mu2edaq-tag-release.sh v1.2.3 --dry-run
```

Review the output to confirm the correct repositories will be tagged.

### 3. Create and push the tags

```bash
./mu2edaq-tag-release.sh v1.2.3 -m "Brief description of this release"
```

### 4. Verify

```bash
git tag | grep v1.2.3
git submodule foreach 'git tag | grep v1.2.3'
```

## Tagging locally before pushing

If you want to inspect the tags before they go to GitHub:

```bash
./mu2edaq-tag-release.sh v1.2.3 --no-push
# review, then push manually:
git submodule foreach 'git push origin v1.2.3'
git push origin v1.2.3
```

## Deleting a tag

If a tag was created in error, delete it locally and remotely in each
affected repository:

```bash
# In a submodule
cd mu2edaq-<name>
git tag -d v1.2.3
git push origin :refs/tags/v1.2.3
cd ..

# In the parent repo
git tag -d v1.2.3
git push origin :refs/tags/v1.2.3
```

## Re-running after a failure

If the script is interrupted partway through, re-run the same command. Any
repository that already has the tag will be skipped automatically.

## See also

- `man ./man/man1/mu2edaq-tag-release.1` — full man page for the tagging script
- `man ./man/man1/mu2edaq-bootstrap.1` — man page for the bootstrap script
- [GitHub releases for mu2edaq-main](https://github.com/Mu2e/mu2edaq-main/releases)
