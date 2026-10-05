# macOS workstation

This repository is the configuration of a macOS development workstation, written
in Nix. The same repository sets up a new Mac and keeps that Mac up to date.

The configuration has two goals. The first goal is that the same commit gives
the same result on each Mac. The second goal is that you can read each file and
know what it does.

The configuration supports only Macs with Apple silicon (`aarch64-darwin`).

## What the configuration contains

| Part | Purpose |
|---|---|
| Nix | Builds and installs each package at the version in `flake.lock` |
| nix-darwin | Applies the system configuration: macOS settings, the firewall, Touch ID for `sudo` |
| Home Manager | Applies the user configuration: the shell, Git, SSH, the command-line tools |
| NixVim | Builds Neovim with its plugins and language servers |
| Ghostty | The terminal |
| zsh and Starship | The shell and its prompt |
| Claude Code | The coding assistant |
| Homebrew | Installs the GUI applications as casks. The cask list is in this repository |

No language runtime is installed globally. Each project gets its compiler or
runtime from its own Nix dev shell, and direnv loads that dev shell. Python is
the exception, because `uv` supplies Python.

## Layout

| Path | Contents |
|---|---|
| `flake.nix` | One nix-darwin system for each Mac, built from `hosts/<name>` |
| `hosts/` | The settings that are different on each Mac: the user account, private applications, power settings |
| `modules/darwin/` | The shared system configuration: macOS settings, Homebrew casks, the firewall, Touch ID for `sudo` |
| `modules/home/` | The shared user configuration: the shell, Git, SSH, command-line tools, containers, Ghostty, Claude Code, `ws` |
| `nixvim/` | The editor: Neovim with language servers, formatters, debuggers and test runners |
| `scripts/bootstrap.sh` | The script that sets up a new Mac. With `--check`, it only writes a report |
| `docs/` | The procedure for a new Mac and one guide for each tool |

## Get started

To set up a new Mac, do the procedure in [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md).

For daily work, use the `ws` command. The [ws guide](docs/tools/ws.md)
describes each subcommand.

### Example: change the configuration

This example changes a shell alias and applies the change.

1. Edit the file:

   ```bash
   cd ~/github/workstation
   nvim modules/home/shell.nix
   ```

2. Build the configuration. This step changes nothing on the Mac:

   ```bash
   ws build
   ```

3. Read the list of package changes that `ws build` shows.
4. Activate the configuration:

   ```bash
   ws switch
   ```

5. Open a new terminal tab and make sure that the alias works.

If the result is incorrect, run `ws rollback` to go back to the previous
generation.

## Tool guides

Each guide describes the daily use of one tool and the solutions to its usual
problems.

| Guide | Contents |
|---|---|
| [Shell](docs/tools/shell.md) | zsh, vi mode, the history, fzf keys, aliases and functions, zoxide, man pages, Starship |
| [CLI tools](docs/tools/cli.md) | fd, ripgrep, fzf, jq, bat, eza, wget, typst, yq, lazydocker, lazysql |
| [Claude Code](docs/tools/claude-code.md) | The settings that all Macs share and the settings that stay on one Mac: rules, status line, permissions, memory |
| [direnv](docs/tools/direnv.md) | Nix dev shells that load when you go into a project directory |
| [Containers](docs/tools/containers.md) | Colima and Docker: the rules, daily use, a profile for each project |
| [SSH](docs/tools/ssh.md) | The shared `~/.ssh/config`, the private hosts in `~/.ssh/config.local`, examples, keys |
| [Git](docs/tools/git.md) | lazygit, merge conflicts, diffs with ec and delta, the email address of each Mac, the scan for secrets, the GitHub CLI (`gh`) |
| [Projects](docs/tools/projects.md) | The files that a project must have for each language (`flake.nix`, `.envrc`, `pyproject.toml`), and what the editor gets from each file |
| [Neovim](docs/tools/neovim.md) | Keys, pickers, buffers and windows, toggles, spelling, and each supported language |
| [ws](docs/tools/ws.md) | How to build, activate, update and roll back the workstation, with Homebrew updates, uv updates and garbage collection |

## License

[MIT](LICENSE).
