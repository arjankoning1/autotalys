#!/usr/bin/env bash
# Incrementally update a Git-based AUTOTALYS installation.
# Arjan Koning / AUTOTALYS
#
# Usage: update_autotalys.bash [INSTALL_DIR] [--dry-run] [--only NAME]
#                             [--no-build] [--rebuild]
#
# --dry-run fetches Git metadata but changes no checked-out files or binaries.
# A missing package is cloned; existing packages are fast-forwarded only.
# Local source modifications and diverged branches are never discarded.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: update_autotalys.bash [INSTALL_DIR] [options]

INSTALL_DIR defaults to $HOME/autotalys.

Options:
  --dry-run        Fetch remote references and show planned actions only
  --only NAME      Update only the named package (e.g. talys, autoendf)
  --no-build       Update source and links but do not compile/install packages
  --rebuild        Build every changed compiled package, even for data/docs changes
  -h, --help       Show this help

A Git installation (from clone_autotalys.bash) is required. Archive-based
installations are not updated in place. The optional libraries/ collection and
OpenMC Conda environment are deliberately excluded.
USAGE
}

say() { printf '%s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; }

ROOT="${HOME}/autotalys"
DRY_RUN=0
NO_BUILD=0
REBUILD=0
ONLY=""
ROOT_SET=0

while (( $# > 0 )); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-build) NO_BUILD=1 ;;
    --rebuild) REBUILD=1 ;;
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
  local repo="$1" dir="$2" path=""
  if ! git -C "$dir" diff --cached --quiet; then
    warn "$repo: staged changes are present"; return 0
  fi
  while IFS= read -r -d '' path; do
    if ! is_expected_generated_change "$repo" "$path"; then
      warn "$repo: locally modified tracked file: $path"
      return 0
    fi
  done < <(git -C "$dir" diff --name-only -z)
  return 1
}

# Whether a change needs a compiled-package build rather than just refreshed
# scripts/data/symlinks. Conservative for source and build configuration files.
is_build_change() {
  local repo="$1" path="$2"
  case "$repo" in
    talys|tefal|tasman|endftables|autonorm|autotalys_tools)
      case "$path" in
        source/*|install_*.bash|Makefile|*/Makefile|CMakeLists.txt|*/CMakeLists.txt)
          return 0 ;;
      esac ;;
    NJOY2016)
      case "$path" in
        src/*|metaconfigure/*|CMakeLists.txt|*/CMakeLists.txt|*.cmake|*/*.cmake)
          return 0 ;;
      esac ;;
    PREPRO)
      case "$path" in source/*|*/Makefile|Makefile) return 0 ;; esac ;;
    ENDF-utility-codes)
      case "$path" in checkr/*|fizcon/*|psyche/*|inter/*) return 0 ;; esac ;;
    fudge)
      case "$path" in
        *.py|*/*.py|*/*/*.py|*.c|*/*.c|*.h|*/*.h|*.cpp|*/*.cpp|\
        pyproject.toml|setup.cfg|setup.py|Makefile|*/Makefile)
          return 0 ;;
      esac ;;
  esac
  return 1
}

is_compiled_package() {
  case "$1" in
    talys|tefal|tasman|endftables|autonorm|autotalys_tools|\
    NJOY2016|PREPRO|ENDF-utility-codes|fudge) return 0 ;;
  esac
  return 1
}

# Add/update only links that already belong to this package (or are absent).
# Never replace a normal file or another package's symlink.
link_one() {
  local dest="$1" target="$2" owner_prefix="$3" existing=""
  if [[ -L "$dest" ]]; then
    existing="$(readlink "$dest")"
    if [[ "$existing" == "$target" ]]; then return 0; fi
    case "$existing" in
      "$owner_prefix"*) ;;
      *) warn "preserving foreign symlink: $dest -> $existing"; return 0 ;;
    esac
  elif [[ -e "$dest" ]]; then
    warn "preserving local file: $dest"; return 0
  fi
  ln -sfn "$target" "$dest"
}

refresh_links() {
  local repo="$1" dir="$ROOT/$1" source="" name="" dest="" target=""
  [[ -d "$dir/bin" ]] || return 0
  mkdir -p "$ROOT/bin"
  for source in "$dir/bin/"*; do
    [[ -f "$source" && ! -d "$source" ]] || continue
    name="${source##*/}"
    # Relative to AUTOTALYS/bin, as in the existing installation script.
    target="../$repo/bin/$name"
    link_one "$ROOT/bin/$name" "$target" "../$repo/bin/"
  done
  # Remove only stale links belonging to this package.
  for dest in "$ROOT/bin/"*; do
    [[ -L "$dest" ]] || continue
    target="$(readlink "$dest")"
    case "$target" in
      "../$repo/bin/"*)
        [[ -e "$dest" ]] || { say "  Removing obsolete link ${dest##*/}"; rm -- "$dest"; }
        ;;
    esac
  done
}

build_package() {
  local repo="$1" dir="$ROOT/$1" program="" part=""
  say "  Building $repo"
  case "$repo" in
    talys|tefal|tasman|endftables|autonorm|autotalys_tools)
      program="$dir/install_${repo}.bash"
      if [[ ! -f "$program" ]]; then
        fail "$repo: missing $program"; return 1
      fi
      (cd "$dir" && bash "./install_${repo}.bash") ;;
    NJOY2016)
      command -v cmake >/dev/null 2>&1 || { fail "NJOY2016: cmake is not installed"; return 1; }
      mkdir -p "$dir/build"
      (cd "$dir/build" && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --parallel 8) || return 1
      if [[ ! -x "$dir/build/njoy" ]]; then
        fail "NJOY2016: build/njoy not found"; return 1
      fi
      mkdir -p "$ROOT/bin"
      link_one "$ROOT/bin/njoy" "../NJOY2016/build/njoy" "../NJOY2016/build/" ;;
    PREPRO)
      if [[ ! -f "$dir/install_PREPRO.bash" ]]; then
        fail "PREPRO: install_PREPRO.bash is missing; run the full installer once"
        return 1
      fi
      (cd "$dir" && bash ./install_PREPRO.bash) ;;
    ENDF-utility-codes)
      mkdir -p "$dir/bin"
      for part in checkr fizcon psyche inter; do
        (cd "$dir/$part" && make clean && make) || return 1
        if [[ ! -f "$dir/$part/$part" ]]; then
          fail "ENDF-utility-codes: missing built $part"; return 1
        fi
        mv "$dir/$part/$part" "$dir/bin/$part" || return 1
      done ;;
    fudge)
      if [[ ! -x "$dir/.venv/bin/python" ]]; then
        fail "FUDGE: existing .venv not found; run the full installer once"
        return 1
      fi
      (cd "$dir" && .venv/bin/python -m pip install --no-deps .) ;;
    *) return 0 ;;
  esac
}

# The assembled root's installer is a copy, not a symlink. Refresh it only
# when it still matches the old Git version, to protect user modifications.
refresh_main_installer() {
  local old="$1" new="$2" src="$ROOT/autotalys_tools/bin/install_autotalys.bash"
  local dest="$ROOT/install_autotalys.bash" before=""
  if [[ ! -f "$src" ]]; then return 0; fi
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then return 0; fi
  if [[ -f "$dest" && -n "$old" ]]; then
    if ! git -C "$ROOT/autotalys_tools" show "$old:bin/install_autotalys.bash" 2>/dev/null | cmp -s - "$dest"; then
      warn "top-level install_autotalys.bash differs from previous version; preserving it"
      return 0
    fi
  elif [[ -f "$dest" ]]; then
    warn "top-level install_autotalys.bash exists and has unknown origin; preserving it"
    return 0
  fi
  if (( DRY_RUN )); then
    say "  Would refresh install_autotalys.bash"
  else
    cp "$src" "$dest"
    chmod +x "$dest"
    say "  Refreshed install_autotalys.bash"
  fi
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
if (( DRY_RUN )); then say "DRY RUN: no checked-out files or binaries will be changed"; fi
if (( NO_BUILD )); then say "Builds disabled (--no-build)"; fi
say ""

updated=0
cloned=0
built=0
unchanged=0
skipped=0
failed=0

for repo in "${PACKAGES[@]}"; do
  if [[ -n "$ONLY" && "$repo" != "$ONLY" ]]; then continue; fi
  dir="$ROOT/$repo"
  say "***** $repo"
  old="" new="" changed=0 build_needed=0 did_clone=0

  if [[ ! -e "$dir" ]]; then
    if (( DRY_RUN )); then
      say "  Would clone missing repository"
      (( cloned+=1 ))
      if (( ! NO_BUILD )) && is_compiled_package "$repo"; then
        say "  Would build newly cloned package"
      fi
      continue
    fi
    if ! clone_missing "$repo"; then
      fail "$repo: clone failed"; (( failed+=1 )); continue
    fi
    did_clone=1
    changed=1
    build_needed=1
    (( cloned+=1 ))
  elif [[ ! -d "$dir/.git" && ! -f "$dir/.git" ]]; then
    fail "$repo: no Git metadata (archive-based installation or unrelated directory); skipping"
    (( skipped+=1 ))
    continue
  else
    if has_unsafe_local_changes "$repo" "$dir"; then
      warn "$repo: preserving local modifications; skipping update"
      (( skipped+=1 )); continue
    fi
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
    if [[ "$old" == "$new" ]]; then
      say "  Up to date ($(printf '%.12s' "$old"))"
      (( unchanged+=1 )); continue
    fi
    if ! git -C "$dir" merge-base --is-ancestor "$old" "$new"; then
      warn "$repo: local branch has diverged or is ahead; not resetting or merging"
      (( skipped+=1 )); continue
    fi
    changed=1
    while IFS= read -r -d '' path; do
      if is_build_change "$repo" "$path"; then build_needed=1; fi
    done < <(git -C "$dir" diff --name-only -z "$old" "$new")
    if (( REBUILD )) && is_compiled_package "$repo"; then build_needed=1; fi
    say "  New commits: ${old:0:12} -> ${new:0:12}"
    if (( DRY_RUN )); then
      say "  Would fast-forward repository"
      if (( build_needed && ! NO_BUILD )); then say "  Would rebuild $repo"; fi
      if [[ "$repo" == autotalys_tools ]]; then
        if ! git -C "$dir" diff --quiet "$old" "$new" -- bin/install_autotalys.bash; then
          say "  Top-level installer may need refreshing (subject to local-change check)"
        fi
      fi
      (( updated+=1 )); continue
    fi
    if ! git -C "$dir" merge --ff-only --quiet "$new"; then
      fail "$repo: cannot fast-forward without overwriting local files"
      (( failed+=1 )); continue
    fi
    (( updated+=1 ))
  fi

  if (( ! NO_BUILD && build_needed )) && is_compiled_package "$repo"; then
    if build_package "$repo"; then
      (( built+=1 ))
    else
      fail "$repo: build failed; source update retained, other packages continue"
      (( failed+=1 ))
    fi
  fi
  # Re-scan scripts and executables; do this even when the build failed, since
  # scripts may have been safely updated by Git.
  case "$repo" in
    talys|tefal|tasman|endftables|autonorm|autoendf|autotalys_tools|\
    PREPRO|ENDF-utility-codes) refresh_links "$repo" ;;
  esac
  if [[ "$repo" == autotalys_tools ]]; then
    refresh_main_installer "$old" "$new"
  fi
  if (( did_clone )); then say "  Cloned successfully"; fi
  say ""
done

say "------------------------------------------------------------"
say "Updated: $updated; cloned: $cloned; built: $built; unchanged: $unchanged"
say "Skipped: $skipped; failed: $failed"
if (( failed || skipped )); then
  warn "Some packages need attention. No local source changes were discarded."
  exit 1
fi
say "AUTOTALYS update complete."