#!/usr/bin/env bash
# Fetch and fast-forward every submodule from its remote, then commit the
# resulting pointer bumps in mu2edaq-main (following the "Bump ..." commit
# convention already used in this repo's history).
#
# Safe to run from a detached HEAD, in mu2edaq-main or in any submodule:
# each submodule is moved onto the branch it was already tracking, or the
# remote's default branch if it was detached, before being fast-forwarded.
# Submodules with local changes or diverged history are left untouched.
set -uo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository." >&2
  exit 1
}
cd "$ROOT"

note() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [submodule-path ...]

Fetch and fast-forward every submodule from its remote, then commit the
resulting pointer bumps in mu2edaq-main. Restrict to specific submodules by
naming their paths (as shown by 'git submodule status').

Options:
  --dry-run     Fetch only; report what would change, make no local changes
  --no-commit   Update submodule checkouts and stage them, but do not commit
  --no-edit     Commit with the generated message as-is (skip \$EDITOR)
  -h, --help    Show this help

EOF
  exit 1
}

DRY_RUN=false
NO_COMMIT=false
NO_EDIT=false
declare -a ONLY=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true ;;
    --no-commit) NO_COMMIT=true ;;
    --no-edit)   NO_EDIT=true ;;
    -h|--help)   usage ;;
    -*)          echo "Unknown option: $1"; usage ;;
    *)           ONLY+=("$1") ;;
  esac
  shift
done

if [[ -z "$(git symbolic-ref -q HEAD 2>/dev/null)" ]]; then
  warn "mu2edaq-main is in detached HEAD state; any bump commit created here"
  warn "will not be reachable from a branch until you 'git checkout -b <name>'."
fi

declare -a ALL_SUBMODULES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && ALL_SUBMODULES+=("$line")
done < <(git submodule foreach -q 'echo $sm_path')

if [[ ${#ONLY[@]} -gt 0 ]]; then
  for o in "${ONLY[@]}"; do
    found=false
    for s in "${ALL_SUBMODULES[@]}"; do [[ "$s" == "$o" ]] && found=true; done
    $found || warn "unknown submodule: $o (skipped)"
  done
fi

# Branch a detached submodule should track: its recorded default branch on
# the remote (falls back to plain 'main' if that can't be determined).
default_branch() {
  local path="$1" ref
  ref=$(git -C "$path" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null) || true
  if [[ -n "$ref" ]]; then
    echo "${ref#origin/}"
    return
  fi
  ref=$(git -C "$path" ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/{print $2; exit}')
  if [[ -n "$ref" ]]; then
    echo "${ref#refs/heads/}"
    return
  fi
  echo "main"
}

declare -a UPDATED_PATHS=()
declare -a UPDATED_SUMMARY=()

update_submodule() {
  local path="$1" name="$2"

  if [[ ! -e "$path/.git" ]]; then
    echo "  SKIP $name: not initialized"
    return
  fi

  if [[ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]]; then
    warn "SKIP $name: has local changes, leaving untouched"
    return
  fi

  local old_sha
  old_sha=$(git -C "$path" rev-parse HEAD)

  if ! git -C "$path" fetch --quiet origin; then
    warn "SKIP $name: fetch failed"
    return
  fi

  local branch
  branch=$(git -C "$path" symbolic-ref -q --short HEAD 2>/dev/null) || true
  [[ -z "$branch" ]] && branch=$(default_branch "$path")

  if ! git -C "$path" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    warn "SKIP $name: no 'origin/$branch' on remote"
    return
  fi

  local n
  n=$(git -C "$path" rev-list --count "HEAD..origin/$branch")
  if [[ "$n" -eq 0 ]]; then
    echo "  OK   $name: $branch up to date"
    return
  fi

  if $DRY_RUN; then
    echo "  PULL $name: $branch, $n commit(s) available"
    return
  fi

  if git -C "$path" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$path" checkout --quiet "$branch"
  else
    git -C "$path" checkout --quiet -b "$branch" --track "origin/$branch"
  fi

  if ! git -C "$path" merge --ff-only --quiet "origin/$branch" 2>/dev/null; then
    warn "SKIP $name: '$branch' has diverged from origin/$branch (not fast-forwardable)"
    return
  fi

  local new_sha
  new_sha=$(git -C "$path" rev-parse HEAD)
  if [[ "$new_sha" == "$old_sha" ]]; then
    echo "  OK   $name: $branch up to date"
    return
  fi

  echo "  BUMP $name: $branch, $n commit(s)"
  UPDATED_PATHS+=("$path")
  UPDATED_SUMMARY+=("$name: $branch, $n commit(s)")
}

note "Updating submodules"
for path in "${ALL_SUBMODULES[@]}"; do
  [[ -z "$path" ]] && continue
  if [[ ${#ONLY[@]} -gt 0 ]]; then
    match=false
    for o in "${ONLY[@]}"; do [[ "$o" == "$path" ]] && match=true; done
    $match || continue
  fi
  update_submodule "$path" "$path"
done

if $DRY_RUN; then
  echo
  note "Dry run complete. No changes made."
  exit 0
fi

if [[ ${#UPDATED_PATHS[@]} -eq 0 ]]; then
  echo
  note "All submodules already up to date."
  exit 0
fi

git add "${UPDATED_PATHS[@]}"

if [[ ${#UPDATED_PATHS[@]} -eq 1 ]]; then
  MSG="Bump ${UPDATED_SUMMARY[0]}"
else
  MSG="Bump ${#UPDATED_PATHS[@]} submodules:
$(printf '  %s\n' "${UPDATED_SUMMARY[@]}")"
fi

echo
note "Staged ${#UPDATED_PATHS[@]} submodule bump(s)"

if $NO_COMMIT; then
  echo "Changes staged but not committed. Commit with:"
  echo "  git commit"
  exit 0
fi

if $NO_EDIT; then
  git commit --quiet -m "$MSG"
else
  git commit -e -m "$MSG"
fi

note "Committed submodule bumps. Push with:"
echo "  git push"
