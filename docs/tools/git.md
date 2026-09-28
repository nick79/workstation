# Git: lazygit, ec, delta and the secret scan

Git, lazygit, ec, delta and gitleaks come from Nix (`modules/home/git.nix`).

- **lazygit** (`lg`) is the everyday interface: staging, committing, branches,
  pushing, simple conflicts.
- **ec** is the merge tool for conflicts too tangled for lazygit's own view.
  `git mergetool` opens it, and so does lazygit.
- **delta** renders diffs in the terminal (`git diff`, `git show`, `git log -p`,
  `git blame`) and inside lazygit.

Keys below are for lazygit 0.65.1 and ec 0.4.2. In lazygit, `?` always shows
the keys for the panel you are in.

## Identity: one file per machine

The name is shared; the **email is per machine** and never in this repository,
which is public, while each Mac commits with its own address. On a new
machine, once:

```bash
git config --file ~/.config/git/local user.email "you@example.com"
```

Until that file exists Git refuses to commit ("Author identity unknown")
instead of guessing an address from the host name. Check with
`git config user.email`.

One repository can commit with a different address than the rest of the
machine, for example this one on a work Mac. Set it in that repository's own
`.git/config`, which is never committed and wins over the machine file:

```bash
git -C ~/github/workstation config user.email "you@example.com"
```

`git config --show-origin user.email` shows which file the address came from.

## Secret scan before every commit

Every `git commit`, in every repository, first runs **gitleaks** over the
staged changes. It is a config-based hook (`hook.gitleaks` in the
global Git config, Git 2.54+), so a repository's own `pre-commit` hook still
runs after it, even where `core.hooksPath` points elsewhere. It works the same
from lazygit, Claude Code and Apple's `/usr/bin/git`. Clean commits print
nothing.

When it finds something, the commit stops and the finding is shown with the
secret **redacted**, plus a `Fingerprint:` line. Remove the secret and commit
again. If it is a false positive:

| Do this | Effect |
|---|---|
| Add `gitleaks:allow` in a comment on that line | That line is ignored from now on |
| Add the fingerprint to `.gitleaksignore` in the repository root | That finding is ignored |
| `SKIP=gitleaks git commit …` (or `git commit --no-verify`, which skips every hook) | This one commit is not scanned |
| `git config hook.gitleaks.enabled false` inside the repository | The scan is off for that repository only |
| A `.gitleaks.toml` in the repository root | Replaces the shared rules there; start it with `[extend]` `useDefault = true` |

Exceptions for one repository belong in that repository. The shared rules
(gitleaks' defaults) live in `modules/home/git.nix`; add an exception there
only if it should hold everywhere, then `ws switch`.

The hook checks only what a commit adds. Before committing to this public
repository, also scan the working tree and the whole history:

```bash
gitleaks dir --no-banner --redact .
gitleaks git --no-banner --redact .
```

Both must end with `no leaks found`. gitleaks catches key-shaped secrets, not
personal details, so also read the diff (`git diff --cached`) for anything
that should not be public.

## lazygit: everyday use

Start it with `lg` inside a repository. Panels: `1` status, `2` files,
`3` branches, `4` commits, `5` stash; `h`/`l` or the numbers to move.

| Key | In | Does |
|---|---|---|
| `space` | Files | Stage or unstage the file |
| `a` | Files | Stage or unstage everything |
| `Enter` | Files | Stage individual lines or hunks (`space` on a line, `v` for a range, `Esc` back) |
| `c` | Files | Commit staged changes |
| `A` | Files | Amend the last commit |
| `e` | Files | Open the file in Neovim |
| `d` | Files | Discard changes (asks first) |
| `s` / `S` | Files | Stash / stash options |
| `p` / `P` | Anywhere | Pull / push |
| `f` | Files | Fetch |
| `n` | Branches | New branch |
| `space` | Branches | Check out the selected branch |
| `M` | Branches | Merge the selected branch into the current one |
| `r` | Branches | Rebase the current branch onto the selected one |
| `z` / `Z` | Anywhere | Undo / redo the last Git action (uses the reflog) |
| `\|` | Anywhere | Cycle diff renderer (delta ↔ plain) |
| `q` | Anywhere | Quit |

## Resolving a merge conflict

A merge (`M` on a branch) or rebase (`r`) stops with conflicted files marked in
the Files panel. Conflict markers include the **common ancestor** (the
`|||||||` section, `merge.conflictStyle = zdiff3`), which shows what each side
changed.

**Simple conflicts, in lazygit:**

1. Select the conflicted file and press `Enter`.
2. `←`/`→` (or `h`/`l`) move between conflicts, `↑`/`↓` between the two sides.
3. `space` keeps the selected side, `b` keeps both, `z` undoes a pick.
4. Repeat for each conflicted file. Once none are left, lazygit asks
   "All merge conflicts resolved. Continue the merge?" (or rebase); answer yes.

**Harder conflicts, in ec:**

1. Select the conflicted file and press `M`, then choose **Open external merge
   tool**. That runs `git mergetool`, which opens ec.
2. ec shows three panes: ours (left), result (middle), theirs (right).
3. `n`/`p` go to the next or previous conflict. `h`/`l` select ours or theirs,
   `a` or `space` applies the selection.
4. `o`/`t`/`b`/`x` apply ours, theirs, both or neither directly. `O`/`T` apply
   ours or theirs to **every** conflict in the file.
5. `e` opens the current result in Neovim for a hand edit; ec reloads it
   afterwards.
6. `u` undo, `Ctrl-R` redo. **`w` writes the file**: applied is not saved.
7. `q` quits. Because the tool is trusted (`trustExitCode`), `git mergetool`
   marks the file resolved when ec exits successfully.

**Finish:** if lazygit has not already offered to continue, press `m`
(lowercase) for the merge/rebase menu and choose **continue**, or **abort** to
go back to where you started. On the
command line: `git merge --continue` / `git rebase --continue`, or
`--abort`.

**From the command line without lazygit:** `git mergetool` walks through every
conflicted file in ec in turn. `ec` alone, in a repository, lists conflicted
files first.

No `*.orig` backup files are left behind (`mergetool.keepBackup = false`).

## Reviewing changes with ec

`ec` with no arguments inside a repository opens a selector: conflicted files
first, then **View Diff** for the working tree or any of the last 100 commits.

| Key | Does |
|---|---|
| `h` / `l` | Focus the file list or the diff |
| `j` / `k` | Move or scroll |
| `s` | Toggle side-by-side and unified |
| `e` | Show or hide the file list |
| `q` | Back to the selector |

## ec colours

ec's built-in colours are dark and its code highlighting was hardcoded to a
dark style (`github-dark`), which left most code near-invisible on the light
Ghostty theme. This repository therefore builds ec locally with a one-line
patch that switches code highlighting to the light `github` style, and
installs a theme from Ghostty's Monokai Pro Light Sun palette
(`~/Library/Application Support/ec/themes.json`). Both live in
`modules/home/git.nix`; nixpkgs itself is untouched. Seven upstream tests that
pin the dark style's exact colours are skipped for this build; the rest of ec's
tests run. Colours can be tuned in the `ecTheme` block there.

## delta on the command line

`git diff`, `git show`, `git log -p` and `git blame` page through delta with
line numbers and syntax colours (light theme, matching bat). `git add -p`
shows delta-coloured hunks too. To see Git's plain output for once:
`git --no-pager diff`.

## GitHub from the terminal: gh

`gh` is the GitHub CLI, installed from Nix (`modules/home/cli.nix`). Log in
once per machine:

```bash
gh auth login
```

Choose GitHub.com, SSH as the Git protocol, your existing key (the one the
host file names for `github.com`), and login with a web browser. The
token goes into the macOS Keychain; `~/.config/gh/` holds only settings and is
not managed by this repository. `gh auth status` shows the result.

Everyday commands:

| Command | Does |
|---|---|
| `gh repo create <name> --private --source . --push` | Create a GitHub repository from the current one and push it |
| `gh repo clone <owner>/<name>` | Clone using the configured protocol |
| `gh pr create` / `gh pr list` / `gh pr checkout <n>` | Pull requests |
| `gh run list` / `gh run watch` | GitHub Actions runs |
| `gh browse` | Open the current repository on github.com |

`gh` is not available on a blank Mac before the bootstrap, so it is no help in
cloning this repository there (`docs/BOOTSTRAP.md` Step 2).
