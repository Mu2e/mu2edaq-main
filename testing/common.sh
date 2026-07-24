# common.sh - shared manifest and helpers for the mu2edaq compatibility harness.
# Sourced by mu2edaq-build-all.sh and mu2edaq-test-all.sh.
# Must stay compatible with bash 3.2 (macOS default shell): no associative
# arrays, no mapfile, no ${var,,}.

COMPAT_DIR="${MU2EDAQ_COMPAT_DIR:-$ROOT/.compat}"
VENV_DIR="$COMPAT_DIR/venvs"
BUILD_DIR="$COMPAT_DIR/build"
LOG_DIR="$COMPAT_DIR/logs"
STATUS_DIR="$COMPAT_DIR/status"

PYTHON="${MU2EDAQ_PYTHON:-python3}"

mkdir -p "$VENV_DIR" "$BUILD_DIR" "$LOG_DIR" "$STATUS_DIR"

# keep bytecode out of the submodule working trees (needs python >= 3.8)
export PYTHONPYCACHEPREFIX="$COMPAT_DIR/pycache"

# ---------------------------------------------------------------- manifest --

# All mu2edaq-* packages under test, in dependency order
# (mu2edaq-discovery must precede mu2edaq-controlroom-setup, which installs it).
pkg_list() {
  cat <<'EOF'
mu2edaq-discovery
mu2edaq-bigredbox
mu2edaq-CFOControl
mu2edaq-cluster-tools
mu2edaq-controlcenter
mu2edaq-controlroom
mu2edaq-controlroom-setup
mu2edaq-dashboard
mu2edaq-dataformat-viewer
mu2edaq-desktop
mu2edaq-diskwatcher
mu2edaq-downtime-logger
mu2edaq-fts
mu2edaq-heartbeatmonitor
mu2edaq-kpp-scripts
mu2edaq-operations
mu2edaq-phone-notification-system
mu2edaq-resource-manager
mu2edaq-reverse-proxy
mu2edaq-runlog-db
mu2edaq-shifter-tools
mu2edaq-snapshot-viewer
mu2edaq-trigger-scalers
EOF
}

# Packages that get a pip venv (they ship requirements.txt and/or pyproject.toml).
pkg_needs_venv() {
  case "$1" in
    mu2edaq-CFOControl|mu2edaq-kpp-scripts|mu2edaq-shifter-tools|mu2edaq-trigger-scalers) return 1 ;;
    *) return 0 ;;
  esac
}

# Packages installed editable from pyproject.toml, with the extras to use.
# Prints the pip target ('.' plus extras); empty output = not editable.
pkg_editable_spec() {
  case "$1" in
    mu2edaq-discovery)          echo ".[dev,yaml]" ;;
    mu2edaq-cluster-tools)      echo ".[dev]" ;;
    mu2edaq-controlroom-setup)  echo ".[gui,dev]" ;;
    mu2edaq-desktop)            echo ".[test]" ;;
    mu2edaq-downtime-logger)    echo ".[dev]" ;;
    mu2edaq-phone-notification-system) echo ".[dev]" ;;
    mu2edaq-reverse-proxy)      echo ".[dev,yaml,gui,server]" ;;
    mu2edaq-snapshot-viewer)    echo ".[gui,test]" ;;
    *) echo "" ;;
  esac
}

# Sibling packages (paths relative to $ROOT) pip-installed into this
# package's venv before the package itself. mu2edaq-discovery is not on
# PyPI; packages that list it in requirements.txt/pyproject get it from
# the sibling checkout.
pkg_sibling_deps() {
  case "$1" in
    mu2edaq-bigredbox)         echo "mu2edaq-discovery" ;;
    mu2edaq-controlcenter)     echo "mu2edaq-discovery" ;;
    mu2edaq-controlroom-setup) echo "mu2edaq-discovery" ;;
    mu2edaq-dashboard)         echo "mu2edaq-discovery" ;;
    mu2edaq-dataformat-viewer) echo "mu2edaq-discovery" ;;
    mu2edaq-diskwatcher)       echo "mu2edaq-discovery" ;;
    mu2edaq-downtime-logger)   echo "mu2edaq-discovery" ;;
    mu2edaq-fts)               echo "mu2edaq-discovery" ;;
    mu2edaq-heartbeatmonitor)  echo "mu2edaq-discovery" ;;
    mu2edaq-phone-notification-system) echo "mu2edaq-discovery" ;;
    mu2edaq-resource-manager)  echo "mu2edaq-discovery" ;;
    mu2edaq-reverse-proxy)     echo "mu2edaq-discovery" ;;
    mu2edaq-runlog-db)         echo "mu2edaq-discovery" ;;
    mu2edaq-snapshot-viewer)   echo "mu2edaq-discovery" ;;
    *) echo "" ;;
  esac
}

# CMake source dirs within the package ('.' = package root). Space separated.
pkg_cmake_dirs() {
  case "$1" in
    mu2edaq-dashboard)          echo "." ;;
    mu2edaq-resource-manager)   echo "." ;;
    mu2edaq-trigger-scalers)    echo "." ;;
    mu2edaq-dataformat-viewer)  echo "cpp" ;;
    mu2edaq-heartbeatmonitor)   echo "cpp_sender" ;;
    mu2edaq-phone-notification-system) echo "." ;;
    *) echo "" ;;
  esac
}

# Directory (relative to package root) to run pytest in; empty = no pytest.
pkg_pytest_dir() {
  case "$1" in
    mu2edaq-cluster-tools)      echo "tests" ;;
    mu2edaq-controlroom)        echo "." ;;
    mu2edaq-controlroom-setup)  echo "tests" ;;
    mu2edaq-desktop)            echo "tests" ;;
    mu2edaq-discovery)          echo "tests" ;;
    mu2edaq-downtime-logger)    echo "tests" ;;
    mu2edaq-fts)                echo "tests" ;;
    mu2edaq-operations)         echo "tests" ;;
    mu2edaq-phone-notification-system) echo "tests" ;;
    mu2edaq-reverse-proxy)      echo "tests" ;;
    mu2edaq-snapshot-viewer)    echo "tests" ;;
    *) echo "" ;;
  esac
}

# CLI smoke commands, one per line, run from the package root with the
# package venv's bin first on PATH. Kept to --help/check style invocations
# that must not start servers or GUIs. All run under a timeout with
# QT_QPA_PLATFORM=offscreen.
pkg_cli_smokes() {
  case "$1" in
    mu2edaq-discovery)
      echo "mu2edaq-discover --help" ;;
    mu2edaq-controlroom-setup)
      printf '%s\n' "crs-tunnel --help" "crs-remote --help" ;;
    mu2edaq-downtime-logger)
      echo "mu2edaq-downtime-logger --help" ;;
    mu2edaq-dashboard)
      echo "python dashboard.py --help" ;;
    mu2edaq-diskwatcher)
      echo "python diskwatcher.py --help" ;;
    mu2edaq-fts)
      echo "python mu2edaq_fts.py --help" ;;
    mu2edaq-heartbeatmonitor)
      printf '%s\n' "python heartbeat_monitor.py --help" "python heartbeat_sender.py --help" ;;
    mu2edaq-dataformat-viewer)
      printf '%s\n' "python mu2edaq-dataformat-viewer.py --help" "python mu2edaq-dataformat-sender.py --help" ;;
    mu2edaq-operations)
      echo "python node_list.py --help" ;;
    mu2edaq-runlog-db)
      echo "python manage.py check" ;;
    mu2edaq-cluster-tools)
      printf '%s\n' "ssh-selector --help" "lan-scan --help" ;;
    mu2edaq-desktop)
      printf '%s\n' "mu2edaq-app --help" "mu2edaq-desktop-icons --help" "mu2edaq-launchpad --help" ;;
    mu2edaq-phone-notification-system)
      printf '%s\n' "mu2edaq-notify-server --help" "mu2edaq-notify --help" ;;
    mu2edaq-reverse-proxy)
      printf '%s\n' "mu2edaq-proxy --help" "mu2edaq-proxy-server --help" ;;
    mu2edaq-snapshot-viewer)
      printf '%s\n' "mu2edaq-snapshot-server --help" "mu2edaq-snapshot-client --help" \
                    "mu2edaq-snapshot-admin --help" ;;
    *) echo "" ;;
  esac
}

# Python modules that must import cleanly in the package venv (beyond the
# automatic requirements.txt scan done by smoke_imports.py). Space separated,
# usually the package's own importable modules.
#
# mu2edaq_discovery is appended automatically for every package that declares
# it as a sibling dep: it is not on PyPI and so is deliberately absent from
# requirements.txt, which means smoke_imports.py no longer sees it. Checking it
# here keeps the local-install path (sibling checkout / wheelhouse) verified.
pkg_import_smokes() {
  local extra=""
  case "$(pkg_sibling_deps "$1")" in
    *mu2edaq-discovery*) extra=" mu2edaq_discovery" ;;
  esac
  case "$1" in
    mu2edaq-discovery)          echo "mu2edaq_discovery" ;;
    mu2edaq-cluster-tools)      echo "mu2edaq_cluster_tools$extra" ;;
    mu2edaq-controlroom-setup)  echo "mu2edaq_controlroom_setup$extra" ;;
    mu2edaq-desktop)            echo "mu2edaq_desktop$extra" ;;
    mu2edaq-downtime-logger)    echo "downtime_logger$extra" ;;
    mu2edaq-phone-notification-system) echo "mu2edaq_notify$extra" ;;
    mu2edaq-reverse-proxy)      echo "mu2edaq_reverse_proxy$extra" ;;
    mu2edaq-snapshot-viewer)    echo "mu2edaq_snapshot_client mu2edaq_snapshot_server$extra" ;;
    *) echo "${extra# }" ;;
  esac
}

# ----------------------------------------------------------------- helpers --

say()  { printf '%s\n' "$*"; }
note() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

# record <phase> <pkg> <step> <PASS|FAIL|SKIP> <logfile-or-->
record() {
  printf '%s\t%s\t%s\t%s\t%s\n' "$2" "$3" "$4" "$5" "$(date '+%Y-%m-%dT%H:%M:%S')" \
    >> "$STATUS_DIR/$1.tsv"
}

# Portable timeout (macOS has no timeout(1)). with_timeout <secs> <cmd...>
with_timeout() {
  local secs="$1"; shift
  "$PYTHON" - "$secs" "$@" <<'PY'
import subprocess, sys
try:
    r = subprocess.run(sys.argv[2:], timeout=float(sys.argv[1]))
    sys.exit(r.returncode)
except subprocess.TimeoutExpired:
    print("TIMEOUT after %ss" % sys.argv[1], file=sys.stderr)
    sys.exit(124)
except FileNotFoundError as e:
    print(e, file=sys.stderr)
    sys.exit(127)
PY
}

# run_logged <logfile> <cmd...>  -> returns cmd status, output tee'd to log
run_logged() {
  local logf="$1"; shift
  { printf '$ %s\n' "$*"; "$@" 2>&1; } >> "$logf" 2>&1
}

venv_python() { echo "$VENV_DIR/$1/bin/python"; }

# Filter/validate a user-supplied package selection; default = all.
select_pkgs() {
  if [ $# -eq 0 ]; then
    pkg_list
    return
  fi
  local p known
  for p in "$@"; do
    p="${p%/}"
    known=$(pkg_list | grep -x "$p" || true)
    if [ -z "$known" ]; then
      warn "unknown package: $p (skipped)"
    else
      echo "$p"
    fi
  done
}
