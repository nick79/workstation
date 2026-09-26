# ws — workstation maintenance. See docs/tools/ws.md.
# Packaged with writeShellApplication, which adds the shebang and
# `set -euo pipefail` and runs shellcheck at build time.

dir="${WORKSTATION_DIR:-$HOME/github/workstation}"
# The hosts/<name> configuration: WORKSTATION_HOST if set (to switch this Mac
# to another configuration name), else the one it was activated from
# (flake.nix writes it), else, before a first activation, its host name.
host="${WORKSTATION_HOST:-$(cat /etc/workstation-host 2>/dev/null || scutil --get LocalHostName)}"

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf 'ws: %s\n' "$*" >&2; exit 1; }

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

need_repo() {
  [[ -f "$dir/flake.nix" ]] || die "no flake at $dir (set WORKSTATION_DIR)"
}

rebuild() {
  nix run "$dir#darwin-rebuild" -- "$@" --flake "$dir#$host"
}

cmd_help() {
  cat <<EOF
ws — workstation maintenance ($dir, host $host)

Read-only:
  ws status          active generation, repo changes, input ages, outdated brew
  ws list            everything installed: Nix, Homebrew, uv tools
  ws check           nix flake check
  ws build           build and show package changes against the running system

Changes the system:
  ws switch          build, show changes, ask, then activate (sudo)
  ws update [input]  update flake.lock (all inputs or the named ones), build, show changes
  ws rollback        activate the previous generation (sudo)
  ws brew            brew update, upgrade and cleanup
  ws tools           upgrade uv-installed tools
  ws remove <name>…  uninstall a Homebrew cask (with its app data) or formula,
                     or a uv tool; asks first. Explains what to edit instead
                     when the name is declared in this repository
  ws upgrade         update + switch, then brew and tools; lists macOS updates
  ws gc [days]       delete generations older than [days] (default 30) and unused store paths (sudo)
EOF
}

cmd_status() {
  need_repo
  say "Active system"
  readlink /run/current-system
  say "Repository ($dir)"
  git -C "$dir" status --short --branch
  say "Pinned inputs (last updated)"
  nix flake metadata "$dir" --json \
    | jq -r '.locks.nodes | to_entries[] | select(.value.locked.lastModified != null)
             | "\(.key)\t\(.value.locked.lastModified | todate | .[0:10])"' \
    | column -t
  if command -v brew >/dev/null; then
    say "Homebrew"
    local outdated
    outdated="$(brew outdated --quiet | wc -l | tr -d ' ')"
    echo "$outdated outdated package(s)"
  fi
}

# Package names referenced by a Nix profile environment.
env_packages() {
  nix-store --query --references "$1" | sed -E 's|^/nix/store/[a-z0-9]+-||' | sort
}

cmd_list() {
  local home_env
  home_env="$(nix-store --query --references "/etc/profiles/per-user/$USER" \
    | grep -- '-home-manager-path$' || true)"
  say "Nix: home packages (Home Manager)"
  env_packages "${home_env:-/etc/profiles/per-user/$USER}"
  say "Nix: system packages (nix-darwin)"
  env_packages "$(readlink -f /run/current-system/sw)"
  if command -v brew >/dev/null; then
    say "Homebrew: formulae installed on request"
    brew list --formula --installed-on-request
    say "Homebrew: casks"
    brew list --cask
  fi
  if command -v uv >/dev/null; then
    say "uv tools"
    uv tool list
  fi
}

cmd_check() {
  need_repo
  nix flake check "$dir"
}

# The Brewfile a system generation's activation runs; empty if it has none.
brewfile_of() {
  grep -o '/nix/store/[a-z0-9]*-Brewfile' "$1/activate" 2>/dev/null | head -1 || true
}

# Homebrew entries of a Brewfile as "cask name", "brew name", ... lines.
brew_entries() {
  sed -En 's/^(tap|brew|cask|mas) "([^"]*)".*/\1 \2/p' "$1" | sort
}

# Print each line of $2, indented and prefixed with $1.
prefix_lines() {
  local line
  while IFS= read -r line; do printf '  %s %s\n' "$1" "$line"; done <<<"$2"
}

# nvd sees only Nix packages; the declared Homebrew apps are one file to it.
# List what activation would add to or drop from the Homebrew declaration.
brew_diff() {
  local old new added removed
  old="$(brewfile_of "$1")"
  new="$(brewfile_of "$2")"
  say "Homebrew declaration"
  if [[ -z "$old" || -z "$new" ]]; then
    echo "Not comparable (a generation without a Brewfile)."
    return 0
  fi
  added="$(comm -13 <(brew_entries "$old") <(brew_entries "$new"))"
  removed="$(comm -23 <(brew_entries "$old") <(brew_entries "$new"))"
  if [[ -z "$added$removed" ]]; then
    echo "No changes."
    return 0
  fi
  [[ -z "$added" ]] || prefix_lines + "$added"
  if [[ -n "$removed" ]]; then
    prefix_lines - "$removed"
    echo "Removed entries stay installed (cleanup = \"none\"); follow with 'ws remove <name>'."
  fi
}

cmd_build() {
  need_repo
  say "Building $host"
  (cd "$dir" && rebuild build)
  say "Changes against the running system"
  nvd diff /run/current-system "$dir/result"
  brew_diff /run/current-system "$dir/result"
}

cmd_switch() {
  cmd_build
  confirm "Activate this generation?" || { echo "Not activated."; return 0; }
  (cd "$dir" && sudo nix run "$dir#darwin-rebuild" -- switch --flake "$dir#$host")
  echo "Activated. Open a new terminal tab to pick up shell changes."
}

cmd_update() {
  need_repo
  say "Updating flake inputs${1:+: $*}"
  nix flake update --flake "$dir" "$@"
  git -C "$dir" --no-pager diff --stat -- flake.lock
  cmd_build
  echo
  echo "Not activated. Review, then 'ws switch'; commit flake.lock once verified."
}

cmd_rollback() {
  local rebuild_bin
  rebuild_bin="$(readlink -f /run/current-system/sw/bin/darwin-rebuild)"
  sudo "$rebuild_bin" --list-generations
  confirm "Roll back to the previous generation?" || { echo "Nothing changed."; return 0; }
  sudo "$rebuild_bin" --rollback
}

cmd_brew() {
  command -v brew >/dev/null || die "Homebrew is not installed"
  brew update && brew upgrade && brew cleanup
}

cmd_tools() {
  command -v uv >/dev/null || die "uv is not installed"
  uv tool upgrade --all
}

# Casks the active generation declares, from the Brewfile its activation runs.
declared_casks() {
  local brewfile
  brewfile="$(brewfile_of /run/current-system)"
  [[ -n "$brewfile" && -f "$brewfile" ]] || return 0
  sed -n 's/^cask "\([^"]*\)".*/\1/p' "$brewfile"
}

remove_one() {
  local name="$1" nix_bin="/etc/profiles/per-user/$USER/bin/$1"

  if command -v brew >/dev/null && brew list --cask "$name" >/dev/null 2>&1; then
    if declared_casks | grep -qxF "$name"; then
      local where="hosts/$host/default.nix (this Mac only)"
      grep -qF "\"$name\"" "$dir/modules/darwin/homebrew.nix" 2>/dev/null &&
        where="modules/darwin/homebrew.nix (every Mac)"
      echo "$name is declared in this repository; activation would reinstall it."
      echo "Remove it from homebrew.casks in $where, run 'ws switch', then 'ws remove $name'."
      return 1
    fi
    say "Homebrew cask: $name"
    echo "Uninstalls the app and removes its support files (the cask's zap list; most go to the Trash)."
    confirm "Remove $name?" || { echo "Kept."; return 0; }
    brew uninstall --cask --zap "$name"
    return 0
  fi

  if command -v brew >/dev/null && brew list --formula "$name" >/dev/null 2>&1; then
    say "Homebrew formula: $name"
    [[ -x "$nix_bin" ]] && echo "The Nix copy ($nix_bin) stays."
    confirm "Remove $name?" || { echo "Kept."; return 0; }
    brew uninstall "$name"
    local orphans
    orphans="$(brew autoremove --dry-run 2>/dev/null | grep -v '^==>' || true)"
    if [[ -n "$orphans" ]]; then
      echo "Dependencies nothing else needs any more:"
      printf '  %s\n' "$orphans"
      confirm "Remove them too?" && brew autoremove
    fi
    return 0
  fi

  if command -v uv >/dev/null && uv tool list 2>/dev/null | awk '/^[^ -]/ {print $1}' | grep -qxF "$name"; then
    say "uv tool: $name"
    confirm "Remove $name?" || { echo "Kept."; return 0; }
    uv tool uninstall "$name"
    return 0
  fi

  if [[ -x "$nix_bin" ]]; then
    echo "$name comes from Nix ($(readlink -f "$nix_bin" | cut -d/ -f1-4))."
    echo "Remove it from the modules in $dir (grep -rn '$name' $dir/modules $dir/hosts), then 'ws switch'."
    return 1
  fi

  echo "$name: not an installed cask, formula, uv tool or Nix command."
  command -v brew >/dev/null && echo "Look it up with: brew search $name"
  return 1
}

cmd_remove() {
  [[ $# -gt 0 ]] || die "usage: ws remove <name>..."
  local name failed=0
  for name in "$@"; do
    remove_one "$name" || failed=1
  done
  return "$failed"
}

cmd_upgrade() {
  cmd_update
  confirm "Activate this generation?" \
    && (cd "$dir" && sudo nix run "$dir#darwin-rebuild" -- switch --flake "$dir#$host")
  if command -v brew >/dev/null; then say "Homebrew"; cmd_brew; fi
  if command -v uv >/dev/null; then say "uv tools"; cmd_tools; fi
  say "macOS updates (listed only; install them from System Settings)"
  softwareupdate --list 2>&1 || true
}

cmd_gc() {
  local days="${1:-30}"
  [[ "$days" =~ ^[0-9]+$ ]] || die "days must be a number"
  confirm "Delete generations older than $days days and unused store paths?" \
    || { echo "Nothing deleted."; return 0; }
  sudo nix-collect-garbage --delete-older-than "${days}d"
}

sub="${1:-help}"
shift || true
case "$sub" in
  help | -h | --help) cmd_help ;;
  status) cmd_status ;;
  list) cmd_list ;;
  check) cmd_check ;;
  build) cmd_build ;;
  switch) cmd_switch ;;
  update) cmd_update "$@" ;;
  rollback) cmd_rollback ;;
  brew) cmd_brew ;;
  tools) cmd_tools ;;
  remove) cmd_remove "$@" ;;
  upgrade) cmd_upgrade ;;
  gc) cmd_gc "$@" ;;
  *) cmd_help >&2; exit 2 ;;
esac
