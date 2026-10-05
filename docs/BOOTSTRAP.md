# Bootstrap procedure

This procedure sets up a new Mac as this workstation.

The script `scripts/bootstrap.sh` does most of the procedure. This document
gives the reason for the sequence of the steps, and the script is that
sequence. If the document and the script are different, the script is
incorrect.

To see what the script does on a Mac, run it with `--check`. In this mode the
script changes nothing:

```bash
./scripts/bootstrap.sh --check
```

## Before you set up a new Mac

Make sure that these three conditions are true:

- The Mac has a configuration in the repository. See the example below.
- All commits are pushed. The new Mac then clones the current state.
- The Mac permits the bootstrap. You must have administrator rights, and
  device management must not block Nix, Homebrew or the Xcode Command Line
  Tools. Look at this first on a Mac that a company manages.

### Example: add a configuration for a new Mac

This example adds a Mac with the configuration name `studio` and the user
account `alice`.

1. Create `hosts/studio/default.nix`:

   ```nix
   { ... }:

   {
     # The user account of this Mac. All home paths come from this name.
     system.primaryUser = "alice";

     # The applications of this Mac only. The shared list is in
     # modules/darwin/homebrew.nix.
     homebrew.casks = [
       "slack"
     ];

     home-manager.users.alice = {
       # The file name of the GitHub key of this Mac. The key is not in the
       # repository.
       programs.ssh.settings."github.com" = {
         HostName = "github.com";
         User = "git";
         IdentityFile = "~/.ssh/id_ed25519_github";
         IdentitiesOnly = "yes";
       };
     };
   }
   ```

2. Add the configuration to `flake.nix`, below the other configurations:

   ```nix
   darwinConfigurations.studio = mkHost "studio";
   ```

3. Add the new file to Git, because a flake reads only the files that Git
   knows:

   ```bash
   git add hosts/studio
   ```

4. On a Mac that is set up, make sure that the new configuration builds:

   ```bash
   WORKSTATION_HOST=studio ws build
   ```

   The build changes nothing. Ignore the package comparison in the output,
   because it compares the new configuration with the current Mac.

5. Commit and push.

The configuration name is a label. It can be different from the host name of
the Mac.

## The reasons for the sequence

Four facts set the sequence of the steps:

1. The Xcode Command Line Tools supply `git`, and `git` clones this repository.
   Thus the Command Line Tools must be there before the script can run. The
   script looks for them and stops if they are absent. It does not install
   them, because their installer opens a window and that stops a `--yes` run.
2. `darwin-rebuild` does not exist before the first activation of nix-darwin.
   Thus the first build and the first activation run from the flake.
3. The `homebrew` module of nix-darwin manages a Homebrew that exists. It does
   not install Homebrew. Thus step 4 installs Homebrew before the first
   activation that declares casks.
4. The Nix installer changes `/etc/zshrc`, and the shell finds Nix immediately
   after the installation. For that reason, `nix run` works before nix-darwin
   exists. After activation, the zsh integration of nix-darwin puts its
   profiles first on `PATH`.

Because of fact 4, the important check is the sequence of `PATH`: Nix must be
before Homebrew. That the shell finds Nix is not sufficient.

Facts 2 and 3 are easy to forget. On a Mac that works, you do not see them.

Note: the Command Line Tools are necessary to clone and to build. They are not
necessary for the Nix installation, because that installation is a binary.

## Step 0: macOS

Install macOS and complete the setup assistant.

The script installs the available macOS updates before all other software. The
function is `install_macos_updates`, and it runs after the check for the
Command Line Tools. It does these actions:

1. It shows the available updates.
2. It asks for approval.
3. It runs `sudo softwareupdate --install --all`.
4. If a restart is necessary for an update, it stops. Restart the Mac and run
   the script again.

If you refuse the updates, the script continues without them. It also
continues if it cannot get the list of updates.

Note: on a Mac with Apple silicon, a macOS update can ask for the password of
the volume owner. That question stops a `--yes` run.

## Step 1: Xcode Command Line Tools

```bash
xcode-select --install
```

Wait until the installation is complete. The Command Line Tools supply `git`
and the tools that compile software.

This step comes before `scripts/bootstrap.sh`, and it cannot be a part of the
script. The script is in the repository, and `git` is necessary to get the
repository.

To make sure that the tools are installed, run this command:

```console
$ xcode-select -p
/Library/Developer/CommandLineTools
```

## Step 2: clone the repository

The repository is public. Thus you can clone it through HTTPS with no
credential:

```bash
mkdir -p ~/github
git clone https://github.com/nick79/workstation ~/github/workstation
cd ~/github/workstation
```

Push access comes after the bootstrap, when `gh` is installed. Run
`gh auth login` and then `gh auth setup-git`.

You restore or create the SSH keys manually in step 9. No key goes into this
repository.

### A Mac that must not have push access

Some Macs must have no credential for the account of this repository. A work
Mac is an example. Push access is not necessary on such a Mac.

Commit on that Mac. Then move the new commits as a bundle file to a Mac that
can push:

```bash
# On the Mac without push access:
git bundle create /Volumes/<usb>/workstation.bundle origin/main..main

# On the Mac with push access:
git pull /Volumes/<usb>/workstation.bundle main
git push
```

Push before one of the two Macs commits again. Then run `git pull` on the first
Mac. No login is necessary for a pull through HTTPS, because the repository is
public.

## Step 3: install Nix

Install upstream Nix with `nix-installer` from the NixOS Foundation. Before you
run the command on a new Mac, compare it with the upstream documentation. The
command changed more than one time.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

This manual command asks for approval. When you run the script with `--yes`,
the script adds the upstream flag `--no-confirm`, and the installer does not
ask.

Caution: do not omit `--enable-flakes`. The default of this installer is
`false`, and all subsequent steps use flakes. Without the flag, Nix fails in
step 6 with an error that does not point to this step.

Open a new shell and make sure that Nix works:

```console
$ nix --version
nix (Nix) 2.35.2
$ nix flake --help
```

`nix flake --help` shows the help text only when flakes are enabled. If it
fails, do these steps:

1. Add this line to `/etc/nix/nix.conf`:

   ```text
   experimental-features = nix-command flakes
   ```

2. Restart the daemon:

   ```bash
   sudo launchctl kickstart -k system/org.nixos.nix-daemon
   ```

3. Run `nix flake --help` again.

Do not continue until `nix flake --help` works.

### How to uninstall Nix

Read this section before you install Nix.

The installer keeps a receipt in `/nix/receipt.json` and a copy of itself in
`/nix/nix-installer`. Immediately after the installation, make sure that the
uninstaller exists:

```console
$ ls /nix/nix-installer
/nix/nix-installer
```

Before the first activation of nix-darwin, one command removes Nix:

```bash
/nix/nix-installer uninstall
```

The command restores the shell files that the installer changed. It removes
the daemon and the build users, and it deletes the store volume.

After the first activation of nix-darwin, remove nix-darwin first:

```bash
sudo nix run nix-darwin#darwin-uninstaller
/nix/nix-installer uninstall
```

Caution: do not run only the Nix uninstaller while nix-darwin is installed.

### Why the procedure does not use the other installers

| Installer | Reason |
|---|---|
| Determinate installer | It installs only Determinate Nix. Its `--prefer-upstream-nix` flag has no effect now. nix-darwin supports Determinate Nix with `nix.enable = false`, but the result is a Nix that is not upstream Nix, and a vendor flake input |
| Official upstream script | The removal has approximately seven manual steps, with `sudo vifs` and `sudo diskutil apfs deleteVolume /nix`. That is not a reliable method to remove Nix |

## Step 4: install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After this installation, the `homebrew` module of nix-darwin manages the
declared cask list.

In the script, `brew shellenv` sets the variables of Homebrew. Then the script
puts all Nix profiles before Homebrew on `PATH` again. Thus Nix is first during
the bootstrap and also in a new shell.

`nix-homebrew` is a different method. It installs Homebrew during activation,
after the clone. This procedure does not use it.

To install only Nix and Homebrew, run the script with `--installer-only`. The
script stops before activation:

```bash
./scripts/bootstrap.sh --installer-only            # install or examine Nix and Homebrew, then stop
./scripts/bootstrap.sh --check --installer-only    # only report, and change nothing
```

## Step 5: run the bootstrap

```bash
./scripts/bootstrap.sh --check              # report what the script does, and change nothing
./scripts/bootstrap.sh --host <name>        # set up the Mac, and ask before each change
```

The script runs steps 0, 3, 4 and 6. Then it does the checks of step 8 and
prints the manual list of step 9. Steps 1 and 2 cannot be a part of the script,
because the script is in the repository.

You can run the script again safely. Each step first looks if its work is
complete.

| Option | Effect |
|---|---|
| `--check` or `-n` | Examines the Mac and writes a report. Changes nothing |
| `--host <name>` | Selects the `hosts/<name>` configuration. Necessary for the first run on a new Mac |
| `--yes` or `-y` | Does not ask before each change |
| `--installer-only` | Installs Nix and Homebrew, then stops |
| `--help` or `-h` | Shows the options |

### Example: the report of a check

This is the first part of the report on a Mac that has the configuration
`personal`:

```console
$ ./scripts/bootstrap.sh --check
Workstation bootstrap  (check only, no changes)

==> Preflight
  ✓ macOS 27.0.1 (build 26A434)
  ✓ Apple Silicon
  ✓ host: personal

==> Xcode Command Line Tools (prerequisite)
  ✓ present at /Library/Developer/CommandLineTools

==> macOS updates
  · no updates available (already done)

==> Nix
  · nix (Nix) 2.35.2 (already done)
  ✓ Nix uninstaller present: /nix/nix-installer uninstall
  ✓ flakes enabled

==> Homebrew
  · Homebrew 7.0.8 (already done)

==> nix-darwin activation
  · flake inputs locked (already done)
  · would: validate the flake
  · would: build the system configuration for 'personal' (changes nothing)
  · would: activate it
```

The marks have these meanings:

| Mark | Meaning |
|---|---|
| `✓` | The check was successful |
| `·` | The work is complete, or `would:` shows an action that the script does without `--check` |
| `!` | A warning |
| `?` | An action that you must do |

### Example: a full run on a new Mac

```bash
xcode-select --install                                           # step 1
mkdir -p ~/github                                                # step 2
git clone https://github.com/nick79/workstation ~/github/workstation
cd ~/github/workstation
./scripts/bootstrap.sh --check --host studio                     # read the report
./scripts/bootstrap.sh --host studio                             # steps 0, 3, 4, 6, 8
```

Then open a new terminal (step 7) and do the manual tasks of step 9.

## Step 6: lock and first activation

`darwin-rebuild` does not exist at this time. Thus the first build and the
first activation use the package that this flake supplies. That package comes
from the locked `nix-darwin` input.

Always build before you activate. This is most important for the first
activation, because the flake did not run on this Mac before.

```bash
nix flake lock
nix flake check
nix run .#darwin-rebuild -- build  --flake .#<name>      # changes nothing
sudo nix run .#darwin-rebuild -- switch --flake .#<name>
```

The activation uses `sudo`. The build does not.

Do not replace `.#darwin-rebuild` with a `nix-darwin/master` reference. Such a
reference changes with time. The local package keeps the command on the
revision in `flake.lock`.

### The configuration that the script uses

Each Mac has a configuration in `hosts/<name>`. The name is a label, and it can
be different from the host name of the Mac. The host name of a new macOS
installation matches no configuration.

On a new Mac, give the name explicitly:

```bash
./scripts/bootstrap.sh --host <name>
```

Activation writes the name to `/etc/workstation-host`. Subsequent runs of the
script, `ws` and Neovim read the name from that file.

Without `--host` and before the first activation, the script uses the host
name of the Mac. If no `hosts/<name>` matches, the script stops and shows the
available names:

```text
error: no configuration hosts/Alices-MacBook-Pro in this repository.
  Pass the one for this Mac with --host <name>, one of: personal work
```

### If the first activation fails

A rollback to a previous generation is not possible, because there is no
previous generation.

- If the build fails, nothing changed.
- If the activation fails, it possibly changed a part of the system before it
  stopped.

Examine the Mac before you try again. If nix-darwin is installed, remove it
first:

```bash
sudo nix run nix-darwin#darwin-uninstaller
```

To also remove Nix, run this command after that:

```bash
/nix/nix-installer uninstall
```

## Step 7: new shell

Open a new terminal. A new login shell loads the nix-darwin profiles. This is
the first time that you can examine the managed environment.

## Step 8: make sure that the setup is correct

The script does two checks: the sequence of `PATH` and the Git email address of
the Mac. Do the other checks manually:

- Nix is before Homebrew on `PATH`. `which bat` must show a path in a Nix
  profile, not in `/opt/homebrew`:

  ```console
  $ which bat
  /etc/profiles/per-user/alice/bin/bat
  ```

- The prompt shows correctly and the shell plugins load. For example, the
  shell shows a grey suggestion while you type a command from the history.
- `nvim` opens with the configuration of this repository. `Space` shows the
  which-key menu.
- The declared casks are installed. `ws list` shows them in the section
  `Homebrew: casks`.
- The macOS settings are active. Also look at the Control Center items in the
  menu bar. Activation writes them for each host, and you must examine them
  visually.
- The Git configuration comes from the correct files:

  ```bash
  git config --list --show-origin
  ```

## Step 9: tasks that stay manual

The data in this list changes during normal use. For that reason, the
configuration does not declare it, and these tasks stay manual after the
bootstrap:

| Task | Command or action |
|---|---|
| Start the container runtime | `colima start`, when containers are necessary. The bootstrap only installs Colima. It creates no VM and starts nothing. A project that uses more resources supplies its own named profile and flags |
| Install a Python interpreter | `uv python install`. Python comes from uv, not from Nix |
| Set the Git email address of this Mac | `git config --file ~/.config/git/local user.email <address>`, one time. The address is not in the repository. Until you set it, Git refuses to commit |
| Sign in to the applications | Sign in and restore the credentials of each application |
| Restore the SSH keys | Restore the keys and all other secret data from your password manager |
| Clone your projects | Clone the project repositories into `~/github` |

Example: the first commands after the bootstrap.

```bash
git config --file ~/.config/git/local user.email "you@example.com"
gh auth login
gh auth setup-git
uv python install 3.13
```

## Corrections go into the repository

If a manual correction is necessary during a run, that correction is a defect
of the configuration. Put the correction into the repository. Then it is not
necessary in the subsequent run.
