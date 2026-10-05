# SSH: the shared configuration and the private hosts

The file `~/.ssh/config` tells `ssh` how to connect to each server: the
address, the user name and the key. Git, `scp`, `rsync` and all other tools
that use SSH read the same file.

The file contains no secrets. The keys are separate files in `~/.ssh/`, and
they never go into this repository.

## The three parts of the configuration

This repository is public. For that reason, the configuration has three parts:

| Part | Location | Contents |
|---|---|---|
| Shared | `modules/home/ssh.nix` | The settings that all Macs use: the macOS Keychain and the include of the Colima file |
| For one Mac, public | `hosts/<name>/default.nix` | The file name of the GitHub key of this Mac |
| For one Mac, private | `~/.ssh/config.local` | All data that you do not publish: lab servers, work servers, IP addresses, internal host names, jump hosts, user names |

Home Manager writes `~/.ssh/config` as a read-only link. Do not edit it. There
are two correct procedures to change the configuration:

- Edit the Nix files and run `ws switch`.
- Edit `~/.ssh/config.local`. A change to this file has an immediate effect,
  with no activation.

## The generated file

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

`ssh` reads the file from the top to the bottom:

- `Include` loads your private file first, and then the file that Colima writes
  for its VMs. `ssh` ignores a file that does not exist. Thus a new Mac with no
  `config.local` works.
- `Host github.com` applies when you connect to `github.com`. Each `git push`
  through SSH does that.
- `Host *` applies to all connections. With `AddKeysToAgent` and `UseKeychain`,
  you type the passphrase of a key one time. macOS then keeps it in the
  Keychain.

## The rule that the first value wins

For each option, `ssh` uses the first value that it finds and ignores the
values that come after it. `config.local` is at the top of the file. Thus a
value in `config.local` has priority over the shared configuration.

`IdentityFile` is the one exception. `ssh` keeps all `IdentityFile` values and
tries the keys in sequence. A key in `config.local` is first, and the shared key
is second.

This rule has one important result for `config.local`: put the specific hosts
first and put a `Host *` block last. A `Host *` block at the top hides the
values of the blocks below it.

Example: this file is correct. `ssh homelab` uses the user `alice`, and all
other hosts use `bob`.

```sshconfig
Host homelab
  User alice

Host *
  User bob
```

If the `Host *` block is first, `ssh homelab` uses `bob`, because `ssh` finds
that value first.

## Create the private file

Do this procedure one time on each Mac.

1. Create the file and make it readable only by you:

   ```bash
   touch ~/.ssh/config.local
   chmod 600 ~/.ssh/config.local
   ```

2. Open the file in an editor:

   ```bash
   nvim ~/.ssh/config.local
   ```

3. Add one block for each server.

`ssh` refuses a configuration file that other users can write. `chmod 600`
prevents that.

Each block starts with `Host <alias>`. The lines below it apply to that alias.
The indentation only makes the file easier to read.

## Examples

### A server with a short name

```sshconfig
Host homelab
  HostName 192.168.1.20
  User alice
  IdentityFile ~/.ssh/id_ed25519_homelab
```

Now `ssh homelab` does the same as
`ssh -i ~/.ssh/id_ed25519_homelab alice@192.168.1.20`. The alias also works
with other tools:

```bash
scp report.pdf homelab:            # copy a file to the home directory on the server
rsync -a photos/ homelab:photos/   # copy a directory
```

### A server on a different port

```sshconfig
Host buildbox
  HostName build.example.com
  User ci
  Port 2222
```

### Lab machines that you reset frequently

The IP address of a lab machine changes, and its host key changes after each
reset. Keep these keys out of your `known_hosts` file. Then a reset does not
cause the warning `REMOTE HOST IDENTIFICATION HAS CHANGED`.

```sshconfig
Host lab-*
  User root
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  LogLevel ERROR

Host lab-box
  HostName 10.10.11.5
```

`Host lab-*` matches each alias that starts with `lab-`. Thus `ssh lab-box`
uses the settings of the two blocks.

Caution: use `StrictHostKeyChecking no` only for lab machines that you reset.
This setting stops the check that protects you from a false server.

### A server behind a jump host

```sshconfig
Host bastion
  HostName bastion.example.com
  User alice

Host internal-db
  HostName 10.0.5.12
  User admin
  ProxyJump bastion
```

`ssh internal-db` connects to `bastion` first and then connects through it to
`10.0.5.12`.

### A database port on your Mac

This block sends the local port 5433 through `bastion` to port 5432 of the
database server.

```sshconfig
Host db-tunnel
  HostName bastion.example.com
  User alice
  LocalForward 5433 10.0.5.12:5432
```

Start the tunnel in one terminal, and connect in a second terminal:

```bash
ssh -N db-tunnel                                  # stays open until you press Ctrl-C
lazysql postgres://admin@localhost:5433/app       # in the second terminal
```

### A second GitHub account

```sshconfig
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

Clone with the alias in the address:

```bash
git clone git@github-work:company/repo.git
```

The alias selects the key. With `IdentitiesOnly yes`, `ssh` offers only this
key. Without that line, `ssh` first offers the other keys in the agent, and
GitHub can match one of them to the incorrect account.

### Keep idle connections open

```sshconfig
Host *
  ServerAliveInterval 60
```

Put this block at the end of `config.local`. There it applies to all hosts and
does not hide the values of the specific hosts before it.

## See the settings that ssh uses

`ssh -G <alias>` shows the final settings for an alias after `ssh` reads all
files. It does not connect to the server.

```console
$ ssh -G homelab | grep -E '^(hostname|user|port|identityfile|proxyjump) '
user alice
hostname 192.168.1.20
port 22
identityfile ~/.ssh/id_ed25519_homelab
```

Use this command when a setting does not seem to apply. If the output shows a
different value, look for a block that comes first and sets the same option.

`ssh -v homelab` connects to the server. It shows the files that `ssh` read and
the keys that `ssh` offered.

## Keys

### Create a key

```bash
ssh-keygen -t ed25519 -C "$USER@$(scutil --get LocalHostName)" -f ~/.ssh/id_ed25519_homelab
```

Give the key a passphrase. Because of the Keychain settings, you type it only
one time.

The command writes two files:

| File | Use |
|---|---|
| `~/.ssh/id_ed25519_homelab` | The private key. It stays on the Mac |
| `~/.ssh/id_ed25519_homelab.pub` | The public key. Give this file to a server or to GitHub |

### Install the public key

On a server:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub homelab
```

On GitHub, copy the public key and add it in the SSH key settings of your
account:

```bash
pbcopy < ~/.ssh/id_ed25519_github.pub
```

Then make sure that GitHub accepts the key:

```console
$ ssh -T git@github.com
Hi alice! You've successfully authenticated, but GitHub does not provide shell access.
```

### Keep a backup of the keys

Keep a copy of each key in your password manager. The keys are not in this
repository. If you erase a Mac, its keys are gone.

## What you can put in each location

| Location | Permitted contents |
|---|---|
| The Nix files (public) | Only data that you accept on a public web page. The file name of a key is permitted. The key is not |
| `~/.ssh/config.local` (private) | All other configuration |
| Not in the repository | Private keys, passwords, tokens |

`config.local` is not in Git, thus this repository is not a backup of it.
Include the file in your own backup before you erase or replace a Mac.
[BOOTSTRAP.md](../BOOTSTRAP.md) contains the list of items that you must
restore manually on a new Mac.
