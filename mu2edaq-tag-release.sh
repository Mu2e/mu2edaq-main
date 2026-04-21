#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <tag> [-m <message>] [--dry-run] [--no-push]

Create an annotated tag on mu2edaq-main and every submodule.

Arguments:
  tag            Tag name (e.g. v1.2.3)

Options:
  -m <message>   Tag annotation message (default: "Release <tag>")
  --dry-run      Print what would be done without making any changes
  --no-push      Create tags locally but do not push to remotes
  -h, --help     Show this help

EOF
  exit 1
}

TAG=""
MESSAGE=""
DRY_RUN=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m)        shift; MESSAGE="$1" ;;
    --dry-run) DRY_RUN=true ;;
    --no-push) NO_PUSH=true ;;
    -h|--help) usage ;;
    -*)        echo "Unknown option: $1"; usage ;;
    *)
      [[ -n "$TAG" ]] && { echo "Unexpected argument: $1"; usage; }
      TAG="$1"
      ;;
  esac
  shift
done

[[ -z "$TAG" ]] && { echo "Error: tag name required."; usage; }
[[ -z "$MESSAGE" ]] && MESSAGE="Release $TAG"

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

tag_repo() {
  local path="$1"
  local name="$2"

  # Check for existing tag
  if git -C "$path" rev-parse "$TAG" >/dev/null 2>&1; then
    echo "  SKIP $name: tag '$TAG' already exists"
    return
  fi

  echo "  TAG  $name ($TAG)"
  run git -C "$path" tag -a "$TAG" -m "$MESSAGE"

  if ! $NO_PUSH; then
    run git -C "$path" push origin "$TAG"
  fi
}

echo "==> Tagging submodules"
git submodule foreach --quiet 'echo $displaypath' | while read -r subpath; do
  tag_repo "$REPO_ROOT/$subpath" "$subpath"
done

echo "==> Tagging parent repo"
tag_repo "$REPO_ROOT" "mu2edaq-main"

echo ""
if $DRY_RUN; then
  echo "Dry run complete. No tags were created."
elif $NO_PUSH; then
  echo "Tags created locally. Push with:"
  echo "  git submodule foreach 'git push origin $TAG'"
  echo "  git push origin $TAG"
else
  echo "Release $TAG tagged and pushed for all repositories."
fi
