#!/usr/bin/env bash
# Test every mu2edaq-* package built by mu2edaq-build-all.sh.
#
#   ./mu2edaq-test-all.sh [package ...]
#
# Per package: byte-compile all Python sources with the package venv (or the
# system python for script-only packages), import every declared dependency,
# run bash -n over shell scripts, run CLI --help smokes, pytest suites, and
# ctest where a CMake build defines tests. GUI/Qt code runs offscreen.
#
# Results land in .compat/status/test.tsv; logs in .compat/logs/test/.
# A markdown report is written to .compat/report.md at the end.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
. "$ROOT/testing/common.sh"

TLOG="$LOG_DIR/test"
mkdir -p "$TLOG"
: > "$STATUS_DIR/test.tsv"

export QT_QPA_PLATFORM=offscreen
SMOKE_TIMEOUT="${MU2EDAQ_SMOKE_TIMEOUT:-30}"
PYTEST_TIMEOUT="${MU2EDAQ_PYTEST_TIMEOUT:-600}"

# python interpreter to use for a package (venv if present, else system)
pkg_python() {
  local vpy
  vpy=$(venv_python "$1")
  if [ -x "$vpy" ]; then echo "$vpy"; else echo "$PYTHON"; fi
}

test_pycompile() {
  local pkg="$1" logf="$TLOG/$pkg-pycompile.log" py rc=0
  py=$(pkg_python "$pkg")
  : > "$logf"
  local n
  n=$(find "$ROOT/$pkg" -name '*.py' -not -path '*/.git/*' -not -path '*/venv/*' | wc -l)
  if [ "$n" -eq 0 ]; then
    record test "$pkg" py-compile SKIP -
    return 0
  fi
  if find "$ROOT/$pkg" -name '*.py' -not -path '*/.git/*' -not -path '*/venv/*' -print0 \
      | xargs -0 "$py" -m py_compile >> "$logf" 2>&1; then
    record test "$pkg" py-compile PASS "$logf"
  else
    record test "$pkg" py-compile FAIL "$logf"; rc=1
  fi
  return $rc
}

test_shellsyntax() {
  local pkg="$1" logf="$TLOG/$pkg-shell.log" rc=0 f
  : > "$logf"
  local found=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    found=1
    if ! bash -n "$f" >> "$logf" 2>&1; then
      echo "SYNTAX FAIL: $f" >> "$logf"; rc=1
    fi
  done <<EOF
$(find "$ROOT/$pkg" -name '*.sh' -not -path '*/.git/*' -not -path '*/venv/*')
EOF
  if [ "$found" = 0 ]; then
    record test "$pkg" shell-syntax SKIP -
  elif [ "$rc" = 0 ]; then
    record test "$pkg" shell-syntax PASS "$logf"
  else
    record test "$pkg" shell-syntax FAIL "$logf"
  fi
  return $rc
}

test_imports() {
  local pkg="$1" logf="$TLOG/$pkg-imports.log" vpy rc=0
  vpy=$(venv_python "$pkg")
  [ -x "$vpy" ] || { record test "$pkg" dep-imports SKIP -; return 0; }
  : > "$logf"
  local reqs="$ROOT/$pkg/requirements.txt" extra
  extra=$(pkg_import_smokes "$pkg")
  if [ ! -f "$reqs" ] && [ -z "$extra" ]; then
    record test "$pkg" dep-imports SKIP -
    return 0
  fi
  [ -f "$reqs" ] || reqs=/dev/null
  # shellcheck disable=SC2086
  if run_logged "$logf" with_timeout "$SMOKE_TIMEOUT" \
      "$vpy" "$ROOT/testing/smoke_imports.py" "$reqs" $extra; then
    record test "$pkg" dep-imports PASS "$logf"
  else
    record test "$pkg" dep-imports FAIL "$logf"; rc=1
  fi
  return $rc
}

test_cli_smokes() {
  local pkg="$1" rc=0 line n=0
  local vbin="$VENV_DIR/$pkg/bin"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    n=$((n + 1))
    local logf="$TLOG/$pkg-cli$n.log"
    : > "$logf"
    if (cd "$ROOT/$pkg" && PATH="$vbin:$PATH" \
          run_logged "$logf" with_timeout "$SMOKE_TIMEOUT" $line); then
      record test "$pkg" "cli:$line" PASS "$logf"
    else
      record test "$pkg" "cli:$line" FAIL "$logf"; rc=1
    fi
  done <<EOF
$(pkg_cli_smokes "$pkg")
EOF
  return $rc
}

test_pytest() {
  local pkg="$1" tdir logf="$TLOG/$pkg-pytest.log" vpy rc=0
  tdir=$(pkg_pytest_dir "$pkg")
  [ -n "$tdir" ] || { record test "$pkg" pytest SKIP -; return 0; }
  vpy=$(venv_python "$pkg")
  [ -x "$vpy" ] || { record test "$pkg" pytest SKIP -; return 0; }
  : > "$logf"
  if (cd "$ROOT/$pkg" && \
        run_logged "$logf" with_timeout "$PYTEST_TIMEOUT" "$vpy" -m pytest "$tdir" -ra -p no:cacheprovider); then
    record test "$pkg" pytest PASS "$logf"
  else
    record test "$pkg" pytest FAIL "$logf"; rc=1
  fi
  return $rc
}

test_ctest() {
  local pkg="$1" rc=0 src tag bdir
  for src in $(pkg_cmake_dirs "$pkg"); do
    tag="$pkg"
    [ "$src" != "." ] && tag="$pkg--$(echo "$src" | tr / -)"
    bdir="$BUILD_DIR/$tag"
    [ -f "$bdir/CTestTestfile.cmake" ] || continue
    local logf="$TLOG/$tag-ctest.log"
    : > "$logf"
    if run_logged "$logf" with_timeout "$PYTEST_TIMEOUT" \
        ctest --test-dir "$bdir" --output-on-failure; then
      record test "$pkg" "ctest:$src" PASS "$logf"
    else
      record test "$pkg" "ctest:$src" FAIL "$logf"; rc=1
    fi
  done
  return $rc
}

# -------------------------------------------------------------------- main --

FAILED=""
# shellcheck disable=SC2086
for pkg in $(select_pkgs "$@"); do
  note "Testing $pkg"
  ok=1
  test_pycompile   "$pkg" || ok=0
  test_shellsyntax "$pkg" || ok=0
  test_imports     "$pkg" || ok=0
  test_cli_smokes  "$pkg" || ok=0
  test_pytest      "$pkg" || ok=0
  test_ctest       "$pkg" || ok=0
  [ "$ok" = 1 ] || FAILED="$FAILED $pkg"
done

echo
note "Test summary ($STATUS_DIR/test.tsv):"
awk -F'\t' '{printf "  %-28s %-44s %s\n", $1, $2, $3}' "$STATUS_DIR/test.tsv"

"$PYTHON" "$ROOT/testing/report.py" "$STATUS_DIR" "$COMPAT_DIR/report.md" \
  && note "Report written to $COMPAT_DIR/report.md"

if [ -n "$FAILED" ]; then
  warn "failures in:$FAILED"
  exit 1
fi
note "All tests passed."
