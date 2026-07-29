# mu2edaq-* Windows compatibility report

Branch: `windows-compat`. Date: 2026-07-29.

Host under test: Windows 11 (build 26200), MSYS2/MinGW Git Bash 5.2, native
CPython **3.13.12** (`python` / `py`; note `python3` on `PATH` is the Windows
Store alias stub, not a real interpreter), pip 26.0.1, Node 24.15, git 2.53,
gh 2.88. **No C/C++ toolchain and no CMake are installed on this host**, so
every C++/CMake component in the suite is *blocked* (unbuildable here), not
*passing* or *failing* — it is called out as such below rather than guessed.

Harness: the suite's own `mu2edaq-build-all.sh` / `mu2edaq-test-all.sh` are
bash/POSIX and were not run wholesale (see "The harness itself" below). Instead
each package was assessed by (a) actually creating a Windows venv, installing,
and running its pytest suite where its dependencies are pure-Python and
installable here, and (b) static analysis for Windows-hostile constructs
(Unix-only stdlib, `os.fork`/`getuid`, hardcoded POSIX paths, `subprocess`
calls to `ssh`/`klist`/`kinit`/`ps`/`kill`, bash-only scripts). Rows marked
**RAN** have real pytest output on this host; the rest are **STATIC** or
**BLOCKED**.

## Bottom line

- **6 packages were executed end-to-end on Windows.** `mu2edaq-operations`:
  **150 passed** (clean). `mu2edaq-runlog-db`: Django `manage.py check` — **no
  issues**. `mu2edaq-discovery` core:
  **23 passed**. `mu2edaq-diskwatcher`: **275 passed, 6 failed, 12 skipped** —
  every failure is a test that shells out to a `.sh` script via
  `subprocess.run(["bash", <windows-path>])`, where MSYS bash mangles the
  backslashes; the Python package itself is clean. `mu2edaq-desktop`:
  **13 passed, 4 failed** (running `.sh` as an executable + installing Linux
  `.desktop` entries). `mu2edaq-controlroom-setup`: **38 passed, 4 failed,
  1 xfailed** (Linux `.desktop` generation + ssh ControlMaster socket paths).
  In every case the package imports cleanly on Windows and the failures are
  Linux-desktop / bash-script / Unix-ssh features, not logic defects.
- **1 hard import-time crash** on Windows: `mu2edaq-shifter-tools/open_tunnels.py`
  calls `os.getuid()` at module top level (`AttributeError` on Windows — the
  module cannot be imported at all). **Fixed on this branch.**
- **1 non-portable default path**: `mu2edaq-bigredbox` defaults its PID/log
  files to `/tmp/...`, which does not exist on Windows. **Fixed on this branch**
  (`tempfile.gettempdir()`).
- **Daemon `os.fork()` is already correctly guarded** in `dashboard`, `fts`,
  `heartbeatmonitor`, and `diskwatcher` — each refuses cleanly on Windows rather
  than crashing. No fix needed.
- **A large class of features is runtime-Unix-only**: SSH tunneling + Kerberos
  (`klist`/`kinit`), `ps`/`kill` process management, and the NOVA-legacy control
  room. These install and import fine but their core function needs Unix tools;
  they are degraded-to-nonfunctional on Windows and are not cheap to port.
- **Every bootstrap/start/stop script in the suite is bash.** They run only
  under Git Bash on Windows, never cmd/PowerShell, and the top-level harness
  additionally assumes `python3` resolves to a real interpreter.

## Verdict legend

| Mark | Meaning |
|------|---------|
| ✅ CLEAN | Python installs, imports, and core logic works on Windows (RAN, or high-confidence STATIC) |
| ⚠️ RUNTIME | Installs/imports fine, but key features need Unix tools (ssh/Kerberos/fork) or POSIX paths — degraded on Windows |
| ❌ BROKEN | Crashes on import or core use on Windows |
| 🔧 CMAKE | Has a C++/CMake component that **cannot be built on this host** (no compiler/CMake); Python part assessed separately |
| 📜 SCRIPTS | Ships only/primarily bash `.sh` scripts (Git Bash only on Windows) |

## Package matrix

| Package | How | Windows verdict | Evidence / notes |
|---|---|---|---|
| Bootstrap | STATIC | ⚠️ RUNTIME | Unix-workstation bootstrapper: bash/emacs/vim/gdb dotfiles (N/A on Windows) + `mu2e-ssh-setup.py` (Python, likely runs) with a bash wrapper. |
| mu2edaq-CFOControl | STATIC | 📜 SCRIPTS | 2 py + 2 sh helper scripts; no packaging/tests. Not import-tested. |
| mu2edaq-bigredbox | STATIC | ⚠️ RUNTIME (fixed) | PyQt6 alert GUI. Was ❌ via `/tmp` PID/log defaults → **fixed** to `tempfile.gettempdir()`. Daemon lifecycle via bash start/stop scripts. |
| mu2edaq-cluster-tools | STATIC | ⚠️ RUNTIME | Textual TUI; LAN scan / ssh-selector shell out to `ssh`/scanning tools. Core Python likely imports. |
| mu2edaq-commandline-tools | STATIC | 🔧 CMAKE + ✅ py | Yields `/etc/mu2edaq/...` as a *candidate* config path (skipped if absent — harmless). C++ component unbuildable here. |
| mu2edaq-config | STATIC | 📜 SCRIPTS | YAML config + 8 bash scripts; no Python. |
| mu2edaq-controlcenter | STATIC | ⚠️ RUNTIME | PyQt6 + WebEngine GUI, 5 bash scripts. |
| mu2edaq-controlroom | STATIC | ❌ BROKEN | NOVA-legacy: hardcoded `/home/novadaq/...`, `ssh`, `ps aux`, `os.system("kill ...")`, `klist`/`kinit`. Tunnel & Kerberos features are Unix-only. |
| mu2edaq-controlroom-setup | **RAN** | ⚠️ RUNTIME | **38 passed / 4 failed / 1 xfailed.** Failures: Linux `.desktop` generation + ssh ControlMaster socket path (`~/.crs`; Windows `expanduser` ignores `$HOME`, and Windows OpenSSH lacks ControlMaster). `klist -s` gate is Windows-wrong. See #12. |
| mu2edaq-dashboard | STATIC | 🔧 CMAKE + ⚠️ | Flask dashboard (fine); daemon `os.fork()` **guarded**; C++ sender unbuildable here. |
| mu2edaq-dataformat-viewer | STATIC | 🔧 CMAKE + ⚠️ | PyQt6 viewer + C++ component (unbuildable here). |
| mu2edaq-desktop | **RAN** | ⚠️ RUNTIME | **13 passed / 4 failed.** Imports clean; failures are executing `.sh` as a program (WinError 193) and installing Linux `.desktop` entries (WinError 2). Launcher-install is Linux-specific. See #12. |
| mu2edaq-discovery | **RAN** | ✅ CLEAN | **23 passed** on Windows (core: protocol/cli/loopback). GUI test needs Qt/display (excluded). stdlib-only core. |
| mu2edaq-diskwatcher | **RAN** | ✅ CLEAN | **275 passed / 6 failed / 12 skipped**. All 6 failures = tests invoking `.sh` via `bash <windows-path>` (backslash mangling), not package defects. Daemon `os.fork()` **guarded**. |
| mu2edaq-downtime-logger | STATIC | ✅ CLEAN | PySide6 GUI app; no Unix-only imports or POSIX paths found in source. |
| mu2edaq-fts | STATIC | ⚠️ RUNTIME | Daemon **guarded** (`os.name == "nt"` → clean exit). SAML/onelogin + sqlite. Some tests hardcode `/var/log`, `/data`, `/tmp` literals that may fail if the fs is touched. |
| mu2edaq-heartbeatmonitor | STATIC | 🔧 CMAKE + ✅ | Flask monitor + UDP sender: Python side clean, daemon `os.fork()` **guarded**. `cpp_sender` unbuildable here. |
| mu2edaq-kpp-scripts | STATIC | — | Empty of code (0 py, 0 sh) in this checkout. |
| mu2edaq-operations | **RAN** | ✅ CLEAN | **150 passed** on Windows (with `requirements.txt` deps installed). 12 bash ops scripts alongside are Git-Bash-only. |
| mu2edaq-phone-notification-system | STATIC | 🔧 CMAKE + ⚠️ | APNs push; C++ lib unbuildable here. Carries the known APNs-key test-isolation failure from the AL9 report (unrelated to Windows). |
| mu2edaq-resource-manager | STATIC | 🔧 CMAKE + ✅ | FastAPI service (Python clean) + C++ component (unbuildable here). |
| mu2edaq-reverse-proxy | STATIC | ⚠️ RUNTIME | PyQt6/Flask; `klist -s` Kerberos gate; `cpp/` component. |
| mu2edaq-runlog-db | **RAN** | ✅ CLEAN | Django `manage.py check` — **no issues** on Windows. |
| mu2edaq-shifter-tools | STATIC | ❌ BROKEN (fixed) | `os.getuid()` at module top of `open_tunnels.py` → import crash on Windows. **Fixed on this branch.** Also uses `ssh`/`scp`/`kill` at runtime. |
| mu2edaq-snapshot-viewer | STATIC | ✅ CLEAN | PySide6 + `mss` screen capture (cross-platform) + waitress. No Unix-only imports found. |
| mu2edaq-trigger-scalers | STATIC | 🔧 CMAKE | Qt6 C++ only (0 Python). Unbuildable here. |

## The harness itself (top-level scripts)

All top-level scripts are `#!/usr/bin/env bash`: `mu2edaq-bootstrap.sh`,
`mu2edaq-build-all.sh`, `mu2edaq-test-all.sh`, `mu2edaq-tag-release.sh`,
`mu2edaq-update-submodules.sh`, `mu2edaq-install-discovery.sh`,
`mu2edaq-setup-env.sh`, plus `testing/common.sh`.

- They run only under **Git Bash** on Windows (not cmd/PowerShell).
- `testing/common.sh` uses `PYTHON="${MU2EDAQ_PYTHON:-python3}"` and
  `mu2edaq-install-discovery.sh` hardcodes `PY="python3"`. On this host `python3`
  is the Windows Store alias stub, so **the harness fails out of the box** — it
  must be run as `MU2EDAQ_PYTHON=python ./mu2edaq-build-all.sh` (and
  `install-discovery.sh --python python`).
- venv layout: the scripts assume `venv/bin/activate`; on Windows venvs it is
  `venv/Scripts/activate`. Any step that sources `bin/activate` will not find it.

## Bootstrap package

`Bootstrap/` provisions a Unix DAQ *workstation*: `dotFiles/` (`.bashrc`,
`.bash_profile`, `.emacs`, `.vimrc`, `.gdbinit`, `.gdb_stl`) and
`ssh/scripts/mu2e-ssh-setup.{py,sh}`. On Windows the dotfiles are not
applicable; `mu2e-ssh-setup.py` (`#!/usr/bin/env python3`) is plain Python and
should run under native Python, but its `.sh` wrapper is bash-only. Treated as a
Unix workstation tool; no Windows port attempted.

## Fixes applied on this branch

| # | Package | File | Change |
|---|---------|------|--------|
| 1 | mu2edaq-shifter-tools | `open_tunnels.py` | Guard module-level `os.getuid()` so the module imports on Windows (falls back to `os.getpid()` where `getuid` is absent). |
| 2 | mu2edaq-bigredbox | `src/mu2edaq_bigredbox/config.py` | Default PID/log paths derive from `tempfile.gettempdir()` instead of hardcoded `/tmp` (POSIX behavior unchanged; Windows now writes to `%TEMP%`). |

These are the two changes that are unambiguously correct on every platform. The
runtime-Unix items (SSH/Kerberos/`ps`/`kill`, the bash harness, C++ builds) are
larger design questions filed as issues rather than patched blindly.

## Not verifiable on this host

- All 🔧 CMAKE C++ components — no compiler/CMake installed.
- Full GUI suites requiring a live Qt platform (Windows offscreen was not
  exercised for every package to keep installs bounded).
- End-to-end SSH/Kerberos flows (no Mu2e gateway/keytab reachable).

## Issues filed

Filed on `Mu2e/mu2edaq-main`, each titled with the submodule:

| # | Title | Status |
|---|-------|--------|
| [#7](https://github.com/Mu2e/mu2edaq-main/issues/7) | shifter-tools `open_tunnels.py` `os.getuid()` import crash | **Fixed** (`mu2edaq-shifter-tools@47f8636`, branch `windows-compat`) |
| [#8](https://github.com/Mu2e/mu2edaq-main/issues/8) | bigredbox `/tmp` PID/log defaults not portable | **Fixed** (`mu2edaq-bigredbox@f55615b`, branch `windows-compat`) |
| [#9](https://github.com/Mu2e/mu2edaq-main/issues/9) | Harness (build-all/test-all/install-discovery) assumes `python3` + `venv/bin` | Open — needs maintainer decision |
| [#10](https://github.com/Mu2e/mu2edaq-main/issues/10) | diskwatcher CLI tests fail: bash invoked with backslash Windows path | Open |
| [#11](https://github.com/Mu2e/mu2edaq-main/issues/11) | SSH-tunnel + Kerberos tooling is Unix-only (5 packages) | Open — design decision |
| [#12](https://github.com/Mu2e/mu2edaq-main/issues/12) | desktop / controlroom-setup: Linux `.desktop` install + ssh ControlMaster fail on Windows | Open — product decision |
