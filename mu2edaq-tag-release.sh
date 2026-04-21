#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <tag> [-m <message>] [--dry-run] [--no-push]
       $(basename "$0") --rename <old-tag> <new-tag> [--dry-run] [--no-push]

Create an annotated tag on mu2edaq-main and every submodule,
or rename an existing tag across all repositories.

Arguments:
  tag            Tag name to create (e.g. v1.2.3)

Options:
  -m <message>   Tag annotation message (default: "Release <tag>")
  --rename       Rename old-tag to new-tag across all repositories
  --dry-run      Print what would be done without making any changes
  --no-push      Create/rename tags locally but do not push to remotes
  -h, --help     Show this help

EOF
  exit 1
}

TAG=""
OLD_TAG=""
MESSAGE=""
DRY_RUN=false
NO_PUSH=false
RENAME=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m)        shift; MESSAGE="$1" ;;
    --rename)  RENAME=true ;;
    --dry-run) DRY_RUN=true ;;
    --no-push) NO_PUSH=true ;;
    -h|--help) usage ;;
    -*)        echo "Unknown option: $1"; usage ;;
    *)
      if $RENAME && [[ -z "$OLD_TAG" ]]; then
        OLD_TAG="$1"
      elif [[ -z "$TAG" ]]; then
        TAG="$1"
      else
        echo "Unexpected argument: $1"; usage
      fi
      ;;
  esac
  shift
done

if $RENAME; then
  [[ -z "$OLD_TAG" || -z "$TAG" ]] && { echo "Error: --rename requires <old-tag> and <new-tag>."; usage; }
else
  [[ -z "$TAG" ]] && { echo "Error: tag name required."; usage; }
  [[ -z "$MESSAGE" ]] && MESSAGE="Release $TAG"
fi

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

rename_tag_repo() {
  local path="$1"
  local name="$2"

  if ! git -C "$path" rev-parse "$OLD_TAG" >/dev/null 2>&1; then
    echo "  SKIP $name: tag '$OLD_TAG' not found"
    return
  fi

  if git -C "$path" rev-parse "$TAG" >/dev/null 2>&1; then
    echo "  SKIP $name: tag '$TAG' already exists"
    return
  fi

  local commit
  commit=$(git -C "$path" rev-list -n1 "$OLD_TAG")
  local msg
  msg=$(git -C "$path" tag -l --format='%(contents)' "$OLD_TAG")
  [[ -z "$msg" ]] && msg="Renamed from $OLD_TAG"

  echo "  RENAME $name ($OLD_TAG -> $TAG)"
  run git -C "$path" tag -a "$TAG" "$commit" -m "$msg"
  run git -C "$path" tag -d "$OLD_TAG"

  if ! $NO_PUSH; then
    run git -C "$path" push origin "$TAG"
    run git -C "$path" push origin ":refs/tags/$OLD_TAG"
  fi
}

if $RENAME; then
  echo "==> Renaming tag '$OLD_TAG' -> '$TAG' in submodules"
  git submodule foreach --quiet 'echo $displaypath' | while read -r subpath; do
    rename_tag_repo "$REPO_ROOT/$subpath" "$subpath"
  done

  echo "==> Renaming tag in parent repo"
  rename_tag_repo "$REPO_ROOT" "mu2edaq-main"

  echo ""
  if $DRY_RUN; then
    echo "Dry run complete. No tags were renamed."
  elif $NO_PUSH; then
    echo "Tags renamed locally. Push with:"
    echo "  git submodule foreach 'git push origin $TAG :refs/tags/$OLD_TAG'"
    echo "  git push origin $TAG :refs/tags/$OLD_TAG"
  else
    echo "Tag '$OLD_TAG' renamed to '$TAG' across all repositories."
  fi
else
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
fi
