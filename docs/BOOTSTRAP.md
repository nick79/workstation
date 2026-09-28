# Bootstrap Procedure

How a bare Mac becomes this workstation.

**The executable form is `scripts/bootstrap.sh`.** Run `./scripts/bootstrap.sh --check` to see what it would do on the current machine without changing anything. This document explains *why* the order is what it is; the script *is* that order. If they disagree, the script is wrong.

Steps that are unresolved or not yet tested on a bare machine are marked `OPEN:` here and reported as `todo` by the script. They stay marked until a real run proves them.

---

## Ordering constraints

1. The Xcode Command Line Tools are needed to **clone and build**, not to install Nix, which is a binary install. But `git` comes from the CLT, and `git` clones this repository, so the CLT precede the script rather than being installed by it. `scripts/bootstrap.sh` checks for them and stops; it never installs them, which would also open a GUI installer and break `--yes`.
2. `darwin-rebuild` does not exist before nix-darwin's first activation, so the first build and the first switch both run from the flake.
3. nix-darwin's `homebrew` module manages an existing Homebrew; it does not install one. Homebrew is therefore installed explicitly (step 4), before the first activation that declares casks.
4. Nix is visible to the shell as soon as it is installed: the installer patches `/etc/zshrc` itself, which is what makes `nix run` possible before nix-darwin exists. nix-darwin's zsh integration then puts its profiles in front. What needs verifying is `PATH` **order** (Nix before Homebrew), not reachability.

Constraints 2 and 3 are the easiest to miss, because on an already-working machine both are invisible.

---

## Step 0 — macOS

Install macOS and complete first-boot setup.

The script installs every pending macOS update before anything else (`install_macos_updates`, after the Command Line Tools check): it lists the updates, asks, runs `sudo softwareupdate --install --all`, and, if an update needs a restart, stops and asks for a restart and a re-run. Declining, or failing to reach the update server, continues without updates.

`OPEN:` only the "no updates available" path has run. The install and restart paths are untested; on Apple silicon an OS update may also ask for the volume owner's password, which would interrupt `--yes`.

## Step 1 — Xcode Command Line Tools

```bash
xcode-select --install
```

Wait for it to finish. Needed for `git` and for anything that compiles.

**This step precedes `scripts/bootstrap.sh` and cannot be part of it**: `git` comes from the CLT, and `git` clones the repository the script lives in.

## Step 2 — Clone the repository

The repository is public, so it clones over HTTPS with no credential:

```bash
mkdir -p ~/github
git clone https://github.com/nick79/workstation ~/github/workstation
cd ~/github/workstation
```

Push access comes later, once `gh` is installed: `gh auth login`, then `gh auth setup-git`. SSH keys are restored or created by hand (step 9); key material never enters this repository.

A Mac that should hold no credential for this repository's account, such as a work Mac, never needs push access. Commit there, carry the new commits to a Mac that can push as a bundle file, and push from that one:

```bash
git bundle create /Volumes/<usb>/workstation.bundle origin/main..main   # on the Mac without access
git pull /Volumes/<usb>/workstation.bundle main && git push              # on the Mac with access
```

Push before either Mac commits again, then `git pull` on the first one. The repository is public, so pulling over HTTPS needs no login.

`OPEN:` untested on a bare machine.

## Step 3 — Install Nix

Upstream Nix, via the NixOS Foundation's `nix-installer`. Re-check the command against upstream documentation before running it on a new machine; this area has changed more than once.

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

The manual command keeps the installer's confirmation. The script's `--yes` mode adds the upstream `--no-confirm` flag so unattended runs do not stop for input.

**`--enable-flakes` is not optional.** This installer defaults it to `false`, and every later step depends on flakes. Without it, Nix fails at step 6 with an error that does not point back here.

Then open a new shell and verify:

```bash
nix --version
nix flake --help    # confirms flakes are enabled
```

If `nix flake --help` fails, add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf` and restart the daemon with `sudo launchctl kickstart -k system/org.nixos.nix-daemon`. Treat a failure here as fatal.

### Uninstall — know it before installing

The installer stores a receipt at `/nix/receipt.json` and a copy of itself at `/nix/nix-installer`. Confirm the uninstaller exists right after installing.

Before nix-darwin has been activated, removing Nix is one command:

```bash
/nix/nix-installer uninstall
```

It restores the shell files it patched, removes the daemon and build users, and deletes the store volume. After nix-darwin has been activated, remove nix-darwin first:

```bash
sudo nix run nix-darwin#darwin-uninstaller
/nix/nix-installer uninstall
```

Do not run the Nix uninstaller alone while nix-darwin remains installed.

### Why not the other installers

| Option | Why not |
|---|---|
| Determinate installer | It installs Determinate Nix only; its `--prefer-upstream-nix` flag no longer has any effect. nix-darwin supports it via `nix.enable = false`, but that means a non-upstream Nix and a vendor flake input |
| Official upstream script | Uninstalling takes about seven manual steps, including `sudo vifs` and `sudo diskutil apfs deleteVolume /nix`: not a rollback path to rely on |

## Step 4 — Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

nix-darwin's `homebrew` module then manages the declared cask list against it. The script evaluates `brew shellenv` for Homebrew's variables, then puts every Nix profile back in front of Homebrew, so Nix comes first inside the bootstrap as well as in a new shell.

`nix-homebrew` would install Homebrew during activation instead, after the clone. It is not used; its `autoMigrate` option is untested here.

For a prerequisites-only run, use `./scripts/bootstrap.sh --installer-only`: it installs or checks Nix and Homebrew, then stops before activation. `--check --installer-only` reports that boundary without changing anything.

## Step 5 — Run the bootstrap

```bash
./scripts/bootstrap.sh --check              # what would happen; changes nothing
./scripts/bootstrap.sh --host <name>        # provision, asking before each change
```

The script runs steps 0, 3, 4 and 6, then the checks of step 8, and prints the manual list of step 9. Steps 1 and 2 cannot be part of it: the script is inside the repository, so it cannot help obtain the repository. `--yes` runs it without prompts. It is safe to re-run: each step checks whether its work is already done. `grep -n 'OPEN:' docs/BOOTSTRAP.md` lists what is still unproven.

## Step 6 — Lock and first activation

`darwin-rebuild` does not exist yet, so the first build and switch run through the package this flake exposes, which comes from the locked `nix-darwin` input. The build comes first, even for the first activation, when the flake is least proven:

```bash
nix flake lock
nix flake check
nix run .#darwin-rebuild -- build  --flake .#<name>      # changes nothing
sudo nix run .#darwin-rebuild -- switch --flake .#<name>
```

Note `sudo` on the switch but not the build. Do not substitute a moving `nix-darwin/master` reference: the local package keeps the command on the revision in `flake.lock`.

**Which configuration:** each Mac is `hosts/<name>`, and the name is a label, not necessarily the Mac's host name (a fresh install's host name matches nothing). Pass it explicitly on a new Mac: `./scripts/bootstrap.sh --host <name>`. Activation writes it to `/etc/workstation-host`, where later runs, `ws` and Neovim read it. Without `--host` and before a first activation, the script tries the Mac's host name, reports that as `todo`, and stops with the list of available names if no `hosts/<name>` matches.

`OPEN:` the `--host` first run is untested on a bare machine. It has run once on a previously used Mac, cleaned of its old Homebrew tools and dotfiles first (macOS 27.0, Nix 2.35.2): the first activation succeeded with no manual fix.

**If the first activation fails**, generation rollback does not apply: there is no previous generation. A build failure changes nothing, but a switch can fail after activation has already changed part of the system. Inspect the machine before retrying. If nix-darwin was installed, remove it first with `sudo nix run nix-darwin#darwin-uninstaller`; only then use `/nix/nix-installer uninstall` if you also want to remove Nix.

## Step 7 — New shell

Open a new terminal, so the nix-darwin profiles are picked up by a fresh login shell. This is the first point at which the managed environment can be checked.

## Step 8 — Verify

The script checks `PATH` order and the per-machine Git email. The rest is still a manual checklist:

- Nix is on `PATH` **before** Homebrew: `which bat` resolves into a Nix profile, not `/opt/homebrew`.
- The prompt renders and the shell plugins load.
- `nvim` opens with the expected configuration.
- The declared casks are installed (`ws list`).
- The macOS settings took effect, including the Control Center menu-bar items, which are written per host and must be checked visually.
- `git config --list --show-origin` points where expected.

`OPEN:` turn this into script checks with expected output.

## Step 9 — Things Nix deliberately does not do

These are mutable by design and stay manual after provisioning:

- `colima start` when you actually want a container runtime. Provisioning installs Colima and stops there: no VM is created and nothing is started. Projects that need non-default resources bring their own named profile and flags.
- `uv python install` for Python interpreters (Python comes from uv, not Nix).
- The Git email for this machine, once: `git config --file ~/.config/git/local user.email <address>`. It is per machine and never in the repository; until it is set, Git refuses to commit.
- Signing in to the applications and restoring their credentials.
- Restoring SSH keys and any other secret material.
- Cloning project repositories into `~/github`.

This list is part of the design, not an admission of failure: a reproducible machine is one where the boundary between declared and mutable is deliberate.

---

## Before provisioning a new Mac

- The Mac has a configuration: `hosts/<name>/default.nix` with its user account and apps, and `darwinConfigurations.<name> = mkHost "<name>";` in `flake.nix`.
- Everything is pushed, so the Mac clones the current state.
- The Mac allows the bootstrap: administrator rights, and no device-management rule that blocks Nix, Homebrew or the Xcode Command Line Tools. Check this first on a company-managed Mac.

Every manual fix needed during a run is a defect: it goes back into the repository. A working machine that was changed in place is not evidence that provisioning works; only a run on a bare machine is.
