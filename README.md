# mu2edaq-main

Top-level meta-repository for the Mu2e DAQ software suite. Each subdirectory is a git submodule pointing to an independent repository in the [Mu2e GitHub organization](https://github.com/Mu2e).

## Submodules

| Directory | Repository |
|---|---|
| mu2edaq-bigredbox | [Mu2e/mu2edaq-bigredbox](https://github.com/Mu2e/mu2edaq-bigredbox) |
| mu2edaq-CFOControl | [Mu2e/mu2edaq-CFOControl](https://github.com/Mu2e/mu2edaq-CFOControl) |
| mu2edaq-cluster-tools | [Mu2e/mu2edaq-cluster-tools](https://github.com/Mu2e/mu2edaq-cluster-tools) |
| mu2edaq-controlcenter | [Mu2e/mu2edaq-controlcenter](https://github.com/Mu2e/mu2edaq-controlcenter) |
| mu2edaq-controlroom | [Mu2e/mu2edaq-controlroom](https://github.com/Mu2e/mu2edaq-controlroom) |
| mu2edaq-dashboard | [Mu2e/mu2edaq-dashboard](https://github.com/Mu2e/mu2edaq-dashboard) |
| mu2edaq-dataformat-viewer | [Mu2e/mu2edaq-dataformat-viewer](https://github.com/Mu2e/mu2edaq-dataformat-viewer) |
| mu2edaq-diskwatcher | [Mu2e/mu2edaq-diskwatcher](https://github.com/Mu2e/mu2edaq-diskwatcher) |
| mu2edaq-fts | [Mu2e/mu2edaq-fts](https://github.com/Mu2e/mu2edaq-fts) |
| mu2edaq-heartbeatmonitor | [Mu2e/mu2edaq-heartbeatmonitor](https://github.com/Mu2e/mu2edaq-heartbeatmonitor) |
| mu2edaq-operations | [Mu2e/daq-operations](https://github.com/Mu2e/daq-operations) |
| mu2edaq-resource-manager | [Mu2e/mu2edaq-resource-manager](https://github.com/Mu2e/mu2edaq-resource-manager) |
| mu2edaq-shifter-tools | [Mu2e/mu2edaq-shifter-tools](https://github.com/Mu2e/mu2edaq-shifter-tools) |

## Cloning

Clone this repo and all submodules in one command:

```bash
git clone --recurse-submodules git@github.com:Mu2e/mu2edaq-main.git
```

If you already cloned without `--recurse-submodules`, initialize and fetch the submodules after the fact:

```bash
git submodule update --init --recursive
```

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
