# macOS Workstation

A reproducible but understandable macOS development workstation, declared with
Nix. One repository provisions a Mac from a clean install and keeps it up to
date afterwards.

Apple Silicon Macs only (`aarch64-darwin`). Core stack: Nix, nix-darwin,
Home Manager, NixVim (Neovim), Ghostty, zsh, Starship, Claude Code. GUI applications are Homebrew casks, declared here.
Language runtimes are not installed globally: each project brings its own
through a Nix dev shell and direnv; Python comes from `uv`.

## Layout

| Path | Holds |
|---|---|
| `flake.nix` | One nix-darwin system per Mac, built from `hosts/<name>` |
| `hosts/` | What differs per Mac: identity, private apps, per-machine settings |
| `modules/darwin/` | Shared system configuration: macOS settings, Homebrew casks, firewall, Touch ID for `sudo` |
| `modules/home/` | Shared user configuration: shell, Git, SSH, CLI tools, containers, Ghostty, Claude Code, `ws` |
| `nixvim/` | The editor: Neovim with language servers, formatting, debugging and tests per language |
| `scripts/bootstrap.sh` | Provisions a new Mac; `--check` reports without changing anything |
| `docs/` | The provisioning guide and one guide per tool |

## Getting started

- A new Mac: follow [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md).
- Day to day: `ws build`, `ws switch`, `ws update` and the rest are in the
  [ws guide](docs/tools/ws.md).

## Tool guides

Short usage guides for the tools this repository installs and configures:

| Guide | Covers |
|---|---|
| [Shell](docs/tools/shell.md) | zsh, vi mode, history, fzf keys, aliases and functions, zoxide, man pages, Starship |
| [CLI tools](docs/tools/cli.md) | fd, ripgrep, fzf, jq, bat, eza, wget, typst, yq, lazydocker, lazysql |
| [Claude Code](docs/tools/claude-code.md) | What is shared across Macs and what stays per machine: rules, status line, settings, memory |
| [direnv](docs/tools/direnv.md) | Per-project Nix dev shells loaded on `cd` |
| [Containers](docs/tools/containers.md) | Colima and Docker: the rules, everyday use, per-project profiles |
| [SSH](docs/tools/ssh.md) | The shared `~/.ssh/config`, private per-machine hosts in `~/.ssh/config.local`, examples, keys |
| [Git](docs/tools/git.md) | lazygit, resolving conflicts with lazygit and ec, reviewing diffs with ec and delta, the per-machine email, the GitHub CLI (`gh`) |
| [Projects](docs/tools/projects.md) | Files to create in a project, per language (`flake.nix`, `.envrc`, `pyproject.toml`), and what the editor expects from each |
| [Neovim](docs/tools/neovim.md) | Keys, pickers, buffers and windows, toggles, spelling, and every supported language |
| [ws](docs/tools/ws.md) | Building, activating, updating and rolling back the workstation; Homebrew and uv updates; garbage collection |

## License

[MIT](LICENSE).
