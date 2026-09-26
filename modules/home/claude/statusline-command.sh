#!/bin/bash
# Claude Code status line. It mirrors the directory, Git branch and Git status
# segments of the Starship prompt (~/.config/starship.toml); the prompt's other
# segments are left out.

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
DIM='\033[2m'
RESET='\033[0m'

# --- directory (starship: [directory] style=blue, truncate_to_repo, truncation_length=3) ---
repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
if [ -n "$repo_root" ]; then
    repo_name=$(basename "$repo_root")
    rel_path="${cwd#"$repo_root"}"
    dir_display="${repo_name}${rel_path}"
else
    case "$cwd" in
        "$HOME") home_relative="~" ;;
        "$HOME"/*) home_relative="~${cwd#"$HOME"}" ;;
        *) home_relative="$cwd" ;;
    esac
    dir_display=$(echo "$home_relative" | awk -F/ '{
        n = NF
        start = (n > 3) ? n - 2 : 1
        out = ""
        for (i = start; i <= n; i++) { out = out (out == "" ? "" : "/") $i }
        print out
    }')
fi
[ -z "$dir_display" ] && dir_display="/"

line="${BLUE}${dir_display}${RESET}"

# read_only indicator (starship: [directory] read_only=" ", read_only_style=red)
if [ -n "$cwd" ] && [ ! -w "$cwd" ]; then
    line="${line} ${RED} ${RESET}"
fi

# --- git branch (starship: [git_branch] symbol=" ", style=magenta) ---
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        line="${line} ${MAGENTA} ${branch}${RESET}"
    fi

    # --- git status (starship: [git_status] style=cyan, format=([\[$all_status$ahead_behind\]]) ) ---
    porcelain=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

    conflicted=$(echo "$porcelain" | grep -cE '^(UU|AA|DD) ')
    stashed=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')
    deleted=$(echo "$porcelain" | grep -cE '^.D| D ')
    renamed=$(echo "$porcelain" | grep -cE '^R')
    modified=$(echo "$porcelain" | grep -cE '^.M')
    staged=$(echo "$porcelain" | grep -cE '^[MADRC]')
    untracked=$(echo "$porcelain" | grep -cE '^\?\?')

    all_status=""
    [ "$conflicted" -gt 0 ] && all_status="${all_status}=${conflicted}"
    [ "$stashed" -gt 0 ] && all_status="${all_status}\$${stashed}"
    [ "$deleted" -gt 0 ] && all_status="${all_status}✘${deleted}"
    [ "$renamed" -gt 0 ] && all_status="${all_status}»${renamed}"
    [ "$modified" -gt 0 ] && all_status="${all_status}!${modified}"
    [ "$staged" -gt 0 ] && all_status="${all_status}+${staged}"
    [ "$untracked" -gt 0 ] && all_status="${all_status}?${untracked}"

    ahead_behind=""
    counts=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
    if [ -n "$counts" ]; then
        behind=$(echo "$counts" | awk '{print $1}')
        ahead=$(echo "$counts" | awk '{print $2}')
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            ahead_behind="⇕${ahead}${behind}"
        elif [ "$ahead" -gt 0 ]; then
            ahead_behind="⇡${ahead}"
        elif [ "$behind" -gt 0 ]; then
            ahead_behind="⇣${behind}"
        fi
    fi

    if [ -n "$all_status" ] || [ -n "$ahead_behind" ]; then
        line="${line} ${CYAN}[${all_status}${ahead_behind}]${RESET}"
    fi
fi

# --- usage & limits ---------------------------------------------------------
# Claude Code >= 2.1 passes usage in the statusline JSON:
#   .context_window.used_percentage       -- current context window fill
#   .rate_limits.five_hour                -- {used_percentage, resets_at (unix s)}
#   .rate_limits.seven_day                -- same, weekly window
#   .rate_limits.spend_limit              -- gateway/overage auth only
#   .cost.total_cost_usd                  -- this session
# rate_limits is absent until the session has made at least one API request,
# so every field is optional and silently skipped when missing.

pct_color() {
    # $1 = percentage (may be fractional); green < 50, yellow < 80, red above
    local p=${1%%.*}
    if [ "$p" -ge 80 ]; then printf '%b' "$RED"
    elif [ "$p" -ge 50 ]; then printf '%b' "$YELLOW"
    else printf '%b' "$GREEN"
    fi
}

fmt_reset() {
    # $1 = unix timestamp of window reset -> "2h14m" / "47m" / "" if past/unset
    local secs=$(( $1 - $(date +%s) ))
    [ "$secs" -le 0 ] && return
    local h=$((secs / 3600)) m=$(((secs % 3600) / 60))
    if [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

IFS=$'\t' read -r ctx_pct fh_pct fh_reset wk_pct wk_reset sl_pct cost_usd <<<"$(
    echo "$input" | jq -r '[
        (.context_window.used_percentage      // -1),
        (.rate_limits.five_hour.used_percentage  // -1),
        (.rate_limits.five_hour.resets_at        // 0),
        (.rate_limits.seven_day.used_percentage  // -1),
        (.rate_limits.seven_day.resets_at        // 0),
        (.rate_limits.spend_limit.used_percentage // -1),
        (.cost.total_cost_usd                 // 0)
    ] | @tsv'
)"

usage=""
add_usage() { # $1 = label, $2 = percentage, $3 = optional reset timestamp
    local label=$1 pct=$2 reset=${3:-0} rounded left seg
    case "$pct" in ''|-1|-1.*) return ;; esac
    rounded=$(printf '%.0f' "$pct")
    seg="$(pct_color "$rounded")${label} ${rounded}%${RESET}"
    if [ "$reset" -gt 0 ] 2>/dev/null; then
        left=$(fmt_reset "$reset")
        [ -n "$left" ] && seg="${seg}${DIM}/${left}${RESET}"
    fi
    if [ -n "$usage" ]; then usage="${usage}${DIM} · ${RESET}${seg}"; else usage="$seg"; fi
}

add_usage "ctx" "$ctx_pct"
add_usage "5h"  "$fh_pct" "$fh_reset"
add_usage "wk"  "$wk_pct" "$wk_reset"
add_usage "spend" "$sl_pct"

if [ -n "$usage" ]; then
    line="${line} ${DIM}│${RESET} ${usage}"
fi

# session cost, shown once it is worth seeing
if [ "$(printf '%.0f' "$(echo "$cost_usd * 100" | bc -l 2>/dev/null || echo 0)")" -gt 0 ] 2>/dev/null; then
    line="${line} ${DIM}\$$(printf '%.2f' "$cost_usd")${RESET}"
fi

printf "%b\n" "$line"
