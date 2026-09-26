# Command-line tools

Everyday tools from Nix (`modules/home/cli.nix`). `which -a <tool>` shows the
Nix path under `/etc/profiles/per-user/$USER/bin` first (macOS's own
`/usr/bin/jq` comes after the Nix `jq`).

## Finding files: fd

A faster, friendlier `find`. It skips hidden files and anything in
`.gitignore` unless told otherwise.

```bash
fd config                 # names containing "config", from here down
fd -e nix                 # by extension
fd -e md docs/            # in a directory
fd -H .env                # include hidden files
fd -I node_modules        # include ignored files
fd -e log -x wc -l        # run a command on each match
```

## Searching contents: ripgrep (`rg`)

Recursive text search, also respecting `.gitignore` and skipping hidden files.

```bash
rg TODO                   # search from here down
rg -i 'error|warn'        # case-insensitive regex
rg -t nix programs        # only one file type (rg --type-list shows them)
rg -l stateVersion        # only list matching files
rg -C 2 darwin-rebuild    # two lines of context
rg -uu secret             # include ignored and hidden files
rg -F 'a.b(c)'            # literal text, no regex
```

No output and exit status 1 means no match, not an error.

## Fuzzy finding: fzf

Wired into the shell (see [shell.md](shell.md)): `Ctrl-R` history, `Ctrl-T`
file path, `**<Tab>` completion. It also works in pipes:

```bash
nvim "$(fd -e md | fzf)"               # pick a file to edit
git switch "$(git branch --format='%(refname:short)' | fzf)"
```

## JSON: jq

```bash
jq . file.json                        # pretty-print
jq '.name' package.json               # one field
jq -r '.items[].id' data.json         # raw strings, one per line
curl -s https://api.github.com/repos/nix-community/home-manager | jq '{stars: .stargazers_count, updated: .pushed_at}'
```

The Claude Code status line depends on it.

## Viewing files: bat

`cat` with syntax colours, line numbers and Git change markers, in the light
theme (`BAT_THEME`). Also the man-page pager.

```bash
bat flake.nix
bat -p notes.txt          # plain, no decorations
bat -r 10:30 file.nix     # line range
```

## Listing: eza

Behind the `ls`, `ll` and `lt` aliases in [shell.md](shell.md). `ll` adds a Git
status column; `lt` is a two-level tree (`eza --tree --level=4` for deeper).

## Downloading: wget

```bash
wget https://example.com/file.iso      # download into the current directory
wget -c https://example.com/file.iso   # resume an interrupted download
```

## Documents: typst

Typesetting. Compiles `.typ` sources to PDF.

```bash
typst compile doc.typ             # writes doc.pdf next to it
typst watch doc.typ               # recompile on every save
typst fonts                       # fonts typst can see
```

## YAML, TOML and more: yq

mikefarah's `yq` (nixpkgs `yq-go`): `jq`-style queries for YAML, JSON, TOML and
XML.

```bash
yq '.services | keys' compose.yaml          # read
yq -i '.version = "2"' config.yaml          # edit in place
yq -o json config.yaml                      # convert YAML to JSON
yq -p toml -o yaml Cargo.toml               # convert TOML to YAML
```

## Shell scripts: shellcheck and shfmt

Not installed globally: like language servers, linters and formatters ship
with Neovim's configuration, next to the language server that drives them,
rather than on the global `PATH`. In Neovim, `bash-language-server` runs
shellcheck as you type and shfmt formats with `Space c f`. For a one-off check
outside the editor, run them without installing:

```bash
nix run nixpkgs#shellcheck -- script.sh
nix run nixpkgs#shfmt -- -d -i 2 script.sh
```

`ws` is checked by shellcheck automatically when it is built.

## Containers: lazydocker

lazygit's sibling for containers: containers, images, volumes, logs and stats
in one screen. It needs a running Docker engine, which here is Colima. Colima
never starts automatically, so its VM uses no memory until you need it:

```bash
colima start          # when you actually need containers
lazydocker
colima stop           # when done
```

Keys follow lazygit: `?` help, `[`/`]` tabs, `d` remove, `r` restart,
`Enter` logs, `q` quit.

## Databases: lazysql

A terminal UI for SQL databases (PostgreSQL, MySQL, SQLite, SQL Server).

```bash
lazysql                                      # manage saved connections
lazysql postgres://user@localhost:5432/db    # open one directly
lazysql ./app.db                             # a SQLite file
```

Saved connections live in lazysql's own config file and may contain passwords,
which is why it is not managed by this repository.
