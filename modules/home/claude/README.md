# Claude Code configuration

Home Manager module for the shared part of the Claude Code user configuration.
How to use and change it: [`docs/tools/claude-code.md`](../../../docs/tools/claude-code.md).

| File | Becomes | How |
|---|---|---|
| `file-deletion.md` | `~/.claude/rules/file-deletion.md` | Read-only link. Claude Code loads every file in `~/.claude/rules/` for every project |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Read-only link, executable |
| `settings.shared.json` | Three keys of `~/.claude/settings.json` | Merged on activation by `default.nix`: `statusLine` is set, `permissions.ask` and `permissions.deny` gain missing entries. Every other key stays per machine |
| `skills/personal-writing-style/SKILL.md` | `~/.claude/skills/personal-writing-style/SKILL.md` | Read-only link: a Claude Code skill for writing prose in the owner's voice |
| `default.nix` | — | The module |

Not managed, on purpose: the rest of `settings.json` (model, theme, TUI),
`~/.claude/CLAUDE.md` (private per-machine instructions), auto memory under
`~/.claude/projects/`, and all session state. Home Manager must never take the
whole `~/.claude/` directory.

## Safety

- No credentials, tokens or API keys. The status-line script only reads the
  JSON that Claude Code pipes to it on stdin.
- No hardcoded home paths; the script uses `$HOME` and the `cwd` from that
  JSON, so it works for any user on any Mac.

## Runtime dependencies

`jq` (from Nix), plus `git`, `awk`, `date` and `bc`.
`bc` comes from the macOS base system and is used once, for the session-cost
line; without it that line degrades silently rather than breaking the status
line.
