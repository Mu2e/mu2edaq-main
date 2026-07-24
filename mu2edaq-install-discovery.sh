#!/bin/bash
#
# Install mu2edaq-discovery into a Python environment, without PyPI.
#
# mu2edaq-discovery is stdlib-only and is not published on PyPI, so it cannot
# be named as a resolvable requirement in a requirements.txt. This script is
# the supported way to add it to an environment. It is offline-safe.
#
# Usage:
#   ./mu2edaq-install-discovery.sh [--python PY] [--editable] [--wheel-dir DIR]
#   ./mu2edaq-install-discovery.sh --build-wheel [--wheel-dir DIR]
#
# Options:
#   --python PY     interpreter/venv to install into (default: python3 on PATH,
#                   i.e. the active virtualenv)
#   --editable      install as an editable checkout instead of a copy
#   --wheel-dir DIR wheelhouse to install from / build into
#                   (default: $MU2EDAQ_WHEELHOUSE, else <root>/.wheelhouse)
#   --build-wheel   build a wheel into the wheelhouse and exit; do this once on
#                   a networked machine, then copy the wheelhouse to offline
#                   nodes and run this script normally there
#
# Resolution order when installing:
#   1. a prebuilt mu2edaq_discovery-*.whl in the wheelhouse   (fully offline)
#   2. the sibling source checkout ../mu2edaq-discovery       (offline if the
#      target env can build a wheel -- see below)
#
# Note on (2): mu2edaq-discovery declares its metadata in setup.cfg precisely
# so it builds with the setuptools 53 that a stock AlmaLinux 9 venv ships, so
# no setuptools upgrade is needed. Building a wheel does still require the
# `wheel` package in the target environment. AL9 has it system-wide
# (python3-wheel), so `python3 -m venv --system-site-packages` gets it for
# free; a plain venv does not, and would need it from the network. The
# wheelhouse path avoids the question entirely.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
SRC="$ROOT/mu2edaq-discovery"

PY="python3"
EDITABLE=0
BUILD_WHEEL=0
WHEEL_DIR="${MU2EDAQ_WHEELHOUSE:-$ROOT/.wheelhouse}"

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --python)      PY="$2"; shift ;;
    --editable)    EDITABLE=1 ;;
    --wheel-dir)   WHEEL_DIR="$2"; shift ;;
    --build-wheel) BUILD_WHEEL=1 ;;
    -h|--help)     usage ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
  shift
done

if [ ! -d "$SRC" ]; then
  echo "error: $SRC not found." >&2
  echo "       Run this from a mu2edaq-main checkout with submodules initialized:" >&2
  echo "       git submodule update --init mu2edaq-discovery" >&2
  exit 1
fi

if [ "$BUILD_WHEEL" = 1 ]; then
  mkdir -p "$WHEEL_DIR"
  echo "==> Building mu2edaq-discovery wheel into $WHEEL_DIR"
  "$PY" -m pip wheel --no-deps -w "$WHEEL_DIR" "$SRC"
  echo "==> Done. Copy $WHEEL_DIR to offline nodes and install with:"
  echo "    ./mu2edaq-install-discovery.sh --wheel-dir <dir>"
  exit 0
fi

# 1. Prefer a prebuilt wheel: no build step, no network, no setuptools floor.
if [ -d "$WHEEL_DIR" ] && ls "$WHEEL_DIR"/mu2edaq_discovery-*.whl >/dev/null 2>&1; then
  echo "==> Installing mu2edaq-discovery from wheelhouse $WHEEL_DIR"
  "$PY" -m pip install --no-index --find-links "$WHEEL_DIR" mu2edaq-discovery
else
  # 2. Build from the sibling checkout. setup.cfg metadata means the stock AL9
  #    setuptools 53 is new enough; only `wheel` has to be present for an
  #    offline (--no-build-isolation) build.
  echo "==> Installing mu2edaq-discovery from $SRC"
  ISOLATION="--no-build-isolation"
  if ! "$PY" -c 'import wheel' 2>/dev/null; then
    echo "    note: 'wheel' is not available to $PY, so this build needs network."
    echo "          Offline alternatives: use --wheel-dir with a prebuilt wheel,"
    echo "          or create the venv with 'python3 -m venv --system-site-packages'"
    echo "          so it picks up the system python3-wheel."
    ISOLATION=""
  fi
  if [ "$EDITABLE" = 1 ]; then
    "$PY" -m pip install $ISOLATION -e "$SRC"
  else
    "$PY" -m pip install $ISOLATION "$SRC"
  fi
fi

"$PY" -c 'from mu2edaq_discovery import Responder; print("==> mu2edaq-discovery OK:", Responder.__module__)'
