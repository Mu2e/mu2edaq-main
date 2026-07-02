# Source this file to work interactively with the compatibility-test builds
# produced by mu2edaq-build-all.sh:
#
#   source mu2edaq-setup-env.sh <package>     # activate that package's venv
#   source mu2edaq-setup-env.sh --list        # show what is available
#
# CMake build output directories for the named package (if any) are appended
# to PATH so built binaries are runnable directly.

_mu2edaq_root=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)
_mu2edaq_compat="${MU2EDAQ_COMPAT_DIR:-$_mu2edaq_root/.compat}"

if [ "${1:-}" = "--list" ] || [ -z "${1:-}" ]; then
  echo "Available venvs:"
  ls "$_mu2edaq_compat/venvs" 2>/dev/null | sed 's/^/  /' || echo "  (none - run ./mu2edaq-build-all.sh first)"
  echo "Available cmake builds:"
  ls "$_mu2edaq_compat/build" 2>/dev/null | sed 's/^/  /' || echo "  (none)"
else
  _mu2edaq_pkg="${1%/}"
  if [ -f "$_mu2edaq_compat/venvs/$_mu2edaq_pkg/bin/activate" ]; then
    # shellcheck disable=SC1090
    . "$_mu2edaq_compat/venvs/$_mu2edaq_pkg/bin/activate"
    echo "Activated venv for $_mu2edaq_pkg"
  fi
  for _mu2edaq_b in "$_mu2edaq_compat/build/$_mu2edaq_pkg" "$_mu2edaq_compat/build/$_mu2edaq_pkg"--*; do
    if [ -d "$_mu2edaq_b" ]; then
      PATH="$_mu2edaq_b:$PATH"
      echo "Added to PATH: $_mu2edaq_b"
    fi
  done
  export PATH
  export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-}"
  unset _mu2edaq_b _mu2edaq_pkg
fi
unset _mu2edaq_root _mu2edaq_compat
