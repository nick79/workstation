# Git: lazygit, ec, delta and the scan for secrets

Nix installs Git, lazygit, ec, delta and gitleaks from `modules/home/git.nix`.

| Tool | Use |
|---|---|
| lazygit (`lg`) | The daily interface: stage, commit, change branches, push, and solve simple conflicts |
| ec | The merge tool for conflicts that are too complex for lazygit. `git mergetool` opens it, and lazygit can open it |
| delta | Shows diffs in the terminal (`git diff`, `git show`, `git log -p`, `git blame`) and in lazygit |
| gitleaks | Scans each commit for secrets |

The keys in this guide are for lazygit 0.65.1 and ec 0.4.2. In lazygit, `?`
shows the keys of the current panel.

## Identity: one file on each Mac

All Macs share the user name. The email address is different on each Mac, and
it is not in this repository. The repository is public, and each Mac commits
with its own address.

Set the address one time on a new Mac:

```bash
git config --file ~/.config/git/local user.email "you@example.com"
```

Until that file exists, Git refuses to commit and shows the message
`Author identity unknown`. It does not make an address from the host name.

To see the address and the file that it comes from, run this command:

```console
$ git config --show-origin user.email
file:/Users/alice/.config/git/local    you@example.com
```

### A different address for one repository

One repository can use a different address than the other repositories on the
Mac. An example is this repository on a work Mac.

Set the address in the `.git/config` file of that repository. Git does not
commit that file, and it has priority over the file of the Mac:

```bash
git -C ~/github/workstation config user.email "you@example.com"
```

After this command, the origin is the repository:

```console
$ git -C ~/github/workstation config --show-origin user.email
file:.git/config    you@example.com
```

## The scan for secrets before each commit

Each `git commit`, in each repository, first runs gitleaks on the staged
changes. A clean commit shows no output from the scan.

The scan is a hook in the Git configuration (`hook.gitleaks` in the global
configuration, Git 2.54 or later). This has three effects:

- The `pre-commit` hook of a repository continues to run after the scan.
- The scan also runs where `core.hooksPath` points to a different directory.
- The scan works the same from lazygit, from Claude Code and from the Git of
  Apple (`/usr/bin/git`).

### When the scan finds a secret

The commit stops. gitleaks shows the finding with the secret redacted, and a
`Fingerprint:` line:

```text
Finding:     API_TOKEN = "REDACTED"
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     3.787326
File:        settings.py
Line:        3
Fingerprint: settings.py:generic-api-key:3

12:20PM WRN leaks found: 1

gitleaks stopped this commit: the staged changes look like they contain
a secret (shown redacted above). Remove it and commit again. If it is a
false positive:
  - add  gitleaks:allow  in a comment on that line, or
  - add the Fingerprint above to .gitleaksignore in the repository, or
  - skip once:  SKIP=gitleaks git commit ...
```

If the finding is a real secret, remove it from the file and commit again.

### When the finding is not a secret

| Action | Effect |
|---|---|
| Add `gitleaks:allow` in a comment on that line | gitleaks ignores that line from now on |
| Add the fingerprint to `.gitleaksignore` in the repository root | gitleaks ignores that finding |
| Run `SKIP=gitleaks git commit` | gitleaks does not scan this one commit |
| Run `git commit --no-verify` | Git runs no hook for this one commit |
| Run `git config hook.gitleaks.enabled false` in the repository | The scan is off for that repository only |
| Add a `.gitleaks.toml` file in the repository root | The file replaces the shared rules in that repository |

Example: a comment on the line.

```python
TEST_FIXTURE = "<a value that looks like a secret>"  # gitleaks:allow
```

Example: a `.gitleaksignore` file. Each line is one fingerprint from the
output of gitleaks.

```text
settings.py:generic-api-key:3
```

Example: a `.gitleaks.toml` file that keeps the default rules and ignores one
directory. Start the file with the `[extend]` table.

```toml
[extend]
useDefault = true

[[allowlists]]
description = "Test fixtures"
paths = ['''tests/fixtures/.*''']
```

An exception for one repository goes in that repository. The shared rules are
the defaults of gitleaks, and they are in `modules/home/git.nix`. Add an
exception there only if it must apply to all repositories. Then run
`ws switch`.

### The two full scans for this repository

The hook examines only the changes that a commit adds. Before each commit to
this public repository, also scan the working tree and the full history:

```bash
gitleaks dir --no-banner --redact .
gitleaks git --no-banner --redact .
```

The two commands must end with `no leaks found`. If one of them shows a
finding, do not commit.

gitleaks finds text that has the shape of a key. It does not find personal
data. Thus also read the staged diff (`git diff --cached`) and look for data
that must not be public: names, addresses, host names, IP addresses.

## lazygit: daily use

Run `lg` in a repository. The panels have numbers: `1` status, `2` files, `3`
branches, `4` commits, `5` stash. Press a number, or `h` and `l`, to move
between the panels.

| Key | Panel | Action |
|---|---|---|
| `space` | Files | Stage or unstage the file |
| `a` | Files | Stage or unstage all files |
| `Enter` | Files | Stage lines or hunks: `space` on a line, `v` for a range, `Esc` to go back |
| `c` | Files | Commit the staged changes |
| `A` | Files | Amend the last commit |
| `e` | Files | Open the file in Neovim |
| `d` | Files | Discard the changes. lazygit asks first |
| `s` / `S` | Files | Stash / show the stash options |
| `p` / `P` | All | Pull / push |
| `f` | Files | Fetch |
| `n` | Branches | Create a branch |
| `space` | Branches | Check out the selected branch |
| `M` | Branches | Merge the selected branch into the current branch |
| `r` | Branches | Rebase the current branch onto the selected branch |
| `z` / `Z` | All | Undo / redo the last Git action. This uses the reflog |
| `\|` | All | Change the diff renderer between delta and plain |
| `q` | All | Quit |

### Example: commit two files and push

1. Run `lg`.
2. Press `2` to go to the Files panel.
3. Move to the first file with `j` and `k`, and press `space` to stage it.
4. Stage the second file in the same way.
5. Press `c`, type the commit message, and press `Enter`.
6. Press `P` to push.

### Example: commit only a part of a file

1. In the Files panel, select the file and press `Enter`.
2. Move to a changed line and press `space` to stage it. To stage a range,
   press `v`, move, and then press `space`.
3. Press `Esc` to go back to the Files panel.
4. Press `c` and write the commit message.

The lines that you did not stage stay in the working tree as changes.

### Example: start a branch for a change

1. Press `3` to go to the Branches panel.
2. Press `n` and type the name, for example `fix/prompt-colour`.
3. Make the change and commit it.
4. Press `P` to push. lazygit asks for the upstream the first time.

### Example: undo an incorrect action

Press `z`. lazygit shows the action that it will undo and asks for approval.
This works for a commit, a merge, a rebase or a checkout, because lazygit uses
the reflog. `Z` does the action again.

## Solve a merge conflict

A merge (`M` on a branch) or a rebase (`r`) stops when files have conflicts.
The Files panel shows these files with a conflict mark.

The conflict markers also contain the common ancestor, in the section after
`|||||||` (`merge.conflictStyle = zdiff3`). The ancestor shows what each side
changed.

```text
    <<<<<<< HEAD
    timeout = 30
    ||||||| 1a2b3c4
    timeout = 10
    =======
    timeout = 60
    >>>>>>> feature/retries
```

In this example the original value was `10`. Your branch changed it to `30`,
and the other branch changed it to `60`. In a real file, the markers start in
the first column. They have an indentation here so that Git and the Markdown
linter do not read this guide as a file with a conflict.

### Simple conflicts: lazygit

1. Select the file with the conflict and press `Enter`.
2. Press `Left arrow` and `Right arrow` (or `h` and `l`) to move between the
   conflicts.
3. Press `Up arrow` and `Down arrow` to move between the two sides.
4. Press `space` to keep the selected side, or `b` to keep the two sides. `z`
   cancels the last selection.
5. Do steps 1 to 4 for each file with a conflict.
6. When no conflict stays, lazygit asks `All merge conflicts resolved. Continue
   the merge?` (or the rebase). Answer yes.

### Complex conflicts: ec

1. Select the file with the conflict and press `M`.
2. Select **Open external merge tool**. This runs `git mergetool`, and
   `git mergetool` opens ec.
3. Read the three panes: ours on the left, the result in the middle, theirs on
   the right.
4. Solve each conflict with the keys in the table.
5. Press `w` to write the file.
6. Press `q` to quit.

| Key | Action |
|---|---|
| `n` / `p` | Go to the next / previous conflict |
| `h` / `l` | Select ours / theirs |
| `a` or `space` | Apply the selection |
| `o` / `t` / `b` / `x` | Apply ours / theirs / the two sides / no side |
| `O` / `T` | Apply ours / theirs to all conflicts in the file |
| `e` | Open the result in Neovim for a manual edit. ec loads the file again after you close Neovim |
| `u` / `Ctrl-R` | Undo / redo |
| `w` | Write the file |
| `q` | Quit |

Caution: a selection that you apply is not saved until you press `w`.

Git trusts the exit status of ec (`trustExitCode`). Thus `git mergetool` marks
the file as solved when ec exits with no error.

### Complete or stop the merge

If lazygit did not offer to continue, press `m` (lower case) to open the menu
for the merge or the rebase. Select **continue** to complete it. Select
**abort** to go back to the state before the merge.

The equivalent commands are:

```bash
git merge --continue      # or: git rebase --continue
git merge --abort         # or: git rebase --abort
```

### Without lazygit

`git mergetool` opens each file with a conflict in ec, one after the other. If
you run `ec` alone in a repository, it shows the files with conflicts first.

Git does not keep `*.orig` backup files after a merge
(`mergetool.keepBackup = false`).

## Review changes with ec

Run `ec` with no arguments in a repository. ec opens a selector with the files
that have conflicts first. Below them is **View Diff** for the working tree and
for each of the last 100 commits.

| Key | Action |
|---|---|
| `h` / `l` | Go to the file list / the diff |
| `j` / `k` | Move or scroll |
| `s` | Change between the side-by-side view and the unified view |
| `e` | Show or hide the file list |
| `q` | Go back to the selector |

Example: read a commit before you push it.

1. Run `ec` in the repository.
2. In the selector, select **View Diff** for the commit.
3. Press `l` to go to the diff, and scroll with `j` and `k`.
4. Press `s` if the lines are too long for the side-by-side view.
5. Press `q` to go back to the selector.

## The colours of ec

The colours of ec are for a dark terminal, and ec sets a dark style
(`github-dark`) for code. On the light Ghostty theme, most code was almost
invisible.

For this reason, this repository builds ec locally with two changes:

- A patch of one line changes the code style to the light `github` style.
- A theme from the Monokai Pro Light Sun palette of Ghostty sets the colours of
  the interface. The theme file is
  `~/Library/Application Support/ec/themes.json`.

The two changes are in `modules/home/git.nix`, and nixpkgs stays unchanged. To
adjust a colour, edit the `ecTheme` block in that file.

The build skips seven tests of ec that expect the exact colours of the dark
style. All other tests of ec run.

## delta on the command line

`git diff`, `git show`, `git log -p` and `git blame` send their output through
delta. delta adds line numbers and syntax colours, in a light theme that
matches bat. `git add -p` also shows its hunks with the colours of delta.

```bash
git diff                         # the changes that are not staged
git diff --cached                # the staged changes
git show HEAD~1                  # the commit before the last one
git log -p -- modules/home/      # the history of one directory, with diffs
git --no-pager diff              # the plain output of Git, for one command
```

## GitHub from the terminal: gh

`gh` is the GitHub CLI. Nix installs it from `modules/home/cli.nix`.

### Log in

Log in one time on each Mac:

```bash
gh auth login
```

`gh` asks some questions. Give these answers:

| Subject of the question | Answer |
|---|---|
| The GitHub host | GitHub.com |
| The protocol for Git | SSH |
| The SSH key | The key that you have. This is the key that the host file names for `github.com` |
| The authentication method | Login with a web browser |

`gh` puts the token in the macOS Keychain. The directory `~/.config/gh/`
contains only settings, and this repository does not manage it. To see the
result, run `gh auth status`.

### Daily commands

| Command | Result |
|---|---|
| `gh repo create <name> --private --source . --push` | Creates a GitHub repository from the current repository and pushes it |
| `gh repo clone <owner>/<name>` | Clones a repository with the configured protocol |
| `gh pr create` | Creates a pull request |
| `gh pr list` | Shows the open pull requests |
| `gh pr checkout <n>` | Checks out the branch of a pull request |
| `gh run list` | Shows the last GitHub Actions runs |
| `gh run watch` | Follows a run until it completes |
| `gh browse` | Opens the current repository on github.com |

Example: open a pull request for the current branch and follow its checks.

```bash
git push -u origin fix/prompt-colour
gh pr create --fill          # the title and the text come from the commits
gh pr checks --watch         # wait for the checks
gh pr view --web             # open the pull request in the browser
```

Example: do a review of the pull request of a colleague on your Mac.

```bash
gh pr checkout 42
nvim .
gh pr review 42 --approve
```

Note: `gh` is not available on a new Mac before the bootstrap. Thus it cannot
help you to clone this repository there. See Step 2 of
[BOOTSTRAP.md](../BOOTSTRAP.md).
