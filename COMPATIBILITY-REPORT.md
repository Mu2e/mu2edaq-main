# mu2edaq-* AlmaLinux 9 compatibility report

Run on the primary production platform: `mu2e-mgr-01.fnal.gov`, AlmaLinux 9.6
(Sage Margay), kernel 5.14.0-570.39.1.el9_6, system Python 3.9.21, gcc 11.5.0,
cmake 3.26.5, glibc 2.34. Date: 2026-07-24. Harness: `mu2edaq-build-all.sh` /
`mu2edaq-test-all.sh` (see `testing/README.md`). Machine-generated evidence for
this run is in `.compat/report.md` and `.compat/status/{build,test}.tsv`.

Release under test: `t00.02.00-rc` submodule pointers as checked out on
2026-07-24 (see "Versions tested" below).

**This revision supersedes the 2026-07-23 one, which was run on macOS**
(26.5.1 arm64, Python 3.12.1) and explicitly asked for an AL9 re-run before
AL9 could be treated as verified. This is that re-run, on real AL9 hardware.
Both issues that revision left open are fixed here. Earlier revisions are kept
in the appendix.

## Bottom line

All **23** `mu2edaq-*` packages build and install on this platform. Of 120
test-phase checks, **101 pass, 18 skip (not applicable), 1 fails**. The build
phase is 74 pass / 3 skip / 0 fail, including the combined-venv conflict check.

The single failure is `mu2edaq-phone-notification-system`'s pytest suite
(1 of 89 tests) and is a test-isolation defect, not a platform incompatibility.

Three findings from this run needed fixes to the harness itself, and one of
them invalidates part of the previous (2026-07-02) report — see "Corrections to
the previous report".

### Fixes applied (committed on branch `al9-compat-fixes`, merged to `main`)

| # | Repo(s) | Change |
|---|---|---|
| 1 | 9 packages + downtime-logger | Removed the unresolvable `mu2edaq-discovery` requirement from `requirements.txt` / `[project] dependencies`; replaced with an explanatory comment. `pip install` now works on a clean machine. |
| 2 | mu2edaq-main | New `mu2edaq-install-discovery.sh`: offline-safe local install (wheelhouse or sibling checkout), plus `--build-wheel` for air-gapped nodes. Documented in the README. |
| 3 | controlcenter, dashboard, diskwatcher, fts | Added the suite's best-effort discovery-install block; dashboard/diskwatcher/fts now fail loudly instead of reporting success over a failed `pip install`. |
| 3b | mu2edaq-discovery | Metadata moved from a PEP 621 `[project]` table to declarative `setup.cfg`, build floor lowered to `setuptools>=40.8.0`, so it builds with the setuptools 53 in a stock AL9 venv instead of producing an `UNKNOWN` package. |
| 4 | mu2edaq-cluster-tools | `pythonpath = src` in `pytest.ini` + README "Running the tests"; the suite runs from an uninstalled checkout again (152 tests). |
| 5 | mu2edaq-main (harness) | 4 missing packages added to `pkg_list`; `smoke_imports.py` case/extras handling; `build_combined` installs siblings first; `mu2edaq_discovery` import-checked in all 14 consumer venvs. |

Re-verified after these changes with a full `--clean --combined` rebuild plus a
complete test pass across all 23 packages: build 74 PASS / 3 SKIP / 0 FAIL,
tests 101 PASS / 18 SKIP / 1 FAIL (the APNs test defect above).

## Corrections to the previous report

The previous revision of this document claimed a 19-package suite with "67
test-phase checks pass, 0 fail". Three claims in it did not hold up when the
suite was actually exercised on this AL9 node:

1. **Three packages were never built or tested.** `mu2edaq-desktop`,
   `mu2edaq-phone-notification-system`, and `mu2edaq-snapshot-viewer` are
   submodules of this repo but were absent from `pkg_list` in
   `testing/common.sh`, so "all 19 packages pass" silently excluded them.
   They are now covered (venv, editable install, sibling `mu2edaq-discovery`,
   CMake for the notify C++ library, pytest, CLI smokes, import smokes).

2. **The dependency-import check could not have been run on Linux.**
   `testing/smoke_imports.py` fell back to the declared *distribution* name as
   the import name, so `Flask` was imported as `Flask`, `Pillow` as `Pillow`,
   `PyJWT` as `PyJWT`. Those resolve on a case-insensitive filesystem (macOS
   default) and raise `ModuleNotFoundError` on AL9. It also never stripped
   extras, so `qrcode[pil]` and `httpx[http2]` were imported literally. Any
   genuine AL9 run would have reported these. Fixed by normalizing case,
   stripping extras, and extending the distribution→module map.

3. **The cross-package "one venv, `pip check` clean" claim was not verified.**
   The combined venv resolve fails outright (`No matching distribution found
   for mu2edaq-discovery`), and the harness then ran `pip check` against the
   resulting *empty* venv and recorded PASS, masking it. `build_combined` now
   installs sibling checkouts before the resolve. With that fix the claim does
   hold: all 23 requirement sets co-install into one venv with `pip check`
   clean (PyQt5 + PyQt6 + PySide6 + Django + fastapi + flask coexist, no
   version-pin conflicts).

## Matrix (this run)

| Package | Version | Build | Deps import | CLI smoke | pytest | ctest |
|---|---|---|---|---|---|---|
| mu2edaq-bigredbox | rc-15-gc557be3 | venv ✓ | PyQt5 ✓ | – | – | – |
| mu2edaq-CFOControl | rc-2-g6355fda | (scripts) | – | – | – | – |
| mu2edaq-cluster-tools | rc-11-g905d344 | venv+editable ✓ | textual ✓ | ssh-selector, lan-scan ✓ | 152 ✓ | – |
| mu2edaq-controlcenter | rc-3-g810ced7 | venv ✓ | PyQt6+WebEngine ✓ | – | – | – |
| mu2edaq-controlroom | rc-4-g076de7a | venv ✓ (krb5 compiles) | ✓ | – | 2 ✓ | – |
| mu2edaq-controlroom-setup | rc-1-gb72c0f0 | venv+editable ✓ | ✓ | crs-tunnel, crs-remote ✓ | 42 ✓ (1 xfail) | – |
| mu2edaq-dashboard | rc-3-gb5efe0f | venv ✓ + cmake ✓ | zmq/flask ✓ | ✓ | – | – |
| mu2edaq-dataformat-viewer | rc-2-gaa9a951 | venv ✓ + cmake(cpp) ✓ | PyQt6 ✓ | viewer, sender ✓ | – | – |
| mu2edaq-desktop | rc-1-gd40aa32 | venv+editable ✓ | PyQt6 ✓ | 3 entry points ✓ | 17 ✓ | – |
| mu2edaq-discovery | rc-8-gca8d76c | venv+editable ✓ | ✓ | mu2edaq-discover ✓ | 29 ✓ | – |
| mu2edaq-diskwatcher | rc-3-gd798f06 | venv ✓ | ✓ | ✓ | – | – |
| mu2edaq-downtime-logger | rc-2-gcafc76a | venv+editable ✓ | PySide6 ✓ | ✓ | 67 ✓ | – |
| mu2edaq-fts | rc-2-gcc07964 | venv ✓ (SAML wheels OK) | ✓ incl. onelogin.saml2 | ✓ | 37 ✓ | – |
| mu2edaq-heartbeatmonitor | rc-2-g4c25c26 | venv ✓ + cmake(cpp_sender) ✓ | ✓ | monitor, sender ✓ | – | 20/20 ✓ |
| mu2edaq-kpp-scripts | rc-1-gb4622f1 | (scripts) | – | – | – | – |
| mu2edaq-operations | v1_00_00-161-g3352789 | venv ✓ | ✓ | ✓ | 150 ✓ | – |
| mu2edaq-phone-notification-system | rc-1-g45dc9e3 | venv+editable ✓ + cmake ✓ | ✓ | server, cli ✓ | **1 fail** / 88 ✓ | (none built) |
| mu2edaq-resource-manager | rc-2-g541b5f2 | venv ✓ + cmake ✓ | fastapi ✓ | – | – | 1/1 ✓ |
| mu2edaq-reverse-proxy | a8cc7a2 | venv+editable ✓ | PyQt6/Flask ✓ | mu2edaq-proxy, -server ✓ | 229 ✓ | – |
| mu2edaq-runlog-db | rc-1-g1f274e0 | venv ✓ | Django ✓ | manage.py check ✓ | – | – |
| mu2edaq-shifter-tools | rc-2-g4fef244 | (scripts) | – | – | – | – |
| mu2edaq-snapshot-viewer | rc-1-gc937c06 | venv+editable ✓ | PySide6 ✓ | 3 entry points ✓ | 101 ✓ | – |
| mu2edaq-trigger-scalers | rc-3-g2bb2b12 | cmake(Qt6) ✓ | – | – | – | – |

Every package also passes `py-compile` under Python 3.9 and `bash -n` on every
shipped shell script. No PEP 604 / 3.10-only syntax remains anywhere in the
suite, and every `pyproject.toml` that declares `requires-python` declares
`>=3.9`.

## Open issues from this run

### Major

1. **`mu2edaq-discovery` was not installable — FIXED in this branch.**
   Ten packages listed a bare `mu2edaq-discovery` in `requirements.txt`. It is
   not on PyPI, so the documented install path failed on a clean AL9 machine,
   with pip aborting the whole resolve and installing *nothing*:

   ```
   $ pip install -r mu2edaq-dashboard/requirements.txt
   ERROR: Could not find a version that satisfies the requirement mu2edaq-discovery
   ERROR: No matching distribution found for mu2edaq-discovery
   ```

   Filed 2026-07-02 as `Mu2e/mu2edaq-main#4` for four packages, closed
   2026-07-21 while still reproducible; re-filed with full evidence as
   `Mu2e/mu2edaq-main#5`. See "The mu2edaq-discovery dependency" below for the
   fix and the rejected alternatives.

2. **`mu2edaq-phone-notification-system` pytest fails on any clean checkout.**
   `tests/test_dispatch.py::test_apns_alert_payload_is_plain_visible_notification`
   constructs `ApnsSender` with the real config, whose `key_file` is
   `config/apns_key.p8` — a gitignored credential absent from every fresh
   clone. `ApnsSender.__init__` therefore sets `self.enabled = False`, the test
   patches `_client`/`_key`/`_token` but never restores `enabled`, and `send()`
   returns `logged` instead of `sent`. Confirmed the test passes iff that file
   exists (any content suffices), so it only ever passed on a workstation with
   a real APNs key.

### Moderate

3. **`mu2edaq-cluster-tools` test suite could not run as documented — FIXED.**
   Commit `11ad1a8` moved the sources under `src/` (src-layout) but nothing
   installed the package for tests: `pytest.ini` set no `pythonpath`, and the
   README had no test section. `pip install -r requirements.txt && pytest` gave
   `ModuleNotFoundError: No module named 'mu2edaq_cluster_tools'` for all seven
   test modules. Fixed by adding `pythonpath = src` to `pytest.ini` and a
   "Running the tests" section to the README; verified from an uninstalled
   checkout (152 passed). Filed as `Mu2e/mu2edaq-cluster-tools#4`.

4. **C++ tests silently absent for phone-notification-system.** Its CMake
   project builds, but CppUnit is not installed on this node, so `ctest` reports
   "No tests were found" and the harness records that as a pass. Either add
   `cppunit-devel` to the AL9 dependency list or have CMake fail loudly.

### Carried over (unchanged, previously filed)

- `Mu2e/mu2edaq-main#2` — suite uses PyQt5 + PyQt6 + PySide6 + C++ Qt5/Qt6
  simultaneously; consider standardizing.
- `Mu2e/mu2edaq-fts#6` — SAML build instructions outdated; manylinux wheels
  work on AL9, `xmlsec1-devel` etc. are no longer needed.
- `Mu2e/mu2edaq-fts#7`, `Mu2e/mu2edaq-controlroom#8` — committed virtualenvs
  and bytecode still in git history.
- `Mu2e/mu2edaq-fts#8`, `Mu2e/mu2edaq-heartbeatmonitor#8` — bootstrap scripts
  not location-independent and report success on failure.
- `Mu2e/mu2edaq-controlroom-setup#4` — requirements.txt / pyproject PyQt6 drift.

## The mu2edaq-discovery dependency

### Why it broke

`mu2edaq-discovery` is stdlib-only, zero-dependency, and **not published on
PyPI**. Ten `requirements.txt` files named it as a plain requirement, which pip
cannot resolve — and pip aborts the *entire* file on an unresolvable name, so
those environments got nothing installed at all, not merely "no discovery".

This contradicted the code: all nine consumers import it lazily inside a
`try/except Exception`, with comments like *"best-effort so a missing package
never blocks startup"*. The runtime treats it as optional; only the packaging
insisted it was mandatory.

### Fix applied

- The bare requirement is removed from all ten `requirements.txt` files and
  from `mu2edaq-downtime-logger`'s `[project] dependencies`, replaced by a
  comment explaining why it must not be listed and how to install it.
  downtime-logger gains a `discovery` extra for the local-install case.
- `mu2edaq-install-discovery.sh` (new, in this repo) is the supported local
  install path. It prefers a prebuilt wheel from a wheelhouse (fully offline),
  otherwise builds from the sibling checkout, and handles the setuptools floor
  described below. `--build-wheel` produces a wheelhouse to copy to offline
  nodes.
- The four bootstrap scripts with no discovery step at all (controlcenter,
  dashboard, diskwatcher, fts) gained the best-effort block already used by
  bigredbox/dataformat-viewer/snapshot-viewer, and dashboard/diskwatcher/fts
  now fail loudly instead of printing "initialized successfully" over a failed
  `pip install`.

Verified on AL9: `pip install -r requirements.txt` now succeeds in a clean venv
for all nine previously-broken packages, `pip install .` succeeds for
downtime-logger, and an end-to-end `bootstrap_diskwatcher.sh` in the submodule
layout installs both the app dependencies and discovery from the sibling.

### Build toolchain: now works with the stock AL9 setuptools

`mu2edaq-discovery` originally declared PEP 621 `[project]` metadata in
`pyproject.toml` with `build-system.requires = ["setuptools>=61"]`. A stock AL9
`python3 -m venv` ships **setuptools 53**, which predates PEP 621 support, so
`pip install ../mu2edaq-discovery` — the mechanism most bootstrap scripts use —
either reached out to PyPI for a newer setuptools or, with build isolation
disabled, built an empty `UNKNOWN` package:

```
creating /tmp/pip-modern-metadata-.../UNKNOWN.egg-info
error: invalid command 'bdist_wheel'
```

Fixed by moving the metadata to declarative `setup.cfg` (read by setuptools
since 30.3) and lowering the floor to `setuptools>=40.8.0`. `pyproject.toml`
now carries only `[build-system]`; setup.cfg is the single source of truth, and
its header says so — adding a `[project]` table back would silently win on
setuptools >= 61 and let the two drift.

Verified that both toolchains produce the same artifact: wheels built with
setuptools 53.0.0 and 82.0.1 have an identical 7-file payload, identical
entry points, and identical `Name`/`Version`/`Requires-Python`/`Provides-Extra`
metadata. The only difference is where each setuptools generation places the
license file (`dist-info/LICENSE` vs `dist-info/licenses/LICENSE`).

One residual constraint: building a wheel still needs the `wheel` package in
the target environment. AL9 ships it system-wide (`python3-wheel`), so
`python3 -m venv --system-site-packages` picks it up and the build is fully
offline; a plain venv does not have it. The wheelhouse path avoids the question
entirely, and `mu2edaq-install-discovery.sh` detects the case and says so.

### Options considered

| Option | No PyPI | Offline | Standalone clone | Verdict |
|---|---|---|---|---|
| Drop the hard requirement, install locally (**applied**) | ✓ | ✓ | ✓ | Chosen — matches the guarded runtime imports |
| `mu2edaq-discovery @ git+https://github.com/...` | ✓ | ✗ | ✓ | Kept only as a bootstrap *fallback*; needs GitHub reachable at install time and a ref to bump each release |
| Relative path `../mu2edaq-discovery` in requirements.txt | ✓ | partly | ✗ | Rejected — hard-fails standalone clones and resolves relative to CWD, not the file |
| Vendor a wheel into each consumer repo | ✓ | ✓ | ✓ | Rejected — 1.3 MB duplicated ten times, ten places to re-sync |
| Publish to PyPI or an internal index | ✗ / infra | ✓ (index) | ✓ | Best long-term; retires all of the above. Needs a policy decision |

The recommendation is to keep the applied fix now and pursue an internal index
(or PyPI) as the permanent answer, at which point `mu2edaq-discovery` can go
back into `requirements.txt` as a normal pinned dependency.

## Coverage

All four submodules the 2026-07-23 revision listed as uncovered — `desktop`,
`phone-notification-system`, `snapshot-viewer` and `reverse-proxy` — are now in
`pkg_list` and exercised. `mu2edaq-reverse-proxy` was registered as a tracked
submodule after this working tree was created; it has been initialized, added
to the manifest, and passes all six checks (229 pytest tests). Every
`mu2edaq-*` submodule in `.gitmodules` is now covered by the harness.

### Intermittent: reverse-proxy GUI test segfault

On its **first** run after install, `mu2edaq-reverse-proxy`'s suite died with a
segmentation fault in
`tests/test_gui.py::test_toolbar_toggle_does_not_disturb_existing_proxies`,
inside `_settle()`'s `app.processEvents()` loop:

```
tests/test_gui.py ...............Fatal Python error: Segmentation fault
Current thread ...:
  File ".../tests/test_gui.py", line 50 in _settle
  File ".../tests/test_gui.py", line 207 in test_toolbar_toggle_does_not_disturb_existing_proxies
```

That is the exact hazard `_settle`'s own docstring documents — Qt frees the
worker objects once their thread finishes, so touching a wrapper whose C++ side
has gone segfaults rather than raising. It has **not** recurred in 30
subsequent runs (25 direct, 3 file-scoped, 2 through the harness), and the test
passes in isolation, so it is a rare race rather than a blocker. Recorded here
because a segfault in a test suite is worth tracking even at low frequency; not
filed as an issue.

## Platform notes

- Python 3.9 reached upstream EOL in Oct 2025; it remains the AL9 system
  python (RHEL supports it through 2032). The suite standardizes on 3.9+ as
  the floor per the production-platform-first policy.
- `xmlsec1-devel` and friends are NOT needed for fts (manylinux wheels).
- All C++ dev dependencies (zeromq, cppzmq, curl, yaml-cpp, Qt5/Qt6 devel) are
  present on this node. `cppunit-devel` is not.
- heartbeatmonitor's `cpp_sender` fetches nlohmann/json at configure time, so
  the first configure needs network access.
- Qt GUI smokes run with `QT_QPA_PLATFORM=offscreen` under a timeout.

## Reproducing

```bash
./mu2edaq-build-all.sh --clean --combined
./mu2edaq-test-all.sh
cat .compat/report.md
```

## Versions tested

Submodule pointers as listed in the matrix above; parent repo at `76058d0`
plus the harness fixes described in "Corrections to the previous report".

## Appendix: previous revisions

Kept for provenance. The 2026-07-23 revision was run on **macOS 26.5.1
arm64 / Python 3.12.1**, not AlmaLinux 9 — it says so itself, and it
flagged that "someone with AL9 access should still re-run" the harness
before treating AL9 as re-verified. This 2026-07-24 revision is that run.
Both issues it left open are now fixed: the `build_combined()`
sibling-install gap, and the submodules missing from `pkg_list`.

### Bottom line (2026-07-23)

- **All 19 `mu2edaq-*` packages in the harness's manifest still build,
  install, and pass their tests** — build: 55/56 steps pass, the one failure
  being the known `_combined` gap below (not a package regression); test:
  73/73 steps pass, 18 skipped where not applicable (e.g. script-only
  packages with no pytest suite). Ran with
  `mu2edaq-build-all.sh --clean --combined` and `mu2edaq-test-all.sh` (see
  `testing/README.md`).
- **Platform note:** this run is on **macOS 26.5.1 (arm64), Python 3.12.1**
  (`sw_vers`/`python3 --version`), not the AlmaLinux 9 box the original
  report used — this sandbox doesn't have AL9 access. The suite's floor is
  Python 3.9+ (RHEL/AL9 system Python) and the harness is deliberately kept
  bash-3.2/POSIX-clean so it runs on both; this run substantiates the macOS
  side and re-confirms the source-level fixes, but someone with AL9 access
  should still re-run `mu2edaq-build-all.sh && mu2edaq-test-all.sh` there
  before treating AL9 as re-verified.
- **All 9 fixes** listed in the original report's "Fixes applied" table were
  described there as *uncommitted, in the submodule working trees*. They are
  now confirmed **committed and merged** — see
  [Fixes from the original report](#fixes-from-the-original-report--verified-merged-2026-07-23)
  below. `git log` shows they landed in `800410d` ("Add AlmaLinux 9
  compatibility harness; bump 7 fixed submodules (#1, #2)") and later bump
  commits.
- **New, harness-level issue found in this run** (not a package regression):
  the `--combined` cross-package conflict check now fails to install,
  because several packages' `requirements.txt` list `mu2edaq-discovery` (not
  on PyPI, installed from the sibling checkout) and `build_combined()` in
  `testing/common.sh` never got the sibling-install step that per-package
  builds have. This gap didn't exist on 2026-07-02 because the
  sibling-checkout pattern for `mu2edaq-discovery` was introduced afterward.
  Per-package builds and `pip check` are unaffected — see
  [Known issues](#known-issues-new-2026-07-23).
- **4 submodules are not yet in the harness manifest** (`pkg_list` in
  `testing/common.sh`): mu2edaq-desktop, mu2edaq-phone-notification-system,
  mu2edaq-reverse-proxy, mu2edaq-snapshot-viewer. All four ship a
  `pyproject.toml`, `requirements.txt`, and `tests/` directory, so they look
  like straightforward additions, but they were not exercised by this report
  — see [Not yet covered](#not-yet-covered-2026-07-23).

### Current matrix (2026-07-23, macOS 26.5.1 arm64, Python 3.12.1)

| Package | Build | Deps import | CLI smoke | pytest | ctest |
|---|---|---|---|---|---|
| mu2edaq-bigredbox | venv ✓ | PyQt6 ✓ | – | – | – |
| mu2edaq-CFOControl | (scripts) | – | – | – | – |
| mu2edaq-cluster-tools | venv ✓ | textual ✓ | – | 152 ✓ | – |
| mu2edaq-controlcenter | venv ✓ | PyQt6+WebEngine ✓ | – | – | – |
| mu2edaq-controlroom | venv ✓ | ✓ | – | 2 ✓ | – |
| mu2edaq-controlroom-setup | venv+editable ✓, sibling discovery ✓ | ✓ | crs-tunnel/crs-remote ✓ | 42 ✓, 1 xfail | – |
| mu2edaq-dashboard | venv ✓ + cmake ✓ | zmq/flask ✓ | ✓ | – | – |
| mu2edaq-dataformat-viewer | venv ✓ + cmake(cpp) ✓ | PyQt6 ✓ | ✓ | – | – |
| mu2edaq-discovery | venv+editable ✓ | ✓ | mu2edaq-discover ✓ | 40 ✓ | – |
| mu2edaq-diskwatcher | venv ✓ | ✓ | ✓ | – | – |
| mu2edaq-downtime-logger | venv+editable ✓ | PySide6 ✓ | ✓ | 67 ✓ | – |
| mu2edaq-fts | venv ✓ | ✓ incl. onelogin.saml2 | ✓ | 37 ✓ | – |
| mu2edaq-heartbeatmonitor | venv ✓ + cmake(cpp_sender) ✓ | ✓ | ✓ | – | 20 ✓ |
| mu2edaq-kpp-scripts | (scripts) | – | – | – | – |
| mu2edaq-operations | venv ✓ | ✓ | ✓ | 150 ✓ | – |
| mu2edaq-resource-manager | venv ✓ + cmake ✓ | fastapi ✓ | – | – | 1 ✓ |
| mu2edaq-runlog-db | venv ✓ | Django ✓ | manage.py check ✓ | – | – |
| mu2edaq-shifter-tools | (scripts) | – | – | – | – |
| mu2edaq-trigger-scalers | cmake(Qt6) ✓ | – | – | – | – |
| _combined (conflict check) | **FAIL** — see Known issues | – | – | – | – |

Cross-package check: `pip check` on the `_combined` venv reports **no
broken requirements** (the FAIL above is in resolving the combined install,
not in a version conflict once packages that do resolve are installed).

### Fixes from the original report — verified merged (2026-07-23)

The original report (2026-07-02) listed 9 fixes as "applied (uncommitted, in
the submodule working trees)". Each is now confirmed present in the current
submodule checkouts and traceable to a merged commit:

| # | Repo | Fix | Status |
|---|---|---|---|
| 1 | mu2edaq-downtime-logger | `requires-python` `>=3.10` → `>=3.9` | ✅ confirmed in `pyproject.toml:10` |
| 2 | mu2edaq-heartbeatmonitor | `from __future__ import annotations` in `heartbeat_monitor.py` | ✅ confirmed at line 15 |
| 3 | mu2edaq-dataformat-viewer | same future-import fix in viewer, sender, `config/config.py`; README → 3.9+ | ✅ confirmed in all 3 files + README |
| 4 | mu2edaq-controlroom | mechanical py2→py3 port of 7 NOvA-legacy scripts | ✅ confirmed — no active (uncommented) `print` statements or `cPickle` remain |
| 5 | mu2edaq-controlroom | `bin/make-data-dirs.sh` → `.py`; fixed missing `+` syntax error; python3 shebang | ✅ confirmed — `bin/make-data-dirs.py` present |
| 6 | mu2edaq-controlroom | `daq-env-tools.py` → `daq_env_tools.py`; import-safe `main()`; fixed 2 latent bugs; tests now run | ✅ confirmed — `daq_env_tools.py` + `test_daq_env_tools.py` present, pytest passes (2 tests) |
| 7 | mu2edaq-controlroom, mu2edaq-shifter-tools | 5 unversioned `python` shebangs → `python3` | ✅ confirmed — no bare `#!/usr/bin/env python` remains in either repo |
| 8 | mu2edaq-cluster-tools, mu2edaq-resource-manager | README Python 3.10+ claims → 3.9+ | ✅ confirmed in both READMEs |
| 9 | mu2edaq-main | added compatibility harness (`mu2edaq-build-all.sh`, `mu2edaq-test-all.sh`, `mu2edaq-setup-env.sh`, `testing/`), `.gitignore` | ✅ confirmed — this report was generated by re-running that exact harness |

All 9 landed via commit `800410d` ("Add AlmaLinux 9 compatibility harness;
bump 7 fixed submodules (#1, #2)") and were carried forward by later
submodule bump commits (`a36274c`, `9002efc`, `a5b9ab0`, `82914c1`, `76058d0`,
`fd00fa4`).

### Known issues (new, 2026-07-23)

1. **`build_combined()` doesn't sibling-install `mu2edaq-discovery`.**
   `testing/common.sh`'s per-package `build_venv()` installs
   `pkg_sibling_deps()` (currently just `mu2edaq-discovery`, from the local
   checkout) before `pip install -r requirements.txt`, so the venv already
   has it and requirements resolve. `build_combined()` skips straight to
   installing every package's `requirements.txt` in one shot, so
   `mu2edaq-discovery` — not published to PyPI — fails to resolve there.
   Proposed fix: install `mu2edaq-discovery` (editable, from its local
   checkout) into the `_combined` venv before the big `pip install -r ...`
   pass, mirroring what per-package builds already do.

### Not yet covered (2026-07-23)

`testing/common.sh`'s `pkg_list` predates these submodules; none were
exercised by this report or the harness generally:

- mu2edaq-desktop
- mu2edaq-phone-notification-system
- mu2edaq-reverse-proxy
- mu2edaq-snapshot-viewer

Each already ships a `pyproject.toml`, `requirements.txt`, and `tests/`
directory, so adding them should be a matter of appending to `pkg_list` (and,
if any needs an editable install or CLI smoke, a case in the corresponding
manifest function) rather than new harness code.

---

### Appendix: original 2026-07-02 AlmaLinux 9 report

Preserved verbatim below for reference. Its "Fixes applied" and "Issues to
file" sections already described the 9 fixes as done; the section above
independently re-verifies that they are actually merged, two weeks and
several submodule bumps later. Otherwise unchanged from the original.

> Run on the primary production platform: AlmaLinux 9.6, system Python 3.9.21,
> gcc 11.5, cmake 3.26.5. Date: 2026-07-02. Harness: `mu2edaq-build-all.sh` /
> `mu2edaq-test-all.sh` (see `testing/README.md`).

#### Bottom line

All 19 `mu2edaq-*` packages now **build, install, and pass their tests** on
this platform (67 test-phase checks pass, 0 fail) — after 9 fixes were applied
across 7 submodules. Before fixes: 1 build failure + 14 test failures. Twelve
issue drafts documenting everything found are in `issue-drafts/`.

#### Matrix (final state)

| Package | Build | Deps import | CLI smoke | pytest | ctest |
|---|---|---|---|---|---|
| mu2edaq-bigredbox | venv ✓ | PyQt5 ✓ | – | – | – |
| mu2edaq-CFOControl | (scripts) | – | – | – | – |
| mu2edaq-cluster-tools | venv ✓ | textual ✓ | – | ✓ | – |
| mu2edaq-controlcenter | venv ✓ | PyQt6+WebEngine ✓ | – | – | – |
| mu2edaq-controlroom | venv ✓ (krb5 compiles) | ✓ | – | ✓ (fixed) | – |
| mu2edaq-controlroom-setup | venv+editable ✓, sibling discovery ✓ | ✓ | crs-tunnel/crs-remote ✓ | ✓ | – |
| mu2edaq-dashboard | venv ✓ + cmake ✓ | zmq/flask ✓ | ✓ | – | – |
| mu2edaq-dataformat-viewer | venv ✓ + cmake(cpp) ✓ | PyQt6 ✓ | ✓ (fixed) | – | – |
| mu2edaq-discovery | venv+editable ✓ | ✓ | mu2edaq-discover ✓ | ✓ | – |
| mu2edaq-diskwatcher | venv ✓ | ✓ | ✓ | – | – |
| mu2edaq-downtime-logger | venv+editable ✓ (fixed) | PySide6 ✓ | ✓ | 67 ✓ | – |
| mu2edaq-fts | venv ✓ (SAML wheels OK) | ✓ incl. onelogin.saml2 | ✓ | ✓ | – |
| mu2edaq-heartbeatmonitor | venv ✓ + cmake(cpp_sender) ✓ | ✓ | ✓ (fixed) | – | ✓ |
| mu2edaq-kpp-scripts | (scripts) | – | – | – | – |
| mu2edaq-operations | venv ✓ | ✓ | ✓ | ✓ | – |
| mu2edaq-resource-manager | venv ✓ + cmake ✓ | fastapi ✓ | – | – | – |
| mu2edaq-runlog-db | venv ✓ | Django ✓ | manage.py check ✓ | – | – |
| mu2edaq-shifter-tools | (scripts) | – | – | – | – |
| mu2edaq-trigger-scalers | cmake(Qt6) ✓ | – | – | – | – |

Cross-package check: **all 19 requirement sets co-install into one venv** with
`pip check` clean (PyQt5 + PyQt6 + PySide6 + Django + fastapi + flask
coexist). No version-pin conflicts anywhere in the suite.

*Note (added 2026-07-23): this combined co-install no longer succeeds as of
today's run — see [Known issues](#known-issues-new-2026-07-23) above. The
regression is in the harness's `_combined` step, not in any package.*

#### Fixes applied (uncommitted, in the submodule working trees)

| # | Repo | Change | Status (2026-07-23) |
|---|---|---|---|
| 1 | mu2edaq-downtime-logger | `requires-python` `>=3.10` → `>=3.9` (no 3.10 features used; 67 tests pass on 3.9) | ✅ **fixed & merged** |
| 2 | mu2edaq-heartbeatmonitor | `from __future__ import annotations` in `heartbeat_monitor.py` (PEP 604 crash on 3.9) | ✅ **fixed & merged** |
| 3 | mu2edaq-dataformat-viewer | same fix in viewer, sender, `config/config.py`; README → 3.9+ | ✅ **fixed & merged** |
| 4 | mu2edaq-controlroom | mechanical py2→py3 port of 7 NOvA-legacy scripts (print/cPickle only) | ✅ **fixed & merged** |
| 5 | mu2edaq-controlroom | `bin/make-data-dirs.sh` → `.py`; fixed missing `+` syntax error; python3 shebang | ✅ **fixed & merged** |
| 6 | mu2edaq-controlroom | `daq-env-tools.py` → `daq_env_tools.py`; import-safe main(); fixed 2 latent bugs; tests now run | ✅ **fixed & merged** |
| 7 | mu2edaq-controlroom, mu2edaq-shifter-tools | 5 unversioned `python` shebangs → `python3` (no `python` binary on AL9) | ✅ **fixed & merged** |
| 8 | mu2edaq-cluster-tools, mu2edaq-resource-manager | README Python 3.10+ claims → 3.9+ (verified) | ✅ **fixed & merged** |
| 9 | mu2edaq-main | added compatibility harness (`mu2edaq-build-all.sh`, `mu2edaq-test-all.sh`, `mu2edaq-setup-env.sh`, `testing/`), `.gitignore` | ✅ **fixed & merged** |

macOS remains supported by all fixes: future-imports are version-neutral,
`requires-python >=3.9` is a relaxation, shebang `python3` is the modern macOS
convention, and the harness scripts avoid bash-4/GNU-only constructs.

#### Issues to file (drafts in `issue-drafts/`, most severe first)

1. `01` downtime-logger requires-python blocks AL9 install — **fixed**
2. `02` heartbeatmonitor PEP 604 crash on 3.9 (contradicts its README) — **fixed**
3. `03` dataformat-viewer PEP 604 crashes in 3 files — **fixed**
4. `04` controlroom ships 7 Python-2 NOvA-legacy scripts — **ported**, retire-vs-keep decision open
5. `05` controlroom make-data-dirs.sh: python-in-.sh + syntax error — **fixed**
6. `06` controlroom daq-env-tools: untestable + 2 latent bugs — **fixed**
7. `07` unversioned python shebangs (controlroom, shifter-tools) — **fixed**
8. `08` README Python-version claims inconsistent with 3.9 reality — **fixed**
9. `09` suite uses PyQt5+PyQt6+PySide6+C++ Qt simultaneously — recommendation *(still open)*
10. `10` controlroom-setup requirements.txt/pyproject drift (PyQt6) — proposal *(still open)*
11. `11` fts SAML build docs outdated (binary wheels now work on AL9) — docs *(still open)*
12. `12` fts has a complete macOS py3.12 venv committed to git (2,090 files,
    darwin .so binaries, shebangs pointing at a personal Mac); stray committed
    bytecode in operations + controlroom — proposal with commands — **fixed**
    *(verified 2026-07-23: `git ls-files` shows zero `venv/` entries in
    mu2edaq-fts and zero tracked `.pyc` in mu2edaq-operations/mu2edaq-controlroom;
    `.gitignore` in each now excludes `venv/`/bytecode)*

#### Platform notes

- Python 3.9 reached upstream EOL in Oct 2025; it remains the AL9 system
  python (RHEL supports it through 2032). The suite standardizes on 3.9+ as
  the floor per the production-platform-first policy.
- `xmlsec1-devel` etc. are NOT needed for fts anymore (manylinux wheels).
- All C++ dev dependencies (zeromq, cppzmq, curl, yaml-cpp, Qt5/Qt6 devel)
  are present on this node; heartbeatmonitor's cpp_sender fetches
  nlohmann/json at configure time (needs network on first configure).
