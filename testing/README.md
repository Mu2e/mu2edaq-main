# mu2edaq compatibility-test harness

Master build/test scripts for all `mu2edaq-*` packages. The primary target is
the AlmaLinux 9 production platform (system Python 3.9); the scripts are kept
bash-3.2-clean so they also run on macOS.

## Usage (from the mu2edaq-main root)

```bash
./mu2edaq-build-all.sh                 # build/install everything
./mu2edaq-build-all.sh --combined      # + all requirements in ONE venv (conflict check)
./mu2edaq-build-all.sh --clean         # wipe venvs/builds first
./mu2edaq-build-all.sh mu2edaq-fts     # just one package

./mu2edaq-test-all.sh                  # test everything, write .compat/report.md
./mu2edaq-test-all.sh mu2edaq-fts      # just one package

source mu2edaq-setup-env.sh <package>  # activate a package's venv + build PATH
source mu2edaq-setup-env.sh --list     # what's available
```

## What it does per package

- **Python packages**: isolated venv under `.compat/venvs/<pkg>`;
  `pip install -r requirements.txt`; editable `pip install -e .[extras]` where
  a pyproject exists; sibling checkouts installed first where needed
  (controlroom-setup ← discovery). On a requirements failure it retries line
  by line so the report names the exact offending dependency.
- **CMake components**: configure + build under `.compat/build/` (dashboard,
  resource-manager, trigger-scalers, dataformat-viewer/cpp,
  heartbeatmonitor/cpp_sender).
- **Tests**: byte-compile every `.py` with the package venv's interpreter,
  import every declared dependency (`testing/smoke_imports.py`), `bash -n`
  every shell script, CLI `--help` smokes (offscreen Qt, with timeout),
  pytest suites, and ctest where CMake defines tests.
- **Report**: `.compat/status/{build,test}.tsv` aggregated into
  `.compat/report.md` with log tails for every failure.

## Layout

```
mu2edaq-build-all.sh    orchestrates builds/installs
mu2edaq-test-all.sh     orchestrates tests, generates report
mu2edaq-setup-env.sh    sourceable env helper
testing/common.sh       package manifest + shared helpers
testing/smoke_imports.py  requirements.txt -> import verification
testing/report.py       TSV -> markdown report
.compat/                all artifacts (gitignored)
```

Adding a package: append it to `pkg_list` in `testing/common.sh` and, if it
needs anything beyond a requirements.txt venv, add cases to the manifest
functions (`pkg_editable_spec`, `pkg_cmake_dirs`, `pkg_pytest_dir`,
`pkg_cli_smokes`, ...).

Environment knobs: `MU2EDAQ_PYTHON` (interpreter for venvs, default
`python3`), `MU2EDAQ_COMPAT_DIR` (artifact dir), `MU2EDAQ_SMOKE_TIMEOUT`,
`MU2EDAQ_PYTEST_TIMEOUT`.

Man pages: `man ../man/man1/mu2edaq-build-all.1`,
`man ../man/man1/mu2edaq-test-all.1`, `man ../man/man1/mu2edaq-setup-env.1`
(paths relative to this directory; from the repo root drop the `../`).
