# ws: keep the workstation up to date

`ws` is the maintenance command of this repository. Its source is in
`modules/home/ws/`. It runs the Nix, Homebrew and uv update steps in a fixed
sequence, with the same safety checks each time.

Run `ws` with no arguments to see the list of subcommands. Type `ws`, a space,
and then press `Tab` to complete a subcommand.

## The repository and the configuration that ws uses

`ws` uses the repository in `~/github/workstation`. It builds the configuration
that the file `/etc/workstation-host` names. Activation writes that file.

Before the first activation, the file does not exist. Then `ws` uses the output
of `scutil --get LocalHostName` as the configuration name.

A configuration name is the name of a directory in `hosts/`, for example
`personal` or `work`. The name is a label. It can be different from the host
name of the Mac.

Two environment variables change these defaults:

| Variable | Effect | Example |
|---|---|---|
| `WORKSTATION_DIR` | `ws` uses a different clone of the repository | `WORKSTATION_DIR=~/src/workstation ws build` |
| `WORKSTATION_HOST` | `ws` uses a different configuration name for one command | `WORKSTATION_HOST=work ws build` |

`WORKSTATION_HOST` is necessary after you change the name of a configuration.
For example, you change `hosts/personal` to `hosts/home` and update `flake.nix`.
The file `/etc/workstation-host` continues to contain `personal`, and
`ws switch` fails. Run `WORKSTATION_HOST=home ws switch` one time. That
activation writes the new name to the file.

## Subcommands

The first four subcommands only read. The other subcommands change the Mac or
the repository.

| Command | Result | Changes the Mac |
|---|---|---|
| `ws status` | Shows the active generation and the changes in the repository that are not committed. Also shows the date of each pinned input and the number of outdated Homebrew packages | No |
| `ws list` | Shows all installed software: Nix home packages, Nix system packages, Homebrew formulae and casks, uv tools | No |
| `ws check` | Runs `nix flake check` | No |
| `ws build` | Builds the configuration. Then shows the packages that activation adds, removes or upgrades (`nvd diff`), and the Homebrew applications that the declaration adds or removes | No. It writes only `./result` |
| `ws switch` | Runs `ws build`, asks for approval, then activates with `sudo` | Yes |
| `ws update [input]` | Updates `flake.lock` for all inputs or for the inputs that you name, then runs `ws build`. It does not activate | Only `flake.lock` |
| `ws rollback` | Shows the generations, asks for approval, then goes back to the previous generation | Yes |
| `ws brew` | Runs `brew update && brew upgrade && brew cleanup` | Yes |
| `ws tools` | Runs `uv tool upgrade --all` | Yes |
| `ws remove <name>` | Uninstalls a Homebrew cask, a Homebrew formula or a uv tool. See [Remove an application or a tool](#remove-an-application-or-a-tool) | Yes, and it deletes data |
| `ws upgrade` | Runs `ws update`, asks to activate, runs `ws brew` and `ws tools`, then shows the macOS updates that are available. It does not install the macOS updates | Yes |
| `ws gc [days]` | Asks for approval, then deletes the generations that are older than `days` (the default is 30) and the store paths that nothing uses | Yes, and it deletes data |

`ws remove` and `ws update` accept more than one name, for example
`ws update nixpkgs home-manager`.

Note: `sudo` asks for your password in a terminal. It cannot ask in the `!`
shell of Claude Code. Thus you must run `ws switch`, `ws rollback` and `ws gc`
in a terminal.

## Examples

### See the state of the Mac

```console
$ ws status

==> Active system
/nix/store/<hash>-darwin-system-26.11.4cff07d

==> Repository (/Users/alice/github/workstation)
## main...origin/main
 M modules/home/shell.nix

==> Pinned inputs (last updated)
flake-parts   2026-09-03
home-manager  2026-10-05
nix-darwin    2026-08-16
nixpkgs       2026-10-04
nixvim        2026-10-02
systems       2026-03-25

==> Homebrew
0 outdated package(s)
```

The line that starts with `M` shows one file with a change that is not
committed. The dates show when each input in `flake.lock` got its last update.

### Change the configuration

1. Edit a `.nix` file in the repository.
2. Build the configuration and read the changes:

   ```bash
   ws build
   ```

3. If the changes are correct, activate them:

   ```bash
   ws switch
   ```

4. Open a new terminal tab. An open shell continues to use the old shell
   configuration.
5. Make sure that the change works.

When a change does not change a package, `ws build` shows this output:

```text
==> Changes against the running system
<<< /run/current-system
>>> /Users/alice/github/workstation/result
No version or selection state changes.
Closure size: 1543 -> 1543 (0 paths added, 0 paths removed, delta +0, disk usage +0B).

==> Homebrew declaration
No changes.
```

### Add a command-line tool to all Macs

This example adds `hyperfine`.

1. Add the package to `home.packages` in `modules/home/cli.nix`:

   ```nix
   home.packages = [
     pkgs.bat
     pkgs.eza
     # ... the other packages
     pkgs.hyperfine
   ];
   ```

2. Run `ws build`. The output contains the new package. The version in this
   example is not a real result:

   ```text
   Added packages:
   [A.]  #1  hyperfine  1.20.0
   ```

3. Run `ws switch` and open a new terminal tab.
4. Make sure that the shell finds the Nix copy:

   ```console
   $ which hyperfine
   /etc/profiles/per-user/alice/bin/hyperfine
   ```

5. Add a section for the tool to [cli.md](cli.md).

To find the name of a package, run `nix search nixpkgs hyperfine`.

### Add an application to one Mac

A GUI application is a Homebrew cask. The shared list is `homebrew.casks` in
`modules/darwin/homebrew.nix`. A host file adds the applications for one Mac.

This example adds Zoom to the `work` Mac only.

1. Add the cask to `homebrew.casks` in `hosts/work/default.nix`:

   ```nix
   homebrew.casks = [
     "google-chrome"
     # ... the other casks
     "zoom"
   ];
   ```

2. Run `ws build`. The last section of the output shows the new cask:

   ```text
   ==> Homebrew declaration
     + cask zoom
   ```

3. Run `ws switch`. Activation installs the cask.

To find the name of a cask, run `brew search zoom`.

### Update all software one time each week

```bash
ws upgrade
```

1. Read the list of package changes before you answer `y`.
2. Use the Mac for some time after the activation.
3. When all tools work, commit `flake.lock`. Then each Mac gets the same
   versions.

### Update only one input

```bash
ws update nixpkgs
ws switch
```

The inputs are `nixpkgs`, `home-manager`, `nix-darwin` and `nixvim`.

### Remove an application or a tool

`ws remove <name>` finds the type of the software by its name. Use the exact
Homebrew name or uv name. `ws list`, `brew list` and `uv tool list` show the
names.

| Type | What `ws remove` does |
|---|---|
| Homebrew cask | Uninstalls the application and its support files (`--zap`) |
| Homebrew formula | Uninstalls the formula. Then offers to remove the dependencies that nothing else uses |
| uv tool | Uninstalls the tool |
| Cask in this repository | Stops, and tells you the file that you must edit. Activation installs a declared cask again |
| Nix package | Stops, and tells you to remove the package from its module |

`ws remove` asks for approval before each removal.

Caution: `ws remove` deletes the support files of a cask. These files contain
the settings and the data of the application.

To remove an application that this repository declares, do these steps. The
example removes Typora from all Macs.

1. Delete `"typora"` from `homebrew.casks` in `modules/darwin/homebrew.nix`.
   For an application of one Mac, edit the host file.
2. Run `ws switch`. The output of the build shows the removal:

   ```text
   ==> Homebrew declaration
     - cask typora
   Removed entries stay installed (cleanup = "none"); follow with 'ws remove <name>'.
   ```

3. Run `ws remove typora`. Activation does not uninstall a cask that you remove
   from the list, because `cleanup` is `"none"`.

To remove a Nix package, delete it from its module and run `ws switch`.

### Go back after an incorrect activation

```bash
ws rollback
```

`ws rollback` shows the generations and asks for approval. Then it activates
the previous generation. Open a new terminal tab after the rollback.

Generations stay available for 30 days.

## Automatic garbage collection

nix-darwin runs `nix-collect-garbage --delete-older-than 30d` each Sunday at
03:15. This prevents a full disk. It is also the reason why a rollback can go
back only 30 days.

`ws gc` does the same task when you run it. To use a different age, give the
number of days:

```bash
ws gc        # generations older than 30 days
ws gc 7      # generations older than 7 days
```

Caution: you cannot roll back to a generation that `ws gc` deletes.

## macOS updates

`ws upgrade` only shows the macOS updates (`softwareupdate --list`). Install
them from System Settings when you are ready for a restart.

## Without ws

If `ws` does not work, use the commands that it runs. Run them in the
repository. `HOST` is the configuration name. `cat /etc/workstation-host` shows
it.

Home Manager runs as a nix-darwin module. Thus one activation applies the
system configuration and the user configuration.

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

Update the inputs as a separate task, not as a side effect of a different
change. If a change makes an update necessary, commit `flake.lock` together
with that change.

Before the first activation of nix-darwin, `darwin-rebuild` does not exist.
Step 6 of [BOOTSTRAP.md](../BOOTSTRAP.md) gives the commands for that
condition.
