#!/usr/bin/env bash
set -euo pipefail

REPO_URL="git@github.com:Mu2e/mu2edaq-main.git"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  clone               Clone mu2edaq-main with all submodules
  update [<name>]     Pull latest commits for all submodules, or a named one
  bump [<name>]       Stage and commit updated submodule pointer(s) in parent repo
  status              Show commit status of all submodules vs their remotes

EOF
  exit 1
}

cmd_clone() {
  git clone --recurse-submodules "$REPO_URL"
  echo "Cloned mu2edaq-main with all submodules."
}

cmd_update() {
  local name="${1:-}"
  if [[ -n "$name" ]]; then
    echo "Updating submodule: $name"
    git submodule update --remote --merge "$name"
  else
    echo "Updating all submodules..."
    git submodule update --remote --merge
  fi
  echo "Done. Run '$0 bump' to commit any pointer changes to the parent repo."
}

cmd_bump() {
  local name="${1:-}"
  if [[ -n "$name" ]]; then
    git add "$name"
    git commit -m "Bump $name to latest"
  else
    # Only stage submodule entries that have changed
    git submodule foreach --quiet 'echo $name' | while read -r mod; do
      if ! git diff --quiet "$mod"; then
        git add "$mod"
      fi
    done
    if git diff --cached --quiet; then
      echo "No submodule pointers changed."
      exit 0
    fi
    git commit -m "Bump submodules to latest"
  fi
  echo "Committed. Run 'git push' to push to origin."
}

cmd_status() {
  echo "Submodule status (local commit vs remote HEAD):"
  git submodule foreach --quiet '
    local=$(git rev-parse --short HEAD)
    remote=$(git rev-parse --short origin/$(git rev-parse --abbrev-ref HEAD) 2>/dev/null || echo "unknown")
    if [ "$local" = "$remote" ]; then
      state="up-to-date"
    else
      state="BEHIND or DIVERGED"
    fi
    echo "  $name: local=$local remote=$remote [$state]"
  '
}

[[ $# -lt 1 ]] && usage

COMMAND="$1"
shift

case "$COMMAND" in
  clone)  cmd_clone "$@" ;;
  update) cmd_update "$@" ;;
  bump)   cmd_bump "$@" ;;
  status) cmd_status "$@" ;;
  *)      usage ;;
esac
