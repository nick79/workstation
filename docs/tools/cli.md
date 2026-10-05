# Command-line tools

Nix installs the daily command-line tools from `modules/home/cli.nix`. The
examples in this guide use the files of this repository, thus you can run them
in `~/github/workstation`.

To make sure that a tool comes from Nix, run `which -a <tool>`. The Nix path
must be first:

```console
$ which -a jq
/etc/profiles/per-user/alice/bin/jq
/usr/bin/jq
```

Two tools from the same module have their sections in other guides: `gh` in
[git.md](git.md) and `uv` in [projects.md](projects.md#python).

## Find files: fd

`fd` finds files by name. It is faster than `find` and its options are shorter.
It ignores hidden files and the files that `.gitignore` excludes, unless you
give an option.

```bash
fd config                 # names that contain "config", in this directory and below
fd -e nix                 # by extension
fd -e md docs/            # in one directory
fd -H .env                # include hidden files
fd -I node_modules        # include ignored files
fd -e log -x wc -l        # run a command on each match
```

Example: find the Nix files in two directories.

```console
$ fd -e nix . hosts modules/darwin
hosts/personal/default.nix
hosts/work/default.nix
modules/darwin/default.nix
modules/darwin/homebrew.nix
modules/darwin/macos-defaults.nix
modules/darwin/user.nix
```

The first argument is the pattern. A `.` matches all names. The other arguments
are the directories.

Example: count the lines of each match.

```console
$ fd -e nix . modules/darwin -x wc -l
     193 modules/darwin/macos-defaults.nix
      24 modules/darwin/user.nix
      44 modules/darwin/default.nix
      37 modules/darwin/homebrew.nix
```

## Search in files: ripgrep (`rg`)

`rg` searches text in a directory and all directories below it. It also ignores
hidden files and the files that `.gitignore` excludes.

```bash
rg TODO                   # search in this directory and below
rg -i 'error|warn'        # regular expression, upper case and lower case
rg -t nix programs        # only one file type (rg --type-list shows the types)
rg -l stateVersion        # show only the names of the files
rg -C 2 darwin-rebuild    # show two lines before and after each match
rg -uu secret             # include ignored files and hidden files
rg -F 'a.b(c)'            # literal text, not a regular expression
```

Example: find the files that use an option.

```console
$ rg -l primaryUser
hosts/personal/default.nix
hosts/work/default.nix
modules/darwin/macos-defaults.nix
modules/darwin/user.nix
```

Example: find a setting with its line number.

```console
$ rg -n cleanup modules/darwin/homebrew.nix
30:      cleanup = "none";
```

Note: when `rg` finds no match, it writes nothing and its exit status is 1.
This is not an error.

```console
$ rg text-that-is-not-there
$ echo $?
1
```

## Fuzzy search: fzf

fzf lets you type some letters and select one line from a list. The shell uses
it for three keys. [shell.md](shell.md) describes them:

- `Ctrl-R` searches the history.
- `Ctrl-T` inserts a file path.
- `**` and then `Tab` completes a path.

fzf also works in a pipe. It reads lines and writes the line that you select.

```bash
nvim "$(fd -e md | fzf)"                                        # select a file and edit it
git switch "$(git branch --format='%(refname:short)' | fzf)"    # select a branch
```

Example: find the files that contain a text, select one, and edit it.

```bash
nvim "$(rg -l stateVersion | fzf)"
```

## JSON: jq

```bash
jq . file.json                        # show the file with indentation
jq '.name' package.json               # one field
jq -r '.items[].id' data.json         # plain strings, one on each line
```

Example: show the inputs that `flake.lock` pins.

```console
$ jq -r '.nodes | keys[]' flake.lock
flake-parts
home-manager
nix-darwin
nixpkgs
nixvim
root
systems
```

Example: show the date of the pinned nixpkgs.

```console
$ jq -r '.nodes.nixpkgs.locked.lastModified | todate' flake.lock
2026-10-04T07:06:02Z
```

Example: get two fields from a web API and give them new names.

```bash
curl -s https://api.github.com/repos/nix-community/home-manager \
  | jq '{stars: .stargazers_count, updated: .pushed_at}'
```

The status line of Claude Code uses `jq`. Do not remove it.

## Show files: bat

`bat` shows a file as `cat` does, and adds syntax colours, line numbers and
Git change marks. It uses a light theme (`BAT_THEME`). It is also the pager for
man pages.

```bash
bat flake.nix             # with colours and line numbers
bat -p notes.txt          # plain: no line numbers and no frame
bat -r 10:30 file.nix     # only lines 10 to 30
bat -l json response.txt  # set the language when the extension does not show it
```

Example: show the first lines of a file as plain text.

```console
$ bat -p -r 1:3 .gitignore
.DS_Store
.direnv/
.env
```

## Lists of files: eza

`eza` is the tool behind the `ls`, `ll` and `lt` aliases in
[shell.md](shell.md).

| Alias | Result |
|---|---|
| `ls` | A short list, with directories first |
| `ll` | A long list with hidden files and a Git status column |
| `lt` | A tree of two levels |

For a deeper tree, give the level:

```bash
eza --tree --level=4
```

Example: a tree of one level.

```console
$ eza --tree --level=1 --group-directories-first docs
docs
├── tools
└── BOOTSTRAP.md
```

## Downloads: wget

```bash
wget https://example.com/file.iso            # download into the current directory
wget -c https://example.com/file.iso         # continue a download that stopped
wget -O ~/Downloads/tool.tar.gz <url>        # set the name of the output file
```

## Documents: typst

`typst` is a typesetting system. It compiles `.typ` source files to PDF.

```bash
typst compile doc.typ             # writes doc.pdf in the same directory
typst watch doc.typ               # compiles again after each save
typst fonts                       # shows the fonts that typst can use
```

Example: a small document. Put this text in `letter.typ`:

```typst
#set page(paper: "a4", margin: 2.5cm)
#set text(size: 11pt)

= Meeting notes

- The build is *green*.
- The next release is on Friday.
```

Then run `typst compile letter.typ` and open `letter.pdf`.

## YAML, TOML and XML: yq

This `yq` is the tool by mikefarah (nixpkgs `yq-go`). It uses the query
language of `jq` for YAML, JSON, TOML and XML.

```bash
yq '.services | keys' compose.yaml          # read
yq -i '.version = "2"' config.yaml          # edit the file
yq -o json config.yaml                      # convert YAML to JSON
yq -p toml -o yaml Cargo.toml               # convert TOML to YAML
```

Example: read one table from the Starship configuration as JSON.

```console
$ yq -p toml -o json '.character' modules/home/starship.toml
{
  "success_symbol": "[❯](bold green)",
  "error_symbol": "[❯](bold red)",
  "vimcmd_symbol": "[❮](bold blue)"
}
```

Note: when you give `-p`, also give `-o`. Without `-o`, `yq` writes YAML and a
warning.

## Shell scripts: shellcheck and shfmt

These two tools are not installed globally. Linters and formatters come with
the Neovim configuration, together with the language server that uses them.

In Neovim, `bash-language-server` runs shellcheck while you type. `Space c f`
formats the file with shfmt.

For one check outside the editor, run the tools without an installation:

```bash
nix run nixpkgs#shellcheck -- script.sh
nix run nixpkgs#shfmt -- -d -i 2 script.sh    # show the format changes as a diff
```

The build of `ws` runs shellcheck on the `ws` script automatically.

## Containers: lazydocker

lazydocker is a terminal interface for containers, images, volumes, logs and
statistics. It uses the same key layout as lazygit.

lazydocker works only while a Docker engine runs. On this workstation the engine is
Colima, and Colima does not start automatically. Thus its VM uses no memory
until you start it.

```bash
colima start          # start the VM when containers are necessary
lazydocker
colima stop           # stop the VM after the work
```

| Key | Action |
|---|---|
| `?` | Show the help |
| `[` and `]` | Go to the previous tab or the next tab |
| `Enter` | Show the logs |
| `r` | Restart the container |
| `d` | Remove the container |
| `q` | Quit |

See [containers.md](containers.md) for Colima.

## Databases: lazysql

lazysql is a terminal interface for SQL databases: PostgreSQL, MySQL, SQLite
and SQL Server.

```bash
lazysql                                      # manage the saved connections
lazysql postgres://user@localhost:5432/db    # open one database directly
lazysql ./app.db                             # open a SQLite file
```

lazysql keeps the saved connections in its own configuration file. That file
can contain passwords. For this reason, this repository does not manage it.
