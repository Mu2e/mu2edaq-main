#!/usr/bin/env bash
# Build and install every mu2edaq-* package for compatibility testing.
#
#   ./mu2edaq-build-all.sh [options] [package ...]
#
# Python packages get an isolated venv under .compat/venvs/<pkg> with their
# requirements.txt (and, where present, an editable pyproject install).
# CMake packages are configured and built under .compat/build/<pkg>.
# With --combined, all Python requirements are additionally installed into a
# single shared venv so pip's resolver can surface cross-package conflicts.
#
# Results land in .compat/status/build.tsv; logs in .compat/logs/build/.
# The script keeps going after failures and exits nonzero if any occurred.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
. "$ROOT/testing/common.sh"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

DO_COMBINED=0
CLEAN=0
PKG_ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --combined) DO_COMBINED=1 ;;
    --clean)    CLEAN=1 ;;
    -h|--help)  usage ;;
    -*)         warn "unknown option $1"; usage ;;
    *)          PKG_ARGS="$PKG_ARGS $1" ;;
  esac
  shift
done

BLOG="$LOG_DIR/build"
mkdir -p "$BLOG"
: > "$STATUS_DIR/build.tsv"

if [ "$CLEAN" = 1 ]; then
  note "Cleaning $VENV_DIR and $BUILD_DIR"
  rm -rf "$VENV_DIR" "$BUILD_DIR"
  mkdir -p "$VENV_DIR" "$BUILD_DIR"
fi

NPROC=$( (nproc || sysctl -n hw.ncpu) 2>/dev/null | head -1 )
NPROC=${NPROC:-4}

# ------------------------------------------------------------------ python --

build_venv() {
  local pkg="$1" logf="$BLOG/$pkg-venv.log" vpy rc=0
  vpy=$(venv_python "$pkg")
  : > "$logf"

  if [ ! -x "$vpy" ]; then
    if ! run_logged "$logf" "$PYTHON" -m venv "$VENV_DIR/$pkg"; then
      record build "$pkg" venv-create FAIL "$logf"; return 1
    fi
  fi
  run_logged "$logf" "$vpy" -m pip install -q --upgrade pip setuptools wheel \
    || warn "$pkg: pip self-upgrade failed (continuing)"
  # pytest is the harness's own requirement in every venv
  run_logged "$logf" "$vpy" -m pip install -q pytest || true
  record build "$pkg" venv-create PASS "$logf"

  # sibling checkouts first (e.g. controlroom-setup needs mu2edaq-discovery)
  local sib
  for sib in $(pkg_sibling_deps "$pkg"); do
    if run_logged "$logf" "$vpy" -m pip install -q "$ROOT/$sib"; then
      record build "$pkg" "sibling:$sib" PASS "$logf"
    else
      record build "$pkg" "sibling:$sib" FAIL "$logf"; rc=1
    fi
  done

  if [ -f "$ROOT/$pkg/requirements.txt" ]; then
    if run_logged "$logf" "$vpy" -m pip install -r "$ROOT/$pkg/requirements.txt"; then
      record build "$pkg" pip-requirements PASS "$logf"
    else
      rc=1
      record build "$pkg" pip-requirements FAIL "$logf"
      # retry line by line so the report names the exact offender(s)
      local rline
      grep -vE '^\s*(#|$|-)' "$ROOT/$pkg/requirements.txt" | while read -r rline; do
        if run_logged "$logf" "$vpy" -m pip install "$rline"; then
          record build "$pkg" "pip:$rline" PASS "$logf"
        else
          record build "$pkg" "pip:$rline" FAIL "$logf"
        fi
      done
    fi
  fi

  local spec
  spec=$(pkg_editable_spec "$pkg")
  if [ -n "$spec" ]; then
    if (cd "$ROOT/$pkg" && run_logged "$logf" "$vpy" -m pip install -e "$spec"); then
      record build "$pkg" pip-editable PASS "$logf"
    else
      record build "$pkg" pip-editable FAIL "$logf"; rc=1
    fi
  fi
  return $rc
}

# ------------------------------------------------------------------- cmake --

build_cmake() {
  local pkg="$1" src="$2" rc=0
  local tag="$pkg"
  [ "$src" != "." ] && tag="$pkg--$(echo "$src" | tr / -)"
  local bdir="$BUILD_DIR/$tag" logf="$BLOG/$tag-cmake.log"
  : > "$logf"

  if run_logged "$logf" cmake -S "$ROOT/$pkg/$src" -B "$bdir" \
       -DCMAKE_BUILD_TYPE=RelWithDebInfo; then
    record build "$pkg" "cmake-configure:$src" PASS "$logf"
  else
    record build "$pkg" "cmake-configure:$src" FAIL "$logf"
    return 1
  fi
  if run_logged "$logf" cmake --build "$bdir" -j "$NPROC"; then
    record build "$pkg" "cmake-build:$src" PASS "$logf"
  else
    record build "$pkg" "cmake-build:$src" FAIL "$logf"; rc=1
  fi
  return $rc
}

# ---------------------------------------------------------------- combined --

build_combined() {
  local logf="$BLOG/_combined-venv.log" vpy="$VENV_DIR/_combined/bin/python" rc=0
  : > "$logf"
  note "Combined-venv dependency conflict check"
  [ -x "$vpy" ] || "$PYTHON" -m venv "$VENV_DIR/_combined" >> "$logf" 2>&1
  run_logged "$logf" "$vpy" -m pip install -q --upgrade pip setuptools wheel || true

  local args="" pkg
  for pkg in $(pkg_list); do
    [ -f "$ROOT/$pkg/requirements.txt" ] && args="$args -r $ROOT/$pkg/requirements.txt"
  done
  # shellcheck disable=SC2086
  if run_logged "$logf" "$vpy" -m pip install $args; then
    record build _combined pip-all-requirements PASS "$logf"
  else
    record build _combined pip-all-requirements FAIL "$logf"; rc=1
  fi
  run_logged "$logf" "$vpy" -m pip check \
    && record build _combined pip-check PASS "$logf" \
    || { record build _combined pip-check FAIL "$logf"; rc=1; }
  return $rc
}

# -------------------------------------------------------------------- main --

FAILED=""
# shellcheck disable=SC2086
for pkg in $(select_pkgs $PKG_ARGS); do
  note "Building $pkg"
  ok=1
  if pkg_needs_venv "$pkg"; then
    build_venv "$pkg" || ok=0
  fi
  for src in $(pkg_cmake_dirs "$pkg"); do
    build_cmake "$pkg" "$src" || ok=0
  done
  if ! pkg_needs_venv "$pkg" && [ -z "$(pkg_cmake_dirs "$pkg")" ]; then
    record build "$pkg" no-build-needed SKIP -
  fi
  [ "$ok" = 1 ] || FAILED="$FAILED $pkg"
done

if [ "$DO_COMBINED" = 1 ]; then
  build_combined || FAILED="$FAILED _combined"
fi

echo
note "Build summary ($STATUS_DIR/build.tsv):"
awk -F'\t' '{printf "  %-28s %-28s %s\n", $1, $2, $3}' "$STATUS_DIR/build.tsv"

if [ -n "$FAILED" ]; then
  warn "failures in:$FAILED"
  exit 1
fi
note "All builds succeeded."
