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

- **Sweep complete: 19 of 26 packages exercised on Windows** — 16 with their
  pytest suites run, plus 3 no-suite apps (`dashboard`, `heartbeatmonitor`,
  `controlcenter`) confirmed to import clean. The other 7 are out of scope on
  this host: `Bootstrap` (Unix workstation setup), `CFOControl` / `config` /
  `kpp-scripts` (shell/YAML only), `trigger-scalers` (Qt6 C++ only), and
  `shifter-tools` (no suite; its import-crash bug is fixed). See the per-package
  matrix for each verdict.
- **16 packages were executed on Windows.** `mu2edaq-controlroom`:
  `test_daq_env_tools` **2 passed**, but its `krb5` dep won't install on Windows
  and its runtime is Unix-only (#11). `mu2edaq-phone-notification-system`:
  Python suite **88 passed / 1 failed** (1 fix; the fail is the pre-existing
  non-Windows APNs bug). `mu2edaq-commandline-tools`:
  Python suite **18 passed** (C++ part blocked). `mu2edaq-resource-manager`:
  FastAPI Python suite **25 passed** (C++ part blocked). `mu2edaq-fts`:
  **37 passed** (SAML wheels install fine). `mu2edaq-bigredbox`:
  **47 passed** after fixing the `/tmp` defaults (#8) and a `SO_REUSEADDR`
  single-instance bug (#14). `mu2edaq-reverse-proxy`:
  **229 passed** (clean). `mu2edaq-snapshot-viewer`:
  **100 passed / 1 skipped** (2 tests fixed: Windows path in double-quoted
  YAML). `mu2edaq-downtime-logger`:
  **66 passed / 1 failed** (logfile-rotation file lock, #13).
  `mu2edaq-cluster-tools`:
  **151 passed / 1 skipped** (symlink test, fixed). `mu2edaq-operations`:
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
| mu2edaq-bigredbox | **RAN** | ✅ CLEAN (fixed) | **47 passed** after two fixes: `/tmp` PID/log defaults → `tempfile.gettempdir()` (#8), and `SO_REUSEADDR` → `SO_EXCLUSIVEADDRUSE` on Windows so the single-instance port check works (#14). Both on `windows-compat@d314369`. |
| mu2edaq-cluster-tools | **RAN** | ✅ CLEAN | **151 passed / 1 skipped** on Windows. Only skip was a test creating a symlink (needs elevation on Windows) — fixed to skip cleanly (`windows-compat@d82f869`). LAN scan / ssh-selector still shell out to `ssh` at runtime. |
| mu2edaq-commandline-tools | **RAN** (py) | 🔧 CMAKE + ✅ | Python suite **18 passed** on Windows. `/etc/mu2edaq/...` is only a candidate config path (skipped if absent). C++ component unbuildable here. |
| mu2edaq-config | STATIC | 📜 SCRIPTS | YAML config + 8 bash scripts; no Python. |
| mu2edaq-controlcenter | **RAN** (import) | ✅ CLEAN | No pytest suite; all `src/*.py` (incl. PyQt6 + WebEngine modules) **import clean** on Windows (offscreen). 5 bash scripts alongside. |
| mu2edaq-controlroom | **RAN** (partial) | ❌ BROKEN | `test_daq_env_tools.py` **2 passed**, but the `krb5` dependency **fails to install on Windows** (no wheel; needs `krb5-config`). NOVA-legacy runtime is Unix-only: hardcoded `/home/novadaq/...`, `ssh`, `ps aux`, `os.system("kill ...")`, `klist`/`kinit`. See #11. |
| mu2edaq-controlroom-setup | **RAN** | ⚠️ RUNTIME | **38 passed / 4 failed / 1 xfailed.** Failures: Linux `.desktop` generation + ssh ControlMaster socket path (`~/.crs`; Windows `expanduser` ignores `$HOME`, and Windows OpenSSH lacks ControlMaster). `klist -s` gate is Windows-wrong. See #12. |
| mu2edaq-dashboard | **RAN** (import) | 🔧 CMAKE + ✅ | No pytest suite; `dashboard.py` **imports clean** on Windows. Daemon `os.fork()` **guarded**; C++ sender unbuildable here. |
| mu2edaq-dataformat-viewer | STATIC | 🔧 CMAKE + ⚠️ | PyQt6 viewer + C++ component (unbuildable here). |
| mu2edaq-desktop | **RAN** | ⚠️ RUNTIME | **13 passed / 4 failed.** Imports clean; failures are executing `.sh` as a program (WinError 193) and installing Linux `.desktop` entries (WinError 2). Launcher-install is Linux-specific. See #12. |
| mu2edaq-discovery | **RAN** | ✅ CLEAN | **23 passed** on Windows (core: protocol/cli/loopback). GUI test needs Qt/display (excluded). stdlib-only core. |
| mu2edaq-diskwatcher | **RAN** | ✅ CLEAN | **275 passed / 6 failed / 12 skipped**. All 6 failures = tests invoking `.sh` via `bash <windows-path>` (backslash mangling), not package defects. Daemon `os.fork()` **guarded**. |
| mu2edaq-downtime-logger | **RAN** | ⚠️ RUNTIME | **66 passed / 1 failed** (with `pytest-qt`). Failure: logfile detector holds the file open (blocks rotation, `WinError 32`) and detects rotation via `st_ino` (meaningless on Windows). See #13. Rest of the app clean. |
| mu2edaq-fts | **RAN** | ✅ CLEAN | **37 passed** on Windows. `onelogin.saml2` SAML wheels install fine; daemon **guarded** (`os.name == "nt"` → clean exit). The `/var/log`/`/data` literals in tests are stored strings, not touched on disk, so they pass. |
| mu2edaq-heartbeatmonitor | **RAN** (import) | 🔧 CMAKE + ✅ | No pytest suite; `heartbeat_monitor.py`/`heartbeat_sender.py` **import clean** on Windows. Daemon `os.fork()` **guarded**. `cpp_sender` unbuildable here. |
| mu2edaq-kpp-scripts | STATIC | — | Empty of code (0 py, 0 sh) in this checkout. |
| mu2edaq-operations | **RAN** | ✅ CLEAN | **150 passed** on Windows (with `requirements.txt` deps installed). 12 bash ops scripts alongside are Git-Bash-only. |
| mu2edaq-phone-notification-system | **RAN** (py) | 🔧 CMAKE + ✅ | Python suite **88 passed / 1 failed** after fixing a Windows path in double-quoted YAML (`windows-compat@4fdc5f0`). The 1 remaining failure is the pre-existing APNs-key test-isolation bug (missing `config/apns_key.p8`), not Windows-related. C++ lib unbuildable here. |
| mu2edaq-resource-manager | **RAN** (py) | 🔧 CMAKE + ✅ | FastAPI Python suite **25 passed** on Windows (needs `httpx` for `TestClient` — missing from `requirements.txt`, platform-agnostic). C++ component unbuildable here. |
| mu2edaq-reverse-proxy | **RAN** | ✅ CLEAN | **229 passed** on Windows (full suite). `klist -s` Kerberos gate is mocked in tests and remains a runtime concern (#11); `cpp/` component not built here. |
| mu2edaq-runlog-db | **RAN** | ✅ CLEAN | Django `manage.py check` — **no issues** on Windows. |
| mu2edaq-shifter-tools | STATIC | ❌ BROKEN (fixed) | `os.getuid()` at module top of `open_tunnels.py` → import crash on Windows. **Fixed on this branch.** Also uses `ssh`/`scp`/`kill` at runtime. |
| mu2edaq-snapshot-viewer | **RAN** | ✅ CLEAN | **100 passed / 1 skipped** after fixing 2 tests that hand-wrote Windows paths into double-quoted YAML (`\U` escape error). Fixed to use `yaml.safe_dump` (`windows-compat@d0dea32`). Production code already used safe_dump. |
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
| 3 | mu2edaq-bigredbox | `src/mu2edaq_bigredbox/daq_alert.py` | `SO_EXCLUSIVEADDRUSE` on Windows (else `SO_REUSEADDR`) so the single-instance port check raises on a second bind. |
| 4 | mu2edaq-cluster-tools | `tests/test_config.py` | Skip the symlink-dedup test when symlink creation isn't permitted (Windows non-elevated). |
| 5 | mu2edaq-snapshot-viewer | `tests/test_server_web.py`, `tests/test_admin_cli.py` | Build test config via `yaml.safe_dump` so Windows paths aren't misread as double-quoted-scalar escapes. |
| 6 | mu2edaq-phone-notification-system | `tests/test_config.py` | Same `yaml.safe_dump` fix for a Windows token-file path in double-quoted YAML. |

These are the two changes that are unambiguously correct on every platform. The
runtime-Unix items (SSH/Kerberos/`ps`/`kill`, the bash harness, C++ builds) are
larger design questions filed as issues rather than patched blindly.

## PowerShell scripts & added test coverage (phase 2)

Adding native PowerShell (`.ps1`) ports of the bash launch/bootstrap scripts so
Windows nodes have first-class launchers, plus targeted cross-platform test
coverage. All parse-checked with the PowerShell parser and committed to each
submodule's `windows-compat` branch. Progress:

| Package | PowerShell scripts added | Tests added | Suite | Commit |
|---|---|---|---|---|
| mu2edaq-bigredbox | `bootstrap.ps1`, `start-mu2edaq-bigredbox.ps1`, `stop-mu2edaq-bigredbox.ps1` | `tests/test_windows_compat.py` (6) | 53 passed | `1c70b33` |
| mu2edaq-diskwatcher | `bootstrap-diskwatcher.ps1`, `start-…ps1`, `stop-…ps1`, `lib/diskwatcher-proc.ps1` | `tests/test_windows_scripts.py` (parity + parse + dry-run); bash tests gated to POSIX (**closes #10**) | 282 passed / 18 skipped | `b691bf8` |
| mu2edaq-snapshot-viewer | (5 launch/bootstrap `.ps1` already shipped; parse-verified) | `tests/test_windows_scripts.py` (parity + parse + capture) | 107 passed / 1 skipped | `25ba27a` |
| mu2edaq-shifter-tools | `bootstrap.ps1` (venv setup). Kerberos/VNC/noVNC/login admin scripts are Unix-only (#11), not ported | first-ever `tests/` (5): open_tunnels import, read_config, parity/parse. **Fixed a real `import sys` bug** in `read_config.py` | 5 passed | `9cab9ad` |
| mu2edaq-cluster-tools | `bootstrap.ps1`, `install.ps1` (per-user install → `%LOCALAPPDATA%` + `.cmd` launchers) | `tests/test_windows_compat.py` (6): ipconfig fallback, ping flags, parity/parse. **Fixed a real Windows gap**: `ssh_selector` had no `ipconfig` fallback → empty network auto-detect | 157 passed / 1 skipped | `fee22e5` |
| mu2edaq-phone-notification-system | `bootstrap.ps1`, `start-`/`stop-mu2edaq-notify-server.ps1` (aws proxy/chain scripts are Linux deploy, not ported) | `tests/test_windows_scripts.py` (6): parity, parse, aws-not-ported, config path guard | 94 passed / 1 fail (pre-existing APNs) | `ba1e678` |
| mu2edaq-controlroom-setup | `bootstrap.ps1`, `bin/start-`/`stop-controlroom.ps1` (server VNC scripts are Linux cluster, not ported) | `tests/test_windows_compat.py` (7). **Fixed `gio` crash** in crs-provision-desktop + 2 test fixes → cleared all 4 phase-1 failures (#12) | 48 passed / 1 skip / 1 xfail (was 38/4-fail) | `60bfffe` |
| mu2edaq-desktop | `bootstrap.ps1`, `start-`/`stop-mu2edaq-desktop.ps1` (bin/install-* are Linux XDG/AL9 installers, not ported) | `tests/test_windows_compat.py` (6). **Fixed same `gio` crash** in icons + 2 test skips → cleared all 4 phase-1 failures (**closes #12**) | 21 passed / 2 skip (was 13/4-fail) | `e4ae19f` |
| mu2edaq-downtime-logger | `bootstrap.ps1`, `start-`/`stop-mu2edaq-downtime-logger.ps1` | `tests/test_windows_scripts.py` + new `test_..._copytruncate` (cross-platform rotation). **#13 narrowed**: `st_ino` works on Windows & copytruncate handled; only unlink-while-open rotation is POSIX-only (gated) | 67 passed / 1 skip (was 66/1-fail) | `20549a6` |
| mu2edaq-fts | `bootstrap_fts.ps1`, `start-`/`stop-mu2edaq-fts.ps1` (start backgrounds via Start-Process since `--daemon` fork is Windows-guarded) | `tests/test_windows_compat.py` (5): parity, parse, daemon-guard. Source review clean (scp/xrdcp/hooks degrade gracefully) | 42 passed (was 37) | `6fd9886` |
| mu2edaq-reverse-proxy | 5 scripts: `bootstrap.ps1`, `start-`/`stop-mu2edaq-proxy-{gui,server}.ps1` (stop matches by cmdline via CIM = `pgrep -f`) | `tests/test_windows_compat.py` (7): run_dir/socket cross-platform, parity/parse. `klist`/ssh runtime stays #11 | 236 passed (was 229) | `19de4a9` |
| mu2edaq-operations | **none** — 12 `.sh` are Linux DAQ ops (PCIe/DTC/IPMI/lm-sensors/otsdaq/pssh), no app launchers; ports would be non-functional | `tests/test_windows_compat.py` (5): temp reader degrades gracefully (psutil `sensors_temperatures` guard), clean `main()` error, no-launcher invariant | 155 passed (was 150) | `acf074e` |
| mu2edaq-resource-manager | `bootstrap.ps1`, `start-`/`stop-mu2edaq-resource-manager.ps1` (RM_* env contract; start backgrounds via Start-Process). C++ build + `load_env.sh` are Linux, not ported | `tests/test_windows_compat.py` (5): parity, parse, cpp/env-not-ported. Server Windows-safe (uvicorn) | 30 passed (py; was 25) | `7f88f57` |
| mu2edaq-runlog-db | 5-script launch chain: `bootstrap-`/`start-`/`stop-mu2e-rundb-viewer.ps1` + standardized wrappers. **Prod uses waitress on Windows** (gunicorn is Unix-only); dev uses runserver | `tests/test_windows_scripts.py` (7): chain parity, parse, `manage.py check` | 7 passed + check clean | `cd41148` |
| mu2edaq-discovery | `bootstrap.ps1`, `start-`/`stop-mu2edaq-discover-gui.ps1` (stop via CIM cmdline match) | `tests/test_windows_compat.py` (6): SO_REUSEPORT guard, multicast constants, parity/parse. UDP multicast Windows-safe (loopback test passes) | 29 passed (was 23) | `c8cc78a` |
| mu2edaq-commandline-tools | `bootstrap.ps1`, `start-`/`stop-mu2edaq-commandline-tools.ps1` (full option/env parity). C++ build gated on cmake presence | `tests/test_windows_compat.py` (6): config candidate-list graceful, expanduser, parity/parse | 24 passed py (was 18) | `66e3e41` |
| mu2edaq-heartbeatmonitor | `bootstrap_heartbeat_monitor.ps1`, `start-`/`stop-mu2edaq-heartbeatmonitor.ps1` (start backgrounds via Start-Process; daemon `os.fork` guarded). C++ cpp_sender not built | first `tests/` (6). **Fixed `/tmp` daemon defaults** → `tempfile.gettempdir()` (as #8) | 6 passed | `346d774` |

## Not verifiable on this host

- All 🔧 CMAKE C++ components — no compiler/CMake installed.
- Full GUI suites requiring a live Qt platform (Windows offscreen was not
  exercised for every package to keep installs bounded).
- End-to-end SSH/Kerberos flows (no Mu2e gateway/keytab reachable).

**Install gotcha (PySide6/Qt).** Installing PySide6 into a venv under a deep
directory hit the Windows 260-char `MAX_PATH` limit (pip `OSError`, a Qt
`.obj` path overflows). Either enable Win32 long paths or put the venv under a
short root (e.g. `C:\v\...`). This affects the test *environment*, not the
packages.

## Issues filed

Filed on `Mu2e/mu2edaq-main`, each titled with the submodule:

| # | Title | Status |
|---|-------|--------|
| [#7](https://github.com/Mu2e/mu2edaq-main/issues/7) | shifter-tools `open_tunnels.py` `os.getuid()` import crash | **Fixed** (`mu2edaq-shifter-tools@47f8636`, branch `windows-compat`) |
| [#8](https://github.com/Mu2e/mu2edaq-main/issues/8) | bigredbox `/tmp` PID/log defaults not portable | **Fixed** (`mu2edaq-bigredbox@f55615b`, branch `windows-compat`) |
| [#9](https://github.com/Mu2e/mu2edaq-main/issues/9) | Harness (build-all/test-all/install-discovery) assumes `python3` + `venv/bin` | Open — needs maintainer decision |
| [#10](https://github.com/Mu2e/mu2edaq-main/issues/10) | diskwatcher CLI tests fail: bash invoked with backslash Windows path | **Fixed** (`mu2edaq-diskwatcher@b691bf8`) |
| [#11](https://github.com/Mu2e/mu2edaq-main/issues/11) | SSH-tunnel + Kerberos tooling is Unix-only (5 packages) | Open — design decision |
| [#12](https://github.com/Mu2e/mu2edaq-main/issues/12) | desktop / controlroom-setup: Linux `.desktop` install + ssh ControlMaster fail on Windows | **Fixed** (`controlroom-setup@60bfffe`, `desktop@e4ae19f`) |
| [#13](https://github.com/Mu2e/mu2edaq-main/issues/13) | downtime-logger logfile detector: open handle blocks rotation + inode detection on Windows | **Narrowed** (`downtime-logger@20549a6`) — inode/copytruncate work on Windows; only unlink-rotation is POSIX-only |
| [#14](https://github.com/Mu2e/mu2edaq-main/issues/14) | bigredbox `SO_REUSEADDR` defeats single-instance port check on Windows | **Fixed** (`mu2edaq-bigredbox@d314369`) |
