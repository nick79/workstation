# Claude Code configuration

Claude Code is a Homebrew cask, and it updates itself. This repository manages
only the shared part of its user configuration, from `modules/home/claude/`.
All personal configuration stays on each Mac.

## What is shared and what is not

| Item | Location | Shared through this repository |
|---|---|---|
| The rules for all projects, for example the file deletion rule | `~/.claude/rules/*.md` | Yes, as read-only links |
| The status line script | `~/.claude/statusline-command.sh` | Yes, as a read-only link |
| The `personal-writing-style` skill | `~/.claude/skills/personal-writing-style/SKILL.md` | Yes, as a read-only link |
| `statusLine`, the `ask` rules for delete commands and the `deny` rules for the Keychain | `~/.claude/settings.json` | Yes. Each activation merges them into the file |
| The model, the theme, the TUI and all other keys of `settings.json` | `~/.claude/settings.json` | No. Change them with `/model` and `/config` |
| Personal instructions (from `#` and `/memory`) | `~/.claude/CLAUDE.md` | No. They are private and stay on the Mac |
| Auto memory (the message "Saved 2 memories") | `~/.claude/projects/<project>/memory/` | No. It stays on the Mac |
| Project instructions | The `CLAUDE.md` of each repository | They are a part of that repository |

This has two results. Work memories and private memories do not mix. No
personal data gets into this public repository.

## How the merge of settings.json works

Activation does not replace `~/.claude/settings.json`. It changes three keys
and keeps all other keys:

- It sets `statusLine` to the value in `settings.shared.json`.
- It adds the shared `permissions.ask` rules that the file does not have.
- It adds the shared `permissions.deny` rules that the file does not have.

Example: the file on a Mac before an activation.

```json
{
  "model": "opus",
  "permissions": {
    "ask": ["Bash(docker system prune *)"]
  }
}
```

The same file after the activation. The model and the rule of the Mac stay.
The lists are shortened in this example.

```json
{
  "model": "opus",
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  },
  "permissions": {
    "ask": ["Bash(docker system prune *)", "Bash(rm *)", "Bash(rmdir *)"],
    "deny": ["Bash(security find-generic-password *)", "Bash(gh auth token*)"]
  }
}
```

## Usual tasks

### Change the default model on this Mac only

Run `/model` in Claude Code. No other step is necessary, because activation
does not change `model`.

### Add a rule for all projects on all Macs

This example adds a rule about commit messages.

1. Create `modules/home/claude/commit-messages.md`:

   ```markdown
   # Commit messages

   - Write the subject line as a command, with a maximum of 60 characters.
   - Do not add a co-author line.
   ```

2. Add the file to `modules/home/claude/default.nix`, below the line for
   `file-deletion.md`:

   ```nix
   home.file.".claude/rules/commit-messages.md".source = ./commit-messages.md;
   ```

3. Run `ws switch`.
4. Start Claude Code again and run `/memory`. The list must contain the new
   file.

Write one file for each topic, and keep each rule short.

### Add a note for this Mac only

There are two procedures:

- Start a message with `#`, for example `# This Mac has no Docker VM`.
- Run `/memory` and select the user `CLAUDE.md`.

The note goes into `~/.claude/CLAUDE.md`.

### Change the status line

1. Edit `modules/home/claude/statusline-command.sh`.
2. Run `ws switch`.
3. Start Claude Code again.

You cannot edit `~/.claude/statusline-command.sh` directly, because it is a
read-only link.

To do a test of the script without Claude Code, send it JSON on standard
input:

```bash
echo '{"cwd":"'"$PWD"'"}' | bash modules/home/claude/statusline-command.sh
```

The command prints the status line for the current directory: the directory
name, the Git branch and the Git status.

### Add a shared permission rule

Add the rule to `modules/home/claude/settings.shared.json` and run `ws switch`.
Use one of the two lists:

| List | Effect |
|---|---|
| `permissions.ask` | Claude asks before it runs the command |
| `permissions.deny` | Claude cannot run the command |

Example: make Claude ask before it uninstalls a Homebrew package.

```json
"ask": [
  "Bash(rm *)",
  "Bash(brew uninstall *)"
]
```

After the activation, make sure that the rule is in the file of the Mac:

```console
$ jq '.permissions.ask' ~/.claude/settings.json
[
  "Bash(rm *)",
  "Bash(rmdir *)",
  "Bash(unlink *)",
  "Bash(trash *)",
  "Bash(git clean *)",
  "Bash(find * -delete*)",
  "Bash(brew uninstall *)"
]
```

The `deny` list blocks the commands that print secrets from the Keychain. The
commands of Claude Code run as your user. Some Keychain items, for example the
token of `gh`, are readable without a macOS prompt.

### Remove a shared permission rule

The merge only adds entries. It does not remove a rule that a Mac has. Thus a
removal has two steps:

1. Remove the rule from `settings.shared.json`.
2. On each Mac, open `~/.claude/settings.json` in an editor and delete the
   rule.

The opposite also applies. If you delete a shared rule in Claude Code, the
next `ws switch` adds it again.

## If activation shows a warning about settings.json

The warning is:

```text
/Users/alice/.claude/settings.json is not valid JSON; shared Claude Code settings were not merged
```

The file has a syntax error. Activation does not change the file.

1. Find the error. In this example, a comma is missing at the end of line 2:

   ```console
   $ jq . ~/.claude/settings.json
   jq: parse error: Expected separator between values at line 3, column 15
   ```

2. Repair the file, or restore it from a backup.
3. Run `ws switch` again.

## Claude Code and Neovim

Open Neovim in the project. Then run `/ide` in Claude Code to connect the two.
Claude sees the current file and the selection, and Neovim shows each proposed
edit as a diff.

The keys start with `Space a`. See
[neovim.md](neovim.md#claude-code-in-the-editor).

## See what Claude Code loaded

| Command in Claude Code | Result |
|---|---|
| `/memory` | Shows the instruction files that Claude Code loaded. The rule files are in this list |
| `/status` | Shows the sources of the settings |
