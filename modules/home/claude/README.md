# Claude Code configuration

This directory is the Home Manager module for the shared part of the Claude
Code user configuration. The guide
[`docs/tools/claude-code.md`](../../../docs/tools/claude-code.md) describes how
to use it and how to change it.

## The files

| File | Target | Method |
|---|---|---|
| `file-deletion.md` | `~/.claude/rules/file-deletion.md` | A read-only link. Claude Code loads each file in `~/.claude/rules/` for all projects |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | A read-only link that is executable |
| `settings.shared.json` | Three keys of `~/.claude/settings.json` | `default.nix` merges them on activation. It sets `statusLine`, and it adds the entries that `permissions.ask` and `permissions.deny` do not have. All other keys stay as they are on the Mac |
| `skills/personal-writing-style/SKILL.md` | `~/.claude/skills/personal-writing-style/SKILL.md` | A read-only link. This Claude Code skill writes prose in the voice of the owner |
| `default.nix` | None | The module |

## What the module does not manage

The module does not manage these items:

- The other keys of `settings.json`, for example the model, the theme and the
  TUI
- `~/.claude/CLAUDE.md`, the private instructions of one Mac
- The auto memory in `~/.claude/projects/`
- All session state

Home Manager must not manage the full `~/.claude/` directory. If it does, all
files in the directory become read-only links. Claude Code then cannot write
its settings, its memory or its session state.

## Safety

- The files contain no credentials, tokens or API keys. The status line script
  reads only the JSON that Claude Code sends to its standard input.
- The files contain no fixed home paths. The script uses `$HOME` and the `cwd`
  value from that JSON. Thus it works for each user on each Mac.

## Runtime dependencies

The status line script uses `jq` from Nix, and `git`, `awk`, `date` and `bc`.

`bc` comes with macOS. The script uses it one time, for the cost of the
session. Without `bc`, the status line does not show the cost, and its other
parts continue to work.
