# mu2edaq-main

This is the top-level meta-repo for the Mu2e DAQ software suite.  The purpose of this repo is to make it easy to checkout and manage the entire suite of DAQ software in a consistent manner.  

This is also the basis of how we are going releases.  Basically the releases are specific tags of this repo which then propagate down to the submodule (and hence to the different individual repos). The other advantage of this approach is that development on the head of a package doesn't screw up the main release (since this main is tied to specific hashes of the submodules)

HOWEVER....if you haven't worked with a package organization like this, it can be a little confusing to do the right checkouts and updates.  So there are some helper scripts that assist with all the GIT magic that needs to happen to do this.

The main script for working with the updates is the boostrap script.  This has a bunch of functions, so look at the instructions later in this file for the actual examples.  There are also scripts for building and testing the release, tagging releases and doing updates to submodules.  Against see the instructions later on.

So what's in this.....everything.  In the most general sense the organization is as follows:

* Mu2e Artdaq components (core artdaq readouts, data overlays etc...). These packages are prefixed as "artdaq-xxxx-xxxx"
* OTSDAQ componeonts (the run control, configuration etc....).  These packages are prefixed as "otsdaq-xxxx-xxxx"
* Everything else.  These packages are prefixed as "mu2edaq-xxxx-xxxx"

## Things to Know

The code stack is mainly a combination of C/C++ and Python.  There is a spack build system for most of it, but not everything requires spack to build and run (i.e. most python packages don't really require a spack run time).   The python methodology that is used is based on Python virtual environments (venv) and esssentially each submodule/repo is setup to have it's own venv area so that it can handle dependancies correctly and pieces can run stand alone.

The scripting that wraps around the code stack is a combination of bash and python.  This provides a robust harness to build, test and run everything.  We try to make everything work off of configuration, so the majority of scripts and harnesses do NOT (and please don't add) hardcoded values in them.  Instead scripts will always do the following:

1. Provide sensible defaults (which will let most things run, but not do anything exciting)
2a. Look for config files (we like yaml, so you will see lots of yaml)
2b. Look for config values in the environment
2c. Override defaults with values from configs or environment
3a. Take most config values on the commandline
3b. Overide defaults and file based config values with values passed on the commandline 

So the ordering is:
```
defaults < environment < config file < commandline
```
Unless specified otherwise.

## Submodules

| Directory | Repository |
|---|---|
| artdaq-core-mu2e | [normanajn/artdaq-core-mu2e](https://github.com/normanajn/artdaq-core-mu2e) |
| artdaq-mu2e | [Mu2e/artdaq-mu2e](https://github.com/Mu2e/artdaq-mu2e) |
| Bootstrap | [Mu2e/Bootstrap](https://github.com/Mu2e/Bootstrap) |
| mu2e-pcie-utils | [Mu2e/mu2e-pcie-utils](https://github.com/Mu2e/mu2e-pcie-utils) |
| mu2e-tdaq-suite | [Mu2e/mu2e-tdaq-suite](https://github.com/Mu2e/mu2e-tdaq-suite) |
| mu2ebintools | [Mu2e/mu2ebintools](https://github.com/Mu2e/mu2ebintools) |
| mu2edaq-bigredbox | [Mu2e/mu2edaq-bigredbox](https://github.com/Mu2e/mu2edaq-bigredbox) |
| mu2edaq-CFOControl | [Mu2e/mu2edaq-CFOControl](https://github.com/Mu2e/mu2edaq-CFOControl) |
| mu2edaq-cluster-tools | [Mu2e/mu2edaq-cluster-tools](https://github.com/Mu2e/mu2edaq-cluster-tools) |
| mu2edaq-commandline-tools | [Mu2e/mu2edaq-commandline-tools](https://github.com/Mu2e/mu2edaq-commandline-tools) |
| mu2edaq-controlcenter | [Mu2e/mu2edaq-controlcenter](https://github.com/Mu2e/mu2edaq-controlcenter) |
| mu2edaq-controlroom | [Mu2e/mu2edaq-controlroom](https://github.com/Mu2e/mu2edaq-controlroom) |
| mu2edaq-controlroom-setup | [Mu2e/mu2edaq-controlroom-setup](https://github.com/Mu2e/mu2edaq-controlroom-setup) |
| mu2edaq-dashboard | [Mu2e/mu2edaq-dashboard](https://github.com/Mu2e/mu2edaq-dashboard) |
| mu2edaq-dataformat-viewer | [Mu2e/mu2edaq-dataformat-viewer](https://github.com/Mu2e/mu2edaq-dataformat-viewer) |
| mu2edaq-desktop | [Mu2e/mu2edaq-desktop](https://github.com/Mu2e/mu2edaq-desktop) |
| mu2edaq-discovery | [Mu2e/mu2edaq-discovery](https://github.com/Mu2e/mu2edaq-discovery) |
| mu2edaq-diskwatcher | [Mu2e/mu2edaq-diskwatcher](https://github.com/Mu2e/mu2edaq-diskwatcher) |
| mu2edaq-downtime-logger | [Mu2e/mu2edaq-downtime-logger](https://github.com/Mu2e/mu2edaq-downtime-logger) |
| mu2edaq-fts | [Mu2e/mu2edaq-fts](https://github.com/Mu2e/mu2edaq-fts) |
| mu2edaq-heartbeatmonitor | [Mu2e/mu2edaq-heartbeatmonitor](https://github.com/Mu2e/mu2edaq-heartbeatmonitor) |
| mu2edaq-kpp-scripts | [Mu2e/mu2edaq-kpp-scripts](https://github.com/Mu2e/mu2edaq-kpp-scripts) |
| mu2edaq-operations | [Mu2e/daq-operations](https://github.com/Mu2e/daq-operations) |
| mu2edaq-phone-notification-system | [Mu2e/mu2edaq-phone-notification-system](https://github.com/Mu2e/mu2edaq-phone-notification-system) |
| mu2edaq-resource-manager | [Mu2e/mu2edaq-resource-manager](https://github.com/Mu2e/mu2edaq-resource-manager) |
| mu2edaq-reverse-proxy | [Mu2e/mu2edaq-reverse-proxy](https://github.com/Mu2e/mu2edaq-reverse-proxy) |
| mu2edaq-runlog-db | [Mu2e/mu2edaq-runlog-db](https://github.com/Mu2e/mu2edaq-runlog-db) |
| mu2edaq-shifter-tools | [Mu2e/mu2edaq-shifter-tools](https://github.com/Mu2e/mu2edaq-shifter-tools) |
| mu2edaq-snapshot-viewer | [Mu2e/mu2edaq-snapshot-viewer](https://github.com/Mu2e/mu2edaq-snapshot-viewer) |
| mu2edaq-trigger-scalers | [Mu2e/mu2edaq-trigger-scalers](https://github.com/Mu2e/mu2edaq-trigger-scalers) |
| otsdaq-mu2e | [Mu2e/otsdaq-mu2e](https://github.com/Mu2e/otsdaq-mu2e) |
| otsdaq-mu2e-calorimeter | [Mu2e/otsdaq-mu2e-calorimeter](https://github.com/Mu2e/otsdaq-mu2e-calorimeter) |
| otsdaq-mu2e-config | [Mu2e/otsdaq-mu2e-config](https://github.com/Mu2e/otsdaq-mu2e-config) |
| otsdaq-mu2e-crv | [Mu2e/otsdaq-mu2e-crv](https://github.com/Mu2e/otsdaq-mu2e-crv) |
| otsdaq-mu2e-dqm | [Mu2e/otsdaq-mu2e-dqm](https://github.com/Mu2e/otsdaq-mu2e-dqm) |
| otsdaq-mu2e-extmon | [Mu2e/otsdaq-mu2e-extmon](https://github.com/Mu2e/otsdaq-mu2e-extmon) |
| otsdaq-mu2e-stm | [Mu2e/otsdaq-mu2e-stm](https://github.com/Mu2e/otsdaq-mu2e-stm) |
| otsdaq-mu2e-sync | [Mu2e/otsdaq-mu2e-sync](https://github.com/Mu2e/otsdaq-mu2e-sync) |
| otsdaq-mu2e-tracker | [Mu2e/otsdaq-mu2e-tracker](https://github.com/Mu2e/otsdaq-mu2e-tracker) |
| otsdaq-mu2e-trigger | [Mu2e/otsdaq-mu2e-trigger](https://github.com/Mu2e/otsdaq-mu2e-trigger) |

## Cloning

Clone this repo and all submodules in one command:

```bash
git clone --recurse-submodules git@github.com:Mu2e/mu2edaq-main.git
```

If you already cloned without `--recurse-submodules`, initialize and fetch the submodules after the fact:

```bash
git submodule update --init --recursive
```

## Bootstrap script

Getting started can be tricky if you don't have help.  So....

`mu2edaq-bootstrap.sh` is a helper script that wraps common submodule workflows into four commands. Run it from the root of the repository to act on the rest of the repos.  The most common things you will do are clone and update.

```
Usage: mu2edaq-bootstrap.sh <command>

Commands:
  clone               Clone mu2edaq-main with all submodules
  update [<name>]     Pull latest commits for all submodules, or a named one
  bump [<name>]       Stage and commit updated submodule pointer(s) in parent repo
  status              Show commit status of all submodules vs their remotes
```

**Clone the full suite onto a new machine:**

```bash
./mu2edaq-bootstrap.sh clone
```

**Pull the latest code for all submodules and record the update:**

```bash
./mu2edaq-bootstrap.sh update
./mu2edaq-bootstrap.sh bump
git push
```

**Update and bump a single submodule:**

```bash
./mu2edaq-bootstrap.sh update mu2edaq-controlcenter
./mu2edaq-bootstrap.sh bump  mu2edaq-controlcenter
git push
```

**Check which submodules are behind their remotes:**

```bash
./mu2edaq-bootstrap.sh status
```

A man page is also available: `man ./man/man1/mu2edaq-bootstrap.1`

## Installing mu2edaq-discovery

`mu2edaq-discovery` is stdlib-only and is **not published on PyPI**, so it
cannot be named in a `requirements.txt` — doing so makes pip abort the whole
file. The consuming apps import it lazily and run fine without it (auto-discovery
simply stays off), so it is installed separately when you want that feature:

```bash
source <your-venv>/bin/activate
./mu2edaq-install-discovery.sh              # from the sibling checkout
```

For nodes without network access, build a wheelhouse once on a machine that has
it, copy the directory over, and install from there:

```bash
./mu2edaq-install-discovery.sh --build-wheel --wheel-dir /path/to/wheelhouse
# ... copy /path/to/wheelhouse to the offline node ...
./mu2edaq-install-discovery.sh --wheel-dir /path/to/wheelhouse
```

Building from source works with the setuptools that a stock AlmaLinux 9 venv
ships (53), but still needs the `wheel` package. AL9 has it system-wide, so
creating the venv with `python3 -m venv --system-site-packages` makes the source
build fully offline; otherwise use the wheelhouse. Use `--python` to target a
specific interpreter and `--editable` for a development install.

## Updating submodules

**Recommended:** `mu2edaq-update-submodules.sh` fetches every submodule,
fast-forwards only what can be safely advanced (skipping anything with local
changes or diverged history), and commits the resulting pointer bumps in one
reviewable commit:

```bash
./mu2edaq-update-submodules.sh                       # all submodules
./mu2edaq-update-submodules.sh mu2edaq-controlcenter # just one
./mu2edaq-update-submodules.sh --dry-run             # preview only
git push
```

A man page is also available: `man ./man/man1/mu2edaq-update-submodules.1`

`mu2edaq-bootstrap.sh update`/`bump` (above) offers the same workflow with
plain merges instead of fast-forward-only, useful when a submodule branch
needs an actual merge commit. Both ultimately do what the raw git commands
below do:

```bash
git submodule update --remote --merge                      # all submodules
git submodule update --remote --merge mu2edaq-<name>        # a single one

git add mu2edaq-<name>   # or: git add -u
git commit -m "Update mu2edaq-<name> to latest"
git push
```

## Making commits to a submodule

Submodules are independent repositories. To contribute to one:

```bash
cd mu2edaq-<name>
# make changes
git add <files>
git commit -m "Your message"
git push
```

Then update the parent repo to point to the new commit:

```bash
cd ..
git add mu2edaq-<name>
git commit -m "Bump mu2edaq-<name> to <short-sha>"
git push
```

## Adding a new submodule

```bash
git submodule add git@github.com:Mu2e/<repo-name>.git <local-directory>
git commit -m "Add <repo-name> as submodule"
git push
```

## Removing a submodule

```bash
git submodule deinit <local-directory>
git rm <local-directory>
git commit -m "Remove <local-directory> submodule"
git push
```

## Tagging a release

`mu2edaq-tag-release.sh` creates (or renames, or lists) an annotated tag
across every submodule and the parent repo. See
[TAGGING-HOWTO.md](TAGGING-HOWTO.md) for the full workflow and tag naming
convention, or `man ./man/man1/mu2edaq-tag-release.1`.

## Compatibility-test harness

`mu2edaq-build-all.sh` / `mu2edaq-test-all.sh` build, install, and test every
`mu2edaq-*` package on the current platform, and `mu2edaq-setup-env.sh` is a
sourceable helper for working interactively with the venvs/builds they
produce:

```bash
./mu2edaq-build-all.sh                 # build/install everything
./mu2edaq-test-all.sh                  # test everything, write .compat/report.md
source mu2edaq-setup-env.sh <package>  # activate a package's venv + build PATH
```

See [testing/README.md](testing/README.md) for the full manifest-driven
harness (per-package build/test behavior, environment knobs, how to add a
package), or the man pages: `man ./man/man1/mu2edaq-build-all.1`,
`man ./man/man1/mu2edaq-test-all.1`, `man ./man/man1/mu2edaq-setup-env.1`.
