# SSH: shared config and private per-machine hosts

`~/.ssh/config` tells the `ssh` command (and Git, `scp`, `rsync`, anything that
uses SSH) how to reach each server: which address, which user name, which key.
It holds no secrets. Keys are separate files in `~/.ssh/` and never enter this
repository.

This repository is public, so the config is split in three:

| Part | Where | What goes in it |
|---|---|---|
| Shared | `modules/home/ssh.nix` | Settings every Mac uses: macOS Keychain, the Colima include |
| Per host, public | `hosts/<name>/default.nix` | This machine's GitHub key name |
| Per machine, **private** | `~/.ssh/config.local` | Everything you would not publish: lab and work servers, IP addresses, internal host names, jump hosts, user names |

Home Manager writes `~/.ssh/config` as a read-only link. Do not edit it; edit
the Nix files and run `ws switch`, or edit `config.local`, which takes effect
immediately with no switch.

## What the generated file looks like

```sshconfig
Include ~/.ssh/config.local ~/.colima/ssh_config

Host github.com
  HostName github.com
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519_github
  User git

Host *
  AddKeysToAgent yes
  UseKeychain yes
```

Read it top to bottom, the way `ssh` does:

- **`Include`** pulls in your private file, then the file Colima writes for its
  VMs. A file that does not exist is skipped silently, so a fresh machine
  without `config.local` works.
- **`Host github.com`** applies when you connect to `github.com` (every
  `git push` over SSH does).
- **`Host *`** applies to every connection. `AddKeysToAgent` and `UseKeychain`
  mean you type a key's passphrase once and macOS remembers it in the Keychain.

## The one rule that explains everything: first value wins

For each option, `ssh` uses the **first** value it finds, reading top to
bottom, and ignores later ones. Because `config.local` is included at the very
top, anything you put there wins over the shared config.

One exception: `IdentityFile` may appear several times, and every one is kept.
`ssh` tries them in order, so a key named in `config.local` is tried first and
the shared one after it.

Consequence: in `config.local`, put **specific hosts first** and any
`Host *` catch-all **last**, or the catch-all will shadow them.

## Create the private file

Once per machine:

```bash
touch ~/.ssh/config.local
chmod 600 ~/.ssh/config.local
```

`chmod 600` makes it readable only by you. `ssh` refuses a config that other
users can write to.

Then open it in any editor (`nvim ~/.ssh/config.local`) and add blocks. Each
block starts with `Host <alias>`; the indented lines under it apply to that
alias. Indentation is only for readability.

## Examples

### A server with a short name

```sshconfig
Host homelab
  HostName 192.168.1.20
  User alice
  IdentityFile ~/.ssh/id_ed25519_homelab
```

Now `ssh homelab` replaces `ssh -i ~/.ssh/id_ed25519_homelab alice@192.168.1.20`,
and `scp file homelab:` and `rsync -a dir/ homelab:dir/` work the same way.

### Throwaway lab machines

Lab IPs change, and their host keys change with every reset. Keep them out of
your real `known_hosts` so a reset never produces the "REMOTE HOST
IDENTIFICATION HAS CHANGED" warning for a real server:

```sshconfig
Host lab-*
  User root
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  LogLevel ERROR

Host lab-box
  HostName 10.10.11.5
```

`Host lab-*` matches every alias starting with `lab-`. Only ever use
`StrictHostKeyChecking no` for throwaway lab machines: it turns off the check
that protects you from connecting to an impostor.

### A server reachable only through another one (jump host)

```sshconfig
Host bastion
  HostName bastion.example.com
  User alice

Host internal-db
  HostName 10.0.5.12
  User admin
  ProxyJump bastion
```

`ssh internal-db` connects to `bastion` first and hops through it.

### A second GitHub account

```sshconfig
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

Clone with `git clone git@github-work:company/repo.git`; the alias selects the
key. `IdentitiesOnly yes` stops `ssh` from offering every other key in the
agent first, which GitHub would otherwise match to the wrong account.

### Keep idle connections alive

```sshconfig
Host *
  ServerAliveInterval 60
```

Put this at the **end** of `config.local`. It then applies everywhere without
shadowing the specific hosts above it.

## Check what ssh will actually do

```bash
ssh -G homelab | grep -E '^(hostname|user|port|identityfile|proxyjump) '
```

`ssh -G` prints the final settings for an alias after reading every file, and
connects to nothing. Use it whenever a setting does not seem to apply.

`ssh -v homelab` connects and shows which files were read and which keys were
offered.

## Keys

Create a key:

```bash
ssh-keygen -t ed25519 -C "$USER@$(scutil --get LocalHostName)" -f ~/.ssh/id_ed25519_homelab
```

Choose a passphrase; the Keychain settings above mean you type it once. The
command writes two files: the private key (no extension) never leaves the
machine, and the `.pub` file is what you give to a server
(`ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub homelab`) or paste into GitHub.

Back keys up in your password manager. They are not in this repository and a
clean install does not bring them back.

## What is safe to put where

- **Nix files (public):** only what you would accept on a public web page. A
  key's *file name* is fine; the key is not.
- **`config.local` (private):** anything else. It is not in Git, so it is not
  backed up by this repository either. Include it in your own backup before
  erasing or replacing a machine; `docs/BOOTSTRAP.md` lists what a new Mac
  needs restored by hand.
- **Never anywhere in the repository:** private keys, passwords, tokens.
