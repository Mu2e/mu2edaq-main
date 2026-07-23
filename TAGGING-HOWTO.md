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

Use [semantic versioning](https://semver.org/) prefixed with a letter indicator and suffixed with a descriptive qualifier. 

For the Mu2eDAQ system we use:

| Prefix | Description |
|---|---|
| `p` | Production Release, this is intended to take physics data with |
| `t` | Test Release, this is intended to test the real systems but no physics quality data is taken with it |
| `d` | Development Release, this is intended only for internal development purposes, no data is taken with it |

Suffixes can be looser but common ones are:
| Suffix | Description |
|---|---|
|`rc`   | Release Candidate    |
|`bad`  | Known major problem  |
|`junk` | Not intended for use |
|`<date>`| A date tag          |
|`<epoch>` | A data epoch identifier |

For version fields we use:

```
v<major>.<minor>.<patch>
```
With fields zero padded.

| Increment | When |
|---|---|
| `major` | Incompatible API or configuration changes |
| `minor` | New features, backwards-compatible |
| `patch` | Bug fixes and minor corrections |

So a full version tag may look like:
```
p01.12.02       # Production Tag
p01.12.03-rc    # Release candidate of a Production Tag
p01.14.06-Run1A # Production release that corresponds to Run 1A
t01.11.04-bad   # A test release that had some major flaw
d02.00.00       # A development or integration release
```

Some suffixes may be added (modified) latter based on testing (i.e. a release candidate may be promoted to a release, or a release may get marked bad)

## Step-by-step workflow

### 1. Ensure submodules are up to date

```bash
./mu2edaq-bootstrap.sh status
```

If anything is behind, pull it in with `./mu2edaq-update-submodules.sh`
(fast-forward only, one reviewable commit) or `./mu2edaq-bootstrap.sh
update && ./mu2edaq-bootstrap.sh bump`. Either way, confirm the submodule
commits you want to tag are checked out and that the parent repo's pointers
are committed and pushed before tagging.

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
- `man ./man/man1/mu2edaq-update-submodules.1` — man page for the fast-forward submodule updater
- [GitHub releases for mu2edaq-main](https://github.com/Mu2e/mu2edaq-main/releases)
