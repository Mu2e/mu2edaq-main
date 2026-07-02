# mu2edaq-* AlmaLinux 9 compatibility report

Run on the primary production platform: AlmaLinux 9.6, system Python 3.9.21,
gcc 11.5, cmake 3.26.5. Date: 2026-07-02. Harness: `mu2edaq-build-all.sh` /
`mu2edaq-test-all.sh` (see `testing/README.md`).

## Bottom line

All 19 `mu2edaq-*` packages now **build, install, and pass their tests** on
this platform (67 test-phase checks pass, 0 fail) — after 9 fixes were applied
across 7 submodules. Before fixes: 1 build failure + 14 test failures. Twelve
issue drafts documenting everything found are in `issue-drafts/`.

## Matrix (final state)

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

## Fixes applied (uncommitted, in the submodule working trees)

| # | Repo | Change |
|---|---|---|
| 1 | mu2edaq-downtime-logger | `requires-python` `>=3.10` → `>=3.9` (no 3.10 features used; 67 tests pass on 3.9) |
| 2 | mu2edaq-heartbeatmonitor | `from __future__ import annotations` in `heartbeat_monitor.py` (PEP 604 crash on 3.9) |
| 3 | mu2edaq-dataformat-viewer | same fix in viewer, sender, `config/config.py`; README → 3.9+ |
| 4 | mu2edaq-controlroom | mechanical py2→py3 port of 7 NOvA-legacy scripts (print/cPickle only) |
| 5 | mu2edaq-controlroom | `bin/make-data-dirs.sh` → `.py`; fixed missing `+` syntax error; python3 shebang |
| 6 | mu2edaq-controlroom | `daq-env-tools.py` → `daq_env_tools.py`; import-safe main(); fixed 2 latent bugs; tests now run |
| 7 | mu2edaq-controlroom, mu2edaq-shifter-tools | 5 unversioned `python` shebangs → `python3` (no `python` binary on AL9) |
| 8 | mu2edaq-cluster-tools, mu2edaq-resource-manager | README Python 3.10+ claims → 3.9+ (verified) |
| 9 | mu2edaq-main | added compatibility harness (`mu2edaq-build-all.sh`, `mu2edaq-test-all.sh`, `mu2edaq-setup-env.sh`, `testing/`), `.gitignore` |

macOS remains supported by all fixes: future-imports are version-neutral,
`requires-python >=3.9` is a relaxation, shebang `python3` is the modern macOS
convention, and the harness scripts avoid bash-4/GNU-only constructs.

## Issues to file (drafts in `issue-drafts/`, most severe first)

1. `01` downtime-logger requires-python blocks AL9 install — **fixed**
2. `02` heartbeatmonitor PEP 604 crash on 3.9 (contradicts its README) — **fixed**
3. `03` dataformat-viewer PEP 604 crashes in 3 files — **fixed**
4. `04` controlroom ships 7 Python-2 NOvA-legacy scripts — **ported**, retire-vs-keep decision open
5. `05` controlroom make-data-dirs.sh: python-in-.sh + syntax error — **fixed**
6. `06` controlroom daq-env-tools: untestable + 2 latent bugs — **fixed**
7. `07` unversioned python shebangs (controlroom, shifter-tools) — **fixed**
8. `08` README Python-version claims inconsistent with 3.9 reality — **fixed**
9. `09` suite uses PyQt5+PyQt6+PySide6+C++ Qt simultaneously — recommendation
10. `10` controlroom-setup requirements.txt/pyproject drift (PyQt6) — proposal
11. `11` fts SAML build docs outdated (binary wheels now work on AL9) — docs
12. `12` fts has a complete macOS py3.12 venv committed to git (2,090 files,
    darwin .so binaries, shebangs pointing at a personal Mac); stray committed
    bytecode in operations + controlroom — proposal with commands

## Platform notes

- Python 3.9 reached upstream EOL in Oct 2025; it remains the AL9 system
  python (RHEL supports it through 2032). The suite standardizes on 3.9+ as
  the floor per the production-platform-first policy.
- `xmlsec1-devel` etc. are NOT needed for fts anymore (manylinux wheels).
- All C++ dev dependencies (zeromq, cppzmq, curl, yaml-cpp, Qt5/Qt6 devel)
  are present on this node; heartbeatmonitor's cpp_sender fetches
  nlohmann/json at configure time (needs network on first configure).
