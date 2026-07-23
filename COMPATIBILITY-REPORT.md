# mu2edaq-* compatibility report

**Last updated: 2026-07-23.** Original report: 2026-07-02 (preserved verbatim
in the [Appendix](#appendix-original-2026-07-02-almalinux-9-report)). A lot
has landed in the repo since the original run — 9 fixes committed and merged,
plus 4 new submodules (mu2edaq-desktop, mu2edaq-phone-notification-system,
mu2edaq-reverse-proxy, mu2edaq-snapshot-viewer) — so this update re-verifies
everything rather than just patching the old numbers in place.

## Bottom line (2026-07-23)

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

## Current matrix (2026-07-23, macOS 26.5.1 arm64, Python 3.12.1)

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

## Fixes from the original report — verified merged (2026-07-23)

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

## Known issues (new, 2026-07-23)

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

## Not yet covered (2026-07-23)

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

## Appendix: original 2026-07-02 AlmaLinux 9 report

Preserved verbatim below for reference. Its "Fixes applied" and "Issues to
file" sections already described the 9 fixes as done; the section above
independently re-verifies that they are actually merged, two weeks and
several submodule bumps later. Otherwise unchanged from the original.

> Run on the primary production platform: AlmaLinux 9.6, system Python 3.9.21,
> gcc 11.5, cmake 3.26.5. Date: 2026-07-02. Harness: `mu2edaq-build-all.sh` /
> `mu2edaq-test-all.sh` (see `testing/README.md`).

### Bottom line

All 19 `mu2edaq-*` packages now **build, install, and pass their tests** on
this platform (67 test-phase checks pass, 0 fail) — after 9 fixes were applied
across 7 submodules. Before fixes: 1 build failure + 14 test failures. Twelve
issue drafts documenting everything found are in `issue-drafts/`.

### Matrix (final state)

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

### Fixes applied (uncommitted, in the submodule working trees)

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

### Issues to file (drafts in `issue-drafts/`, most severe first)

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

### Platform notes

- Python 3.9 reached upstream EOL in Oct 2025; it remains the AL9 system
  python (RHEL supports it through 2032). The suite standardizes on 3.9+ as
  the floor per the production-platform-first policy.
- `xmlsec1-devel` etc. are NOT needed for fts anymore (manylinux wheels).
- All C++ dev dependencies (zeromq, cppzmq, curl, yaml-cpp, Qt5/Qt6 devel)
  are present on this node; heartbeatmonitor's cpp_sender fetches
  nlohmann/json at configure time (needs network on first configure).
