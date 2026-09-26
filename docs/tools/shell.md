# Shell: zsh, Starship and plugins

zsh is Apple's `/bin/zsh`; Home Manager owns only its configuration
(`modules/home/shell.nix`). The prompt is Starship, configured in
`modules/home/starship.toml`.

## Where things are

| File | Written by | Holds |
|---|---|---|
| `~/.zshenv` | Home Manager | Session variables (`EDITOR`, `VISUAL`, `BAT_THEME`), `~/.local/bin` on `PATH` |
| `~/.zprofile` | Home Manager | `brew shellenv` for login shells |
| `~/.zshrc` | Home Manager | Everything interactive: keymap, history, completion, plugins, prompt; in a shell that skipped `~/.zprofile`, also `brew shellenv` followed by the Nix-first reorder again |
| `/etc/zshrc` | nix-darwin | Puts the Nix profiles ahead of Homebrew on `PATH`, so a command that exists in both runs the Nix one |

All of these are read-only links into the Nix store. Change the Nix files in
this repository and activate; never edit the generated files.

## Editing the command line (vi mode)

The shell starts in vi insert mode. `Esc` switches to command mode (the prompt
character turns from a green `❯` to a blue `❮`), `i` or `a` goes back.
`KEYTIMEOUT=10` keeps `Esc` fast.

| Key | Does |
|---|---|
| `Ctrl-R` | Fuzzy-search history (fzf) |
| `Ctrl-T` | Fuzzy-pick a file and insert its path (fzf) |
| `**<Tab>` | Fuzzy completion, e.g. `nvim **<Tab>`, `cd **<Tab>` |
| `→` | Accept the grey autosuggestion (in command mode, `$` or `A` also accept it) |

## Aliases and functions

| Name | Does |
|---|---|
| `vim` | Neovim |
| `ls`, `ll`, `lt` | eza: short list, long list with Git status, two-level tree |
| `lg` | lazygit |
| `reload` | `exec zsh`: restart the shell in place after an activation |
| `path` | `PATH` one entry per line, in lookup order |
| `ports` | What is listening on TCP ports, and which process |
| `mkcd <dir>` | Create a directory (with parents) and enter it |
| `z <part>` | zoxide: jump to the best-matching directory you have visited, e.g. `z work` |
| `zi` | zoxide with an fzf picker |
| `ws` | Workstation updates; see [ws.md](ws.md) |

zoxide learns from every `cd`, so `z` gets useful after a few days of use.

## Man pages

`man <page>` is shown through bat (`MANPAGER`): coloured sections, `/` to
search, `q` to quit. Piped output (`man ls | grep …`) stays plain text.

## Conveniences

- **Type a directory name to enter it** (`AUTO_CD`): `..` or `~/github` alone
  works like `cd`.
- **Comments at the prompt** (`INTERACTIVE_COMMENTS`): `ls # why` is valid.
- **A leading space keeps a command out of history**, useful for anything with
  a secret in it.
- **History is shared** between open terminals, 100,000 entries, duplicates
  removed, in `~/.zsh_history`.

## Common workflows

**After an activation changed the shell config:** open a new terminal tab (or
run `reload`). An already open shell keeps the old configuration.

**Check where a command comes from:** `which -a <cmd>` lists every match in
`PATH` order. Nix paths (`/etc/profiles/per-user/…`, `/run/current-system/…`)
should come before `/opt/homebrew`.

**Measure startup time:** `time zsh -lic exit`. About 0.1 s is normal. The very
first shell after a change is slower once while it rebuilds the completion
cache (`~/.zcompdump`).

## No global language runtimes

The shell loads no language version manager. `node`, `npm` and `java` exist
only inside a project whose dev shell provides them
([projects.md](projects.md)).

Aliases for one Mac only go in its host file
(`programs.zsh.shellAliases.<name>` under `home-manager.users.<user>`).
