# mu2edaq-main

Top-level meta-repository for the Mu2e DAQ software suite. Each subdirectory is a git submodule pointing to an independent repository in the [Mu2e GitHub organization](https://github.com/Mu2e).

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
| mu2edaq-controlcenter | [Mu2e/mu2edaq-controlcenter](https://github.com/Mu2e/mu2edaq-controlcenter) |
| mu2edaq-controlroom | [Mu2e/mu2edaq-controlroom](https://github.com/Mu2e/mu2edaq-controlroom) |
| mu2edaq-controlroom-setup | [Mu2e/mu2edaq-controlroom-setup](https://github.com/Mu2e/mu2edaq-controlroom-setup) |
| mu2edaq-dashboard | [Mu2e/mu2edaq-dashboard](https://github.com/Mu2e/mu2edaq-dashboard) |
| mu2edaq-dataformat-viewer | [Mu2e/mu2edaq-dataformat-viewer](https://github.com/Mu2e/mu2edaq-dataformat-viewer) |
| mu2edaq-discovery | [Mu2e/mu2edaq-discovery](https://github.com/Mu2e/mu2edaq-discovery) |
| mu2edaq-diskwatcher | [Mu2e/mu2edaq-diskwatcher](https://github.com/Mu2e/mu2edaq-diskwatcher) |
| mu2edaq-downtime-logger | [Mu2e/mu2edaq-downtime-logger](https://github.com/Mu2e/mu2edaq-downtime-logger) |
| mu2edaq-fts | [Mu2e/mu2edaq-fts](https://github.com/Mu2e/mu2edaq-fts) |
| mu2edaq-heartbeatmonitor | [Mu2e/mu2edaq-heartbeatmonitor](https://github.com/Mu2e/mu2edaq-heartbeatmonitor) |
| mu2edaq-kpp-scripts | [Mu2e/mu2edaq-kpp-scripts](https://github.com/Mu2e/mu2edaq-kpp-scripts) |
| mu2edaq-operations | [Mu2e/daq-operations](https://github.com/Mu2e/daq-operations) |
| mu2edaq-resource-manager | [Mu2e/mu2edaq-resource-manager](https://github.com/Mu2e/mu2edaq-resource-manager) |
| mu2edaq-runlog-db | [Mu2e/mu2edaq-runlog-db](https://github.com/Mu2e/mu2edaq-runlog-db) |
| mu2edaq-shifter-tools | [Mu2e/mu2edaq-shifter-tools](https://github.com/Mu2e/mu2edaq-shifter-tools) |
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

`mu2edaq-bootstrap.sh` is a helper script that wraps common submodule workflows into four commands. Run it from the root of the repository.

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

To pull the latest commits for all submodules:

```bash
git submodule update --remote --merge
```

To update a single submodule:

```bash
git submodule update --remote --merge mu2edaq-<name>
```

After updating, commit the new submodule pointers in the parent repo:

```bash
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
