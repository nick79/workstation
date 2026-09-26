# ws: keeping the workstation up to date

`ws` is this repository's maintenance command (`modules/home/ws/`). It wraps the
Nix, Homebrew and uv update steps so the order and the safety checks are always
the same. Run `ws` alone for the list of subcommands; `Tab` completes them.

It works on `~/github/workstation` for the configuration named in
`/etc/workstation-host`, which activation writes; before a first activation it
falls back to `scutil --get LocalHostName`. Configuration names are the
directories under `hosts/`, not necessarily the Mac's host name. Set
`WORKSTATION_DIR` to use another checkout, and `WORKSTATION_HOST` to build or
switch to another configuration name once (for example after renaming it).

## Subcommands

| Command | Does | Changes the system |
|---|---|---|
| `ws status` | Active generation, uncommitted repo changes, when each pinned input was last updated, outdated Homebrew count | No |
| `ws list` | Everything installed: Nix home and system packages, Homebrew formulae and casks, uv tools | No |
| `ws check` | `nix flake check` | No |
| `ws build` | Builds the configuration and shows which packages would be added, removed or upgraded (`nvd diff`), then which Homebrew apps the declaration adds or drops | No (writes only `./result`) |
| `ws switch` | `ws build`, then asks, then activates with `sudo` | **Yes** |
| `ws update [input…]` | Updates `flake.lock` (all inputs, or e.g. `ws update nixpkgs`), then `ws build`. Never activates | `flake.lock` only |
| `ws rollback` | Lists generations, asks, returns to the previous one | **Yes** |
| `ws brew` | `brew update && brew upgrade && brew cleanup` | **Yes** |
| `ws tools` | `uv tool upgrade --all` | **Yes** |
| `ws remove <name>…` | Uninstalls a Homebrew cask with its app data (`--zap`), a Homebrew formula (then offers to remove dependencies nothing else needs), or a uv tool. Asks before each. Refuses, and says what to edit, when the name is a cask this repository declares (activation would reinstall it) or a Nix package | **Yes, deletes** |
| `ws upgrade` | Everything: `ws update`, ask to activate, `ws brew`, `ws tools`, then lists pending macOS updates without installing them | **Yes** |
| `ws gc [days]` | Asks, then deletes generations older than `days` (default 30) and unreferenced store paths | **Yes, deletes** |

`sudo` asks for your password in a real terminal. It cannot prompt inside
Claude Code's `!` shell, so run `ws switch`, `ws rollback` and `ws gc` yourself.

## Common workflows

**Change the configuration** (edit a `.nix` file in this repository):

```bash
ws build     # does it build, and what changes?
ws switch    # activate
```

Then open a new terminal tab for shell changes and verify.

**Weekly update of everything:**

```bash
ws upgrade
```

Review the package list before answering `y`. Once everything works, commit
`flake.lock` so every Mac gets the same versions.

**Update only one input:** `ws update nixpkgs` (or `home-manager`,
`nix-darwin`), then `ws switch`.

**Remove an application or tool:** `ws remove <name>`, with the exact
Homebrew or uv name (`brew list`, `uv tool list` or `ws list` shows them).
It works out which kind it is. For something this repository declares, edit
the declaration instead: delete the cask from `homebrew.casks` in
`modules/darwin/homebrew.nix` (an app every Mac has) or in the host file (an
app only this Mac has), or the package from its module, then `ws switch`. A cask removed from
the list stays installed (`cleanup = "none"`), so follow with
`ws remove <name>`.

**Something broke after activating:** `ws rollback`, then open a new tab.
Earlier generations stay available for 30 days.

## Automatic garbage collection

nix-darwin runs `nix-collect-garbage --delete-older-than 30d` every Sunday at
03:15, so old generations do not fill the disk. That is why rollback reaches
back 30 days. `ws gc` does the same on demand, with a different age if you
want (`ws gc 7`).

## macOS updates

`ws upgrade` only **lists** them (`softwareupdate --list`). Install macOS
updates deliberately from System Settings.

## Without ws

The raw commands `ws` wraps, for when `ws` itself is broken. Run them in the
repository; `HOST` is the configuration name (`cat /etc/workstation-host`).
Home Manager runs as a nix-darwin module, so one activation applies both the
system and the user configuration.

```bash
darwin_rebuild="$(command -v darwin-rebuild)"
"$darwin_rebuild" build --flake .#HOST            # changes nothing
sudo "$darwin_rebuild" switch --flake .#HOST

sudo "$darwin_rebuild" --list-generations         # rollback
sudo "$darwin_rebuild" switch --rollback

nix flake check
nix flake update                                  # all inputs
nix flake update nixpkgs                          # one input
```

Update inputs deliberately, never as a side effect of another change, and
commit `flake.lock` with the change that required it. Before nix-darwin's
first activation there is no `darwin-rebuild` yet; see
[BOOTSTRAP.md](../BOOTSTRAP.md) step 6.
