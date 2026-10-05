# Shell: zsh, Starship and plugins

The shell is zsh from macOS (`/bin/zsh`). Home Manager supplies only the
configuration of the shell, from `modules/home/shell.nix`. The prompt is
Starship, and its configuration is `modules/home/starship.toml`.

## The configuration files

| File | Written by | Contents |
|---|---|---|
| `~/.zshenv` | Home Manager | The session variables (`EDITOR`, `VISUAL`, `BAT_THEME`, `MANPAGER`) and `~/.local/bin` on `PATH` |
| `~/.zprofile` | Home Manager | `brew shellenv` for login shells |
| `~/.zshrc` | Home Manager | All interactive settings: keymap, history, completion, plugins, prompt |
| `/etc/zshrc` | nix-darwin | Puts the Nix profiles before Homebrew on `PATH` |

All four files are read-only links into the Nix store. Do not edit them. Change
the Nix files in this repository and activate the configuration.

Because the Nix profiles are first on `PATH`, a command that Nix and Homebrew
both install runs the Nix copy.

Some shells do not read `~/.zprofile`, for example a shell that an editor
starts. For these shells, `~/.zshrc` runs `brew shellenv` and then puts the Nix
profiles first again.

## The prompt

The prompt shows these items, from left to right:

| Item | Shown when |
|---|---|
| The directory, in blue | Always. In a repository, the path starts at the repository root |
| The Git branch and the Git status | The directory is in a repository |
| The Python version or the Node version | The directory is a Python project or a Node project |
| The duration of the last command | The command ran for more than 2 seconds |
| The number of background jobs | A background job runs |
| The prompt character | Always |

The prompt character has three states:

- A green `❯` shows that the last command was successful.
- A red `❯` shows that the last command failed.
- A blue `❮` shows that the command line is in vi command mode.

## Edit the command line (vi mode)

The shell starts in vi insert mode. Press `Esc` to go to command mode. Press
`i` or `a` to go back to insert mode.

`KEYTIMEOUT=10` makes the shell react to `Esc` after 0.1 seconds.

| Key | Action |
|---|---|
| `Ctrl-R` | Search the history with fzf |
| `Ctrl-T` | Select a file with fzf and insert its path |
| `**` then `Tab` | Complete with fzf, for example `nvim **` then `Tab`, or `cd **` then `Tab` |
| `Right arrow` | Accept the grey suggestion. In command mode, `$` and `A` also accept it |

### Example: correct a long command

You typed this command and you see that the branch name is incorrect:

```bash
git push origin feature/login-from
```

1. Press `Esc` to go to command mode.
2. Press `b` to move to the start of the word `from`.
3. Type `cw`, then type `form`.
4. Press `Enter` to run the command.

### Example: run a command from the history again

1. Press `Ctrl-R`.
2. Type a part of the command, for example `flake upd`.
3. Use `Ctrl-J` and `Ctrl-K` to move in the list.
4. Press `Enter` to put the command on the command line.
5. Press `Enter` again to run it.

## Aliases and functions

| Name | Action |
|---|---|
| `vim` | Starts Neovim |
| `ls` | eza: a short list |
| `ll` | eza: a long list with hidden files and the Git status |
| `lt` | eza: a tree of two levels |
| `lg` | Starts lazygit |
| `reload` | Runs `exec zsh`. This starts the shell again in the same terminal |
| `path` | Shows `PATH` with one entry on each line, in the search sequence |
| `ports` | Shows the TCP ports that are open for connections and the process of each port |
| `mkcd <dir>` | Makes a directory, with its parent directories, and goes into it |
| `z <text>` | zoxide: goes to the directory that best matches the text |
| `zi` | zoxide: lets you select the directory with fzf |
| `ws` | Maintains the workstation. See [ws.md](ws.md) |

### Examples

Go to a directory that you used before. zoxide records each `cd`, thus `z`
becomes useful after some days of work:

```console
$ z work
$ pwd
/Users/alice/github/workstation
```

Make a project directory and go into it:

```console
$ mkcd ~/github/demo/src
$ pwd
/Users/alice/github/demo/src
```

Find the source of each command on `PATH`:

```console
$ path
/nix/var/nix/profiles/default/bin
/run/current-system/sw/bin
/etc/profiles/per-user/alice/bin
/Users/alice/.nix-profile/bin
/opt/homebrew/bin
/opt/homebrew/sbin
/Users/alice/.local/bin
/usr/local/bin
/usr/bin
/bin
/usr/sbin
/sbin
```

Find the process that uses port 5173:

```console
$ ports | grep 5173
node    41213 alice   23u  IPv6 0x1f2e3d4c      0t0  TCP [::1]:5173 (LISTEN)
```

The second column is the process ID. To stop that process, run `kill 41213`.

### An alias for one Mac only

Put an alias for one Mac in its host file, below
`home-manager.users.<user>`:

```nix
home-manager.users.alice = {
  programs.zsh.shellAliases.proj = "cd ~/github/myproject";
};
```

## Man pages

`man <page>` shows the page through bat (`MANPAGER`), with colours for the
sections. Press `/` to search and `q` to quit.

When you send the output to a different command, the output stays plain text:

```bash
man ls | grep -- --color
```

## Other shell behaviour

- You can type a directory name without `cd` (`AUTO_CD`). For example, `..` or
  `~/github` goes into that directory.
- You can type a comment at the prompt (`INTERACTIVE_COMMENTS`). For example,
  `ls -la # show hidden files` is a correct command.
- The shell does not record a command that starts with a space. Use this for a
  command that contains a secret.
- All open terminals share one history. The history file is `~/.zsh_history`.
  It keeps 100,000 entries and no duplicates.

Example of a command that stays out of the history. Note the space before
`export`:

```bash
 export API_TOKEN="<token>"
```

## Usual tasks

### Use a new shell configuration after an activation

Open a new terminal tab, or run `reload`. An open shell continues to use the
old configuration.

### Find where a command comes from

`which -a <command>` shows each match in the `PATH` sequence:

```console
$ which -a jq
/etc/profiles/per-user/alice/bin/jq
/usr/bin/jq
```

The Nix paths (`/etc/profiles/per-user/...` and `/run/current-system/...`) must
come before `/opt/homebrew`. Here the Nix copy of `jq` is first, and the macOS
copy in `/usr/bin` is second.

### Measure the start time of the shell

```console
$ time zsh -lic exit
zsh -lic exit  0.05s user 0.04s system 88% cpu 0.101 total
```

Approximately 0.1 seconds is normal. The first shell after a change is slower
one time, because it builds the completion cache (`~/.zcompdump`) again.

## No global language runtimes

The shell does not load a language version manager. `node`, `npm` and `java`
exist only in a project whose dev shell supplies them. See
[projects.md](projects.md).

```console
$ cd ~
$ which node
node not found
$ cd ~/github/webapp
direnv: loading ~/github/webapp/.envrc
direnv: using flake
$ which node
/nix/store/<hash>-nodejs-22.20.0/bin/node
```
