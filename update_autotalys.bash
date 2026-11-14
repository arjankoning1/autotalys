#!/usr/bin/env bash
# Incrementally update a Git-based AUTOTALYS installation.
# Arjan Koning / AUTOTALYS
#
# Usage: update_autotalys.bash [INSTALL_DIR] [--dry-run] [--only NAME]
#
# --dry-run fetches Git metadata but changes no checked-out files.
# A missing package is cloned; existing packages are fast-forwarded only.
# Local source modifications and diverged branches are never discarded.
# Run install_autotalys.bash separately after updating the source repositories.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: update_autotalys.bash [INSTALL_DIR] [options]

INSTALL_DIR defaults to $HOME/autotalys.

Options:
  --dry-run        Fetch remote references and show planned actions only
  --only NAME      Update only the named package (e.g. talys, autoendf)
  -h, --help       Show this help

A Git installation (from clone_autotalys.bash) is required. Archive-based
installations are not updated in place. This script only updates source
repositories; run install_autotalys.bash separately to rebuild and relink.
USAGE
}

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; }

ROOT="${HOME}/autotalys"
DRY_RUN=0
ONLY=""
ROOT_SET=0

while (( $# > 0 )); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --only)
      if (( $# < 2 )) || [[ "$2" == -* ]]; then
        fail "--only requires a package name"; exit 2
      fi
      ONLY="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) fail "unknown option: $1"; usage >&2; exit 2 ;;
    *)
      if (( ROOT_SET )); then fail "only one installation path is allowed"; exit 2; fi
      ROOT="$1"; ROOT_SET=1 ;;
  esac
  shift
done

command -v git >/dev/null 2>&1 || { fail "Git is required"; exit 1; }
[[ -d "$ROOT" ]] || { fail "installation directory does not exist: $ROOT"; exit 1; }
ROOT="$(cd "$ROOT" && pwd -P)"

# Keep this list aligned with clone_autotalys.bash and download_autotalys.bash.
# Missing entries are cloned automatically. Case and spelling matter.
PACKAGES=(
  talys tefal tasman endftables autonorm autoendf autotalys_tools
  resonancetables resbase nubarbase fnsbase exfortables
  NJOY2016 PREPRO ENDF-utility-codes fudge
)

repo_url() {
  case "$1" in
    NJOY2016) printf '%s\n' 'https://github.com/njoy/NJOY2016.git' ;;
    PREPRO) printf '%s\n' 'https://github.com/IAEA-NDS/PREPRO.git' ;;
    ENDF-utility-codes) printf '%s\n' 'https://github.com/IAEA-NDS/ENDF-utility-codes.git' ;;
    fudge) printf '%s\n' 'https://github.com/LLNL/fudge.git' ;;
    *) printf 'https://github.com/arjankoning1/%s.git\n' "$1" ;;
  esac
}

if [[ -n "$ONLY" ]]; then
  found=0
  for package in "${PACKAGES[@]}"; do
    if [[ "$package" == "$ONLY" ]]; then found=1; break; fi
  done
  (( found )) || { fail "unknown package: $ONLY"; exit 2; }
fi

# Only the supported generated binaries may be locally modified without
# preventing a source update. Git will still reject any conflicting merge.
is_expected_generated_change() {
  local repo="$1" path="$2" dir="$ROOT/$1"
  # The current full installer applies this one known PREPRO build patch.
  # Accept it only when it is EXACTLY the expected one-line substitution.
  if [[ "$repo" == PREPRO && "$path" == source/EVALPLOT/evalplot.h ]]; then
    if git -C "$dir" show 'HEAD:source/EVALPLOT/evalplot.h' 2>/dev/null | \
       sed '/^[[:space:]]*PARAMETER (MAXLEGE /s/120000/2400/' | \
       cmp -s - "$dir/$path"; then
      return 0
    fi
  fi
  is_generated_binary "$repo" "$path"
}

is_generated_binary() {
  case "$1:$2" in
    autotalys_tools:bin/ZAres|autotalys_tools:bin/driplist|\
    autotalys_tools:bin/extrema|autotalys_tools:bin/globalCE|\
    autotalys_tools:bin/interCE|autotalys_tools:bin/psycheCE|\
    autotalys_tools:bin/naturaltables|autotalys_tools:bin/njoycovx)
      return 0 ;;
  esac
  return 1
}

has_unsafe_local_changes() {
  local repo="$1" dir="$2" upstream="$3" path="" mode=""
  MATCHING_UPSTREAM_PATHS=()
  if ! git -C "$dir" diff --cached --quiet; then
    warn "$repo: staged changes are present"; return 0
  fi
  while IFS= read -r -d '' path; do
    if is_expected_generated_change "$repo" "$path"; then
      continue
    fi
    # A file copied from a newer checkout looks locally modified against the
    # old HEAD. Accept it only if its bytes and Git mode match the fetched tip.
    mode="$(git -C "$dir" ls-tree "$upstream" -- "$path")"
    if [[ "$mode" == 100644\ * || "$mode" == 100755\ * ]] &&
       [[ -f "$dir/$path" && ! -L "$dir/$path" ]] &&
       git -C "$dir" diff --quiet "$upstream" -- "$path" &&
       git -C "$dir" show "$upstream:$path" | cmp -s - "$dir/$path"; then
      MATCHING_UPSTREAM_PATHS+=("$path")
      continue
    fi
    warn "$repo: locally modified tracked file: $path"
    return 0
  done < <(git -C "$dir" diff --name-only -z)
  return 1
}

clone_missing() {
  local repo="$1" url=""
  url="$(repo_url "$repo")"
  say "  Cloning missing package from $url"
  if [[ "$repo" == exfortables ]]; then
    git clone --depth=1 --filter=blob:none --no-checkout "$url" "$ROOT/$repo" || return 1
    git -C "$ROOT/$repo" sparse-checkout set --no-cone \
      '/n/' '/p/' '/g/' '/d/' '/a/' '/t/' '/h/' '/FY/' || return 1
    git -C "$ROOT/$repo" checkout main || return 1
  else
    git clone "$url" "$ROOT/$repo" || return 1
  fi
}

say "AUTOTALYS installation: $ROOT"
if (( DRY_RUN )); then say "DRY RUN: no checked-out files will be changed"; fi
say ""

updated=0
cloned=0
unchanged=0
skipped=0
failed=0

for repo in "${PACKAGES[@]}"; do
  if [[ -n "$ONLY" && "$repo" != "$ONLY" ]]; then continue; fi
  dir="$ROOT/$repo"
  say "***** $repo"
  old="" new=""

  if [[ ! -e "$dir" ]]; then
    if (( DRY_RUN )); then
      say "  Would clone missing repository"
      (( cloned+=1 ))
      continue
    fi
    if ! clone_missing "$repo"; then
      fail "$repo: clone failed"; (( failed+=1 )); continue
    fi
    (( cloned+=1 ))
    say "  Cloned successfully"
  elif [[ ! -d "$dir/.git" && ! -f "$dir/.git" ]]; then
    fail "$repo: no Git metadata (archive-based installation or unrelated directory); skipping"
    (( skipped+=1 ))
    continue
  else
    if ! old="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"; then
      fail "$repo: cannot determine HEAD"; (( failed+=1 )); continue
    fi
    if ! git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
      warn "$repo: no tracking branch; skipping"
      (( skipped+=1 )); continue
    fi
    if ! git -C "$dir" fetch --quiet --no-tags; then
      fail "$repo: fetch failed"; (( failed+=1 )); continue
    fi
    if ! new="$(git -C "$dir" rev-parse '@{upstream}' 2>/dev/null)"; then
      fail "$repo: cannot determine upstream commit"; (( failed+=1 )); continue
    fi
    if has_unsafe_local_changes "$repo" "$dir" "$new"; then
      warn "$repo: preserving local modifications; skipping update"
      (( skipped+=1 )); continue
    fi
    if [[ "$old" == "$new" ]]; then
      say "  Up to date ($(printf '%.12s' "$old"))"
      (( unchanged+=1 )); continue
    fi
    if ! git -C "$dir" merge-base --is-ancestor "$old" "$new"; then
      warn "$repo: local branch has diverged or is ahead; not resetting or merging"
      (( skipped+=1 )); continue
    fi
    say "  New commits: ${old:0:12} -> ${new:0:12}"
    if (( ${#MATCHING_UPSTREAM_PATHS[@]} )); then
      say "  ${#MATCHING_UPSTREAM_PATHS[@]} locally modified file(s) already match the new commit"
    fi
    if (( DRY_RUN )); then
      say "  Would fast-forward repository"
      (( updated+=1 )); continue
    fi
    stash_after=""
    if (( ${#MATCHING_UPSTREAM_PATHS[@]} )); then
      stash_before="$(git -C "$dir" rev-parse -q --verify refs/stash 2>/dev/null || true)"
      if ! git -C "$dir" stash push --quiet -m "AUTOTALYS update: files matching upstream" -- "${MATCHING_UPSTREAM_PATHS[@]}"; then
        fail "$repo: could not temporarily save matching files"
        (( failed+=1 )); continue
      fi
      stash_after="$(git -C "$dir" rev-parse -q --verify refs/stash 2>/dev/null || true)"
      if [[ -z "$stash_after" || "$stash_after" == "$stash_before" ]]; then
        fail "$repo: could not verify temporary save of matching files"
        (( failed+=1 )); continue
      fi
    fi
    if ! git -C "$dir" merge --ff-only --quiet "$new"; then
      if [[ -n "$stash_after" ]]; then
        if [[ "$(git -C "$dir" rev-parse -q --verify refs/stash 2>/dev/null || true)" == "$stash_after" ]]; then
          if ! git -C "$dir" stash pop --quiet 'stash@{0}'; then
            warn "$repo: matching files remain in Git stash $stash_after; restore them with git stash pop"
          fi
        else
          warn "$repo: matching files remain in Git stash $stash_after"
        fi
      fi
      fail "$repo: cannot fast-forward without overwriting local files"
      (( failed+=1 )); continue
    fi
    if [[ -n "$stash_after" ]]; then
      if [[ "$(git -C "$dir" rev-parse -q --verify refs/stash 2>/dev/null || true)" == "$stash_after" ]]; then
        if ! git -C "$dir" stash drop --quiet 'stash@{0}'; then
          warn "$repo: update succeeded, but the temporary save remains in Git stash $stash_after"
        fi
      else
        warn "$repo: update succeeded, but the temporary save remains in Git stash $stash_after"
      fi
    fi
    (( updated+=1 ))
  fi
  say ""
done

say "------------------------------------------------------------"
say "Updated: $updated; cloned: $cloned; unchanged: $unchanged"
say "Skipped: $skipped; failed: $failed"
if (( failed || skipped )); then
  warn "Some packages need attention. No local source changes were discarded."
  exit 1
fi
say "AUTOTALYS source update complete. Run install_autotalys.bash when ready to install."
