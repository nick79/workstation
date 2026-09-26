#!/usr/bin/env bash
#
# Provision this Mac from a clean macOS install.
#
#   ./scripts/bootstrap.sh --check     inspect and report, change nothing
#   ./scripts/bootstrap.sh             provision, prompting before each change
#   ./scripts/bootstrap.sh --yes       provision without prompting
#   ./scripts/bootstrap.sh --installer-only
#                                      install Nix and Homebrew only, and stop
#   --host <name>                      the hosts/<name> configuration to use;
#                                      needed on a new Mac's first run
#
# Prerequisites, which this script deliberately does NOT perform: macOS itself,
# the Xcode Command Line Tools, and cloning this repository (public, so over
# HTTPS without credentials). Git comes from the CLT and git clones the
# repository, so both necessarily precede the script.
#
# Safe to run repeatedly. Every step checks whether its work is already done.
#
# This script is the executable form of docs/BOOTSTRAP.md. If the two disagree,
# the script is wrong: the document explains why the order is what it is.
#
# What it does NOT do, by design:
#   - install macOS, or the Xcode Command Line Tools (checked, never installed)
#   - create or restore SSH keys, or any other credential
#   - start Colima or create a container VM, install Python interpreters,
#     or sign in to applications
# Those are listed in docs/BOOTSTRAP.md step 9 and stay manual on purpose.

set -euo pipefail

# Assigned separately so a failing cd stops the script under set -e (SC2155).
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly NIX_INSTALLER_URL="https://artifacts.nixos.org/nix-installer"
readonly BREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly BREW_PREFIX="/opt/homebrew"

MODE="prompt"   # prompt | yes | check
HOST=""
INSTALLER_ONLY=0

# ---------------------------------------------------------------- output ----

if [ -t 1 ]; then
    C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'
    C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
else
    C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_BOLD=""; C_OFF=""
fi

step()  { printf '\n%s==>%s %s%s%s\n' "$C_BOLD" "$C_OFF" "$C_BOLD" "$1" "$C_OFF"; }
ok()    { printf '  %s✓%s %s\n' "$C_OK" "$C_OFF" "$1"; }
skip()  { printf '  %s·%s %s %s(already done)%s\n' "$C_DIM" "$C_OFF" "$1" "$C_DIM" "$C_OFF"; }
warn()  { printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$1"; }
die()   { printf '\n%serror:%s %s\n' "$C_ERR" "$C_OFF" "$1" >&2; exit 1; }
todo()  { printf '  %s?%s %s\n' "$C_WARN" "$C_OFF" "$1"; }

# Ask before changing anything. Returns 1 in check mode and 2 when the user
# declines a required step.
confirm() {
    case "$MODE" in
        check) printf '  %s·%s would: %s\n' "$C_DIM" "$C_OFF" "$1"; return 1 ;;
        yes)   return 0 ;;
    esac
    printf '  %s?%s %s [y/N] ' "$C_WARN" "$C_OFF" "$1"
    read -r reply </dev/tty
    case "$reply" in [yY]*) return 0 ;; *) warn "declined"; return 2 ;; esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------- arguments ----

while [ $# -gt 0 ]; do
    case "$1" in
        --check|-n) MODE="check" ;;
        --yes|-y)   MODE="yes" ;;
        --host)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ] || [[ "${2:-}" == -* ]]; then
                die "--host requires a non-empty host name"
            fi
            shift
            HOST="$1"
            ;;
        --installer-only) INSTALLER_ONLY=1 ;;
        -h|--help)  sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          die "unknown argument: $1" ;;
    esac
    shift
done

# ------------------------------------------------------------- preflight ----

preflight() {
    step "Preflight"

    [ "$(uname -s)" = "Darwin" ] || die "this script is macOS only"
    ok "macOS $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"

    [ "$(uname -m)" = "arm64" ] || die "this configuration targets Apple Silicon only"
    ok "Apple Silicon"

    [ "$(id -u)" -ne 0 ] || die "do not run this as root; it will ask for sudo when needed"

    if [ ! -f "$REPO_ROOT/flake.nix" ]; then
        # Installing Nix and Homebrew and then stopping leaves a half-built
        # machine and reports success. Refuse, unless asked for explicitly.
        if [ "$MODE" = "check" ] || [ "$INSTALLER_ONLY" -eq 1 ]; then
            warn "no flake.nix in $REPO_ROOT — nothing can be activated"
        else
            die "no flake.nix in $REPO_ROOT.

  Provisioning cannot complete: there is no system configuration to activate.
  Run the script from a complete clone of this repository.

  To see what would happen, changing nothing:
      ./scripts/bootstrap.sh --check
  To install only the prerequisites (Nix, Homebrew) and stop, deliberately:
      ./scripts/bootstrap.sh --installer-only"
        fi
    fi

    # Which hosts/<name> configuration to activate. --host wins; after
    # the first activation the configuration records its own name in
    # /etc/workstation-host; before that, fall back to the Mac's host name,
    # which on a new Mac usually matches nothing, hence --host.
    if [ -z "$HOST" ]; then
        if [ -r /etc/workstation-host ]; then
            HOST="$(cat /etc/workstation-host)"
        else
            HOST="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
            todo "host taken from the Mac's host name; on a new Mac pass --host <name> (docs/BOOTSTRAP.md step 6)"
        fi
    fi
    if [ -f "$REPO_ROOT/flake.nix" ] && [ ! -f "$REPO_ROOT/hosts/$HOST/default.nix" ]; then
        local known=() d
        for d in "$REPO_ROOT"/hosts/*/default.nix; do
            [ -f "$d" ] && known+=("$(basename "$(dirname "$d")")")
        done
        if [ "$MODE" = "check" ] || [ "$INSTALLER_ONLY" -eq 1 ]; then
            warn "no configuration hosts/$HOST — pass --host <name>, one of: ${known[*]}"
        else
            die "no configuration hosts/$HOST in this repository.
  Pass the one for this Mac with --host <name>, one of: ${known[*]}"
        fi
    fi
    ok "host: $HOST"
}

# Ask for sudo once, up front, and keep it alive. Scattering sudo prompts
# through a long run is how people walk away and come back to a stalled script.
sudo_keepalive() {
    [ "$MODE" = "check" ] && return 0
    step "Administrator access"
    sudo -v || die "sudo is required"
    while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
    ok "granted"
}

# ----------------------------------------------- prerequisite: Xcode CLT ----

# NOT a step this script performs. Git comes from the Command Line Tools, and
# git is what clones the repository this script lives in -- so by the time the
# script can run, the CLT must already be present. Installing them also opens a
# GUI installer, which would make --yes a lie. Checked, never installed.
check_xcode_clt() {
    step "Xcode Command Line Tools (prerequisite)"

    if xcode-select -p >/dev/null 2>&1; then
        ok "present at $(xcode-select -p)"
        return 0
    fi

    warn "not installed, yet this repository was cloned — unusual"
    warn "install them, then re-run:  xcode-select --install"
    [ "$MODE" = "check" ] || die "Xcode Command Line Tools are required"
}

# -------------------------------------------------- step 0: macOS updates ----

# A fresh machine takes every pending macOS update before anything else is
# installed. Optional: declining continues. An update
# that needs a restart ends the run here; restart, then run the script again.
install_macos_updates() {
    step "macOS updates"

    local available labels
    available="$(softwareupdate --list 2>&1)" || true
    labels="$(grep '^\* Label:' <<<"$available" | sed 's/^\* Label: /    /')" || true
    if [ -z "$labels" ]; then
        if grep -q "No new software available" <<<"$available"; then
            skip "no updates available"
        else
            warn "could not list updates; continuing without them"
            warn "$(tail -1 <<<"$available")"
        fi
        return 0
    fi
    printf '%s\n' "$labels"
    todo "the install and restart paths below are untested (docs/BOOTSTRAP.md step 0)"

    if ! confirm "install all available macOS updates"; then
        [ "$MODE" = "check" ] || warn "continuing without them"
        return 0
    fi
    sudo softwareupdate --install --all
    ok "installed"

    if grep -q "Action: restart" <<<"$available"; then
        warn "an installed update needs a restart to finish"
        printf '\n  Restart the Mac, then run this script again to continue.\n'
        exit 0
    fi
}

# ----------------------------------------------------------- step 3: Nix ----

install_nix() {
    step "Nix"

    if have nix || [ -e /nix/receipt.json ]; then
        skip "$(nix --version 2>/dev/null || echo 'installed, not on PATH in this shell')"
    else
        if ! confirm "install upstream Nix (NixOS Foundation installer)"; then
            [ "$MODE" = "check" ] && return 0
            die "Nix installation was declined; stopping without continuing to dependent steps"
        fi
        # --enable-flakes is REQUIRED. This installer defaults it to false, and
        # everything downstream -- `nix run`, darwin-rebuild, the whole flake --
        # needs it. Without it the run fails later, confusingly.
        local -a nix_install_args=(install --enable-flakes)
        [ "$MODE" = "yes" ] && nix_install_args+=(--no-confirm)
        curl -sSfL "$NIX_INSTALLER_URL" | sh -s -- "${nix_install_args[@]}"
        # This shell was started before Nix existed.
        # shellcheck disable=SC1091
        [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] &&
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        ok "installed"
    fi

    # Verify the Nix uninstaller exists now, while there is still almost
    # nothing to roll back. After nix-darwin activation, remove nix-darwin
    # first with its upstream uninstaller.
    if [ -x /nix/nix-installer ]; then
        ok "Nix uninstaller present: /nix/nix-installer uninstall"
    else
        warn "/nix/nix-installer is missing — rollback would be manual. Investigate before continuing."
    fi

    # Fatal, not a warning. Continuing without flakes guarantees a failure
    # further along, at a point where the cause is much less obvious.
    if have nix; then
        if nix flake --help >/dev/null 2>&1; then
            ok "flakes enabled"
        else
            die "flakes are not enabled.
  Add to /etc/nix/nix.conf:
      experimental-features = nix-command flakes
  then restart the daemon:
      sudo launchctl kickstart -k system/org.nixos.nix-daemon
  Nothing further can work without this."
        fi
    elif [ "$MODE" != "check" ]; then
        die "Nix was installed but is not on PATH in this shell. Open a new terminal and re-run."
    fi
}

# ------------------------------------------------------ step 4: Homebrew ----

# brew shellenv is still needed for Homebrew commands and metadata, but it
# prepends Homebrew to PATH, ahead of Nix. Keep its other environment changes
# and rebuild PATH with the existing Nix profile bins first, in NIX_PROFILES
# order, so a Nix tool always wins over a Homebrew one of the same name.
reassert_nix_path() {
    local profile entry candidate duplicate index
    local -a ordered_path inherited_path
    ordered_path=()

    for profile in ${NIX_PROFILES:-}; do
        [ -d "$profile/bin" ] || continue
        ordered_path[${#ordered_path[@]}]="$profile/bin"
    done
    [ "${#ordered_path[@]}" -gt 0 ] || return 0

    IFS=: read -r -a inherited_path <<< "${PATH-}"
    for entry in "${inherited_path[@]}"; do
        duplicate=0
        for candidate in "${ordered_path[@]}"; do
            if [ "$candidate" = "$entry" ]; then
                duplicate=1
                break
            fi
        done
        [ "$duplicate" -eq 1 ] || ordered_path[${#ordered_path[@]}]="$entry"
    done

    PATH="${ordered_path[0]}"
    for ((index = 1; index < ${#ordered_path[@]}; index++)); do
        PATH="$PATH:${ordered_path[$index]}"
    done
    export PATH
}

install_homebrew() {
    step "Homebrew"

    if [ -x "$BREW_PREFIX/bin/brew" ]; then
        skip "$("$BREW_PREFIX/bin/brew" --version | head -1)"
    else
        # nix-darwin's homebrew module manages an existing Homebrew; it does
        # not install one. This must happen before activation.
        if ! confirm "install Homebrew"; then
            [ "$MODE" = "check" ] && return 0
            die "Homebrew installation was declined; stopping without continuing to dependent steps"
        fi
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$BREW_INSTALLER_URL")"
        ok "installed"
    fi

    [ -x "$BREW_PREFIX/bin/brew" ] && eval "$("$BREW_PREFIX/bin/brew" shellenv)"
    reassert_nix_path
}

# ---------------------------------------------------- step 6: activation ----

activate_system() {
    step "nix-darwin activation"

    if [ ! -f "$REPO_ROOT/flake.nix" ]; then
        todo "flake.nix is missing — run the script from a complete clone of this repository"
        return 0
    fi

    if ! have nix; then
        todo "nix-darwin activation pending — install Nix, lock the flake, run nix flake check, then build before switching"
        return 0
    fi

    if [ -f "$REPO_ROOT/flake.lock" ]; then
        skip "flake inputs locked"
    elif confirm "lock flake inputs"; then
        nix flake lock "$REPO_ROOT" || die "failed to lock flake inputs; the system was not changed"
        ok "flake inputs locked"
    elif [ "$MODE" != "check" ]; then
        die "locking flake inputs was declined; stopping before validation and activation"
    fi

    if [ "$MODE" = "check" ]; then
        confirm "validate the flake" || true
    else
        nix flake check "$REPO_ROOT" || die "flake validation failed; the system was not changed"
        ok "flake check succeeded"
    fi

    local rebuild_build rebuild_switch first_run=0
    if have darwin-rebuild; then
        local darwin_rebuild_bin
        darwin_rebuild_bin="$(command -v darwin-rebuild)"
        rebuild_build=("$darwin_rebuild_bin" build --flake "$REPO_ROOT#$HOST")
        rebuild_switch=(sudo "$darwin_rebuild_bin" switch --flake "$REPO_ROOT#$HOST")
    else
        # First activation: darwin-rebuild does not exist yet, so run it from
        # the package exposed by this flake. That package comes from the locked
        # nix-darwin input, so the build and activation use the same revision.
        first_run=1
        rebuild_build=(nix run "$REPO_ROOT#darwin-rebuild" -- build --flake "$REPO_ROOT#$HOST")
        rebuild_switch=(sudo nix run "$REPO_ROOT#darwin-rebuild" -- switch --flake "$REPO_ROOT#$HOST")
    fi

    # Build first, always — including the first time, which is when the flake
    # is least trustworthy. A build changes nothing about the running system.
    if confirm "build the system configuration for '$HOST' (changes nothing)"; then
        "${rebuild_build[@]}" || die "build failed; the system was not changed"
        ok "build succeeded"
    elif [ "$MODE" != "check" ]; then
        die "system build was declined; stopping before activation"
    fi

    if confirm "activate it"; then
        if ! "${rebuild_switch[@]}"; then
            if [ "$first_run" -eq 1 ]; then
                # No previous generation exists and darwin-rebuild is not
                # installed, so generation rollback is not available yet.
                die "first activation failed.
  There is no previous generation to roll back to, and darwin-rebuild is
  not installed, so 'switch --rollback' does not apply here.
  The build succeeded, but switch may have partially activated the system.
  Inspect the machine before retrying. If nix-darwin was installed, remove it
  first with:
      sudo nix run nix-darwin#darwin-uninstaller
  Then, if you want to remove Nix too:
      /nix/nix-installer uninstall"
            fi
            die "activation failed. Roll back with:
      sudo \"\$(command -v darwin-rebuild)\" switch --rollback
  List generations with:
      sudo \"\$(command -v darwin-rebuild)\" --list-generations"
        fi
        ok "activated"
    elif [ "$MODE" != "check" ]; then
        die "activation was declined; stopping without verification or post-steps"
    fi
}

# ------------------------------------------------------- step 8: verify ----

verify() {
    step "Verification"

    if have nix; then ok "nix: $(nix --version)"; else warn "nix not on PATH"; fi
    [ -x /nix/nix-installer ] && ok "Nix uninstaller present: /nix/nix-installer uninstall"
    [ -x "$BREW_PREFIX/bin/brew" ] && ok "homebrew: $("$BREW_PREFIX/bin/brew" --version | head -1)"

    # Nix must come before Homebrew, or a tool installed by both silently runs
    # the Homebrew copy instead of the declared one.
    if have bat; then
        local p; p="$(command -v bat)"
        case "$p" in
            /nix/store/*|*/.nix-profile/*|/run/current-system/*|/etc/profiles/*)
                ok "PATH order: bat resolves to Nix ($p)" ;;
            *) warn "PATH order: bat resolves to $p — Homebrew is ahead of Nix" ;;
        esac
    fi

    # The email is per machine, in an untracked file, so each Mac can use its
    # own address and none is in the public repository.
    if have git; then
        local email; email="$(git config --file "$HOME/.config/git/local" user.email 2>/dev/null || true)"
        if [ -n "$email" ]; then ok "git email set for this machine"
        else todo "git email not set: git config --file ~/.config/git/local user.email <address>"; fi
    fi

    todo "remaining checks are not written yet — see docs/BOOTSTRAP.md step 8"
}

# ------------------------------------------------------------ post-steps ----

manual_steps() {
    step "Deliberately not automated"
    cat <<'EOF'
  These are mutable by design and stay manual (docs/BOOTSTRAP.md step 9):

    colima start           only when you want a runtime; never auto-started,
                           and provisioning creates no VM at all
    uv python install      Python interpreters (uv, not Nix, provides Python)
    git email              git config --file ~/.config/git/local user.email <address>
                           once per machine, never in the repository
    ssh keys               restore from the password manager, or create new ones
    applications           sign in to the applications
    projects               clone your repositories

  A reproducible machine is one where the line between declared and mutable
  is deliberate, not one where everything is declarative.
EOF
}

# ------------------------------------------------------------------ main ----

main() {
    printf '%sWorkstation bootstrap%s  %s(%s)%s\n' \
        "$C_BOLD" "$C_OFF" "$C_DIM" "$([ "$MODE" = check ] && echo 'check only, no changes' || echo "mode: $MODE")" "$C_OFF"

    preflight
    sudo_keepalive
    check_xcode_clt
    install_macos_updates
    install_nix
    install_homebrew
    if [ "$INSTALLER_ONLY" -eq 1 ]; then
        step "Installer-only complete"
        if [ "$MODE" = "check" ]; then
            printf '  %s·%s would stop here; activation and post-steps are not run\n' "$C_DIM" "$C_OFF"
            printf '%sNothing was changed.%s\n' "$C_DIM" "$C_OFF"
        else
            ok "Nix and Homebrew are ready; nix-darwin activation was not attempted"
        fi
        return 0
    fi
    activate_system
    verify
    manual_steps

    printf '\n%sDone.%s\n' "$C_BOLD" "$C_OFF"
    [ "$MODE" = "check" ] && printf '%sNothing was changed.%s\n' "$C_DIM" "$C_OFF"
    return 0
}

main
