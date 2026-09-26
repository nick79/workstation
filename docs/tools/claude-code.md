# Claude Code configuration

Claude Code itself is a Homebrew cask that updates itself. This repository
manages only the **shared** part of its user configuration
(`modules/home/claude/`); everything personal stays on each machine.

## What is shared and what is not

| Thing | Where | Shared via this repo? |
|---|---|---|
| Rules for every project, e.g. the file-deletion rule | `~/.claude/rules/*.md` | **Yes**, read-only links |
| Status line script | `~/.claude/statusline-command.sh` | **Yes**, read-only link |
| `personal-writing-style` skill | `~/.claude/skills/personal-writing-style/SKILL.md` | **Yes**, read-only link; edit `modules/home/claude/skills/`, then `ws switch` |
| `statusLine`, the delete-command `ask` rules and the Keychain `deny` rules | `~/.claude/settings.json` | **Yes**, merged in on every activation |
| Model, theme, TUI, anything else in `settings.json` | `~/.claude/settings.json` | No, per machine; change freely with `/model`, `/config` |
| Personal instructions (`#` and `/memory` edits) | `~/.claude/CLAUDE.md` | No, per machine and private |
| Auto memory ("Saved 2 memories") | `~/.claude/projects/<project>/memory/` | No, machine-local by design |
| Project instructions | each repository's `CLAUDE.md` | Belongs to that repository |

So work and private memories never mix, and nothing personal reaches this
public repository.

## Common workflows

**Change the default model on this Mac only:** `/model` inside Claude Code.
Nothing else to do; activation never touches `model`.

**Add a rule for every project on every Mac:** create
`modules/home/claude/<topic>.md`, add it to `default.nix` next to
`file-deletion.md` as `home.file.".claude/rules/<topic>.md".source`, then
`ws switch`. One topic per file; keep rules short.

**Add a note for this Mac only:** start a message with `#`, or use `/memory`
and pick the user `CLAUDE.md`. It lands in `~/.claude/CLAUDE.md`.

**Change the status line:** edit `modules/home/claude/statusline-command.sh`,
`ws switch`, restart Claude Code. Editing `~/.claude/statusline-command.sh`
directly is not possible; it is a read-only link.

**Add a shared permission rule:** add it to `permissions.ask` (Claude asks
first) or `permissions.deny` (Claude may never run it) in
`modules/home/claude/settings.shared.json`, `ws switch`. The `deny` list blocks
the commands that print Keychain secrets: Claude Code's commands run as you,
and some Keychain items, such as `gh`'s token, can be read back without a
macOS prompt.

**Remove a shared permission rule:** remove it from `settings.shared.json`
*and* delete it by hand from `~/.claude/settings.json` on each Mac. The merge
only ever adds entries, so it never removes a rule a machine already has.
Conversely, a shared rule deleted inside Claude Code comes back at the next
`ws switch`.

## If activation warns about settings.json

"`settings.json` is not valid JSON; shared Claude Code settings were not
merged" means the file is damaged. It is left exactly as it is. Fix or restore
it, then `ws switch` again. Check it with `jq . ~/.claude/settings.json`.

## Claude Code and Neovim

With Neovim open in the same project, `/ide` in Claude Code connects the two:
Claude sees the current file and selection, and proposed edits open as diffs
in Neovim. Keys are under `Space a` ([neovim.md](neovim.md#claude-code-in-the-editor)).

## Checking what Claude Code loaded

Inside Claude Code, `/memory` lists the loaded instruction files (the rules file
among them) and `/status` shows the settings sources.
