# Neovim

Neovim is built with NixVim from `nixvim/` in this repository. There is
no plugin manager and nothing is downloaded at runtime: every plugin comes
from Nix. To change the editor, edit `nixvim/`, then run `ws build` and
`ws switch`. Editing `~/.config/nvim/init.lua` does nothing lasting, because it
is a link into the Nix store.

The leader key is `Space`. Press it and wait: which-key lists what comes next.
It works the same after `g`, `z`, `[`, `]` and `<C-w>`.

## Everyday keys

| Keys | Does |
|---|---|
| `Ctrl-S` | Save, in any mode |
| `Esc` | Also clears search highlighting |
| `Space Space` | Find a file |
| `Space /` | Grep the project |
| `Space ,` | Switch buffer |
| `Space e` | File explorer (also opens for `nvim .`) |
| `Shift-H` / `Shift-L` | Previous / next buffer |
| `Ctrl-h/j/k/l` | Move between windows |
| `Space -` / `Space \|` | Split below / right |
| `Space q q` | Quit everything (asks about unsaved files) |

`j` and `k` move by screen line in wrapped text; with a count (`5j`) they move
by real line, so relative numbers still work.

## Finding things: `Space f` and `Space s`

Every picker works the same way: type to filter, `Ctrl-j`/`Ctrl-k` or the
arrows to move, `Enter` to open, `Ctrl-v`/`Ctrl-s` to open in a vertical /
horizontal split, `Esc` to close. `Space s R` reopens the last picker where you
left it.

| Keys | Picker |
|---|---|
| `Space f f` | Files (respects `.gitignore`) |
| `Space f F` | Files, including hidden and ignored ones |
| `Space f r` | Recent files |
| `Space f b` | Buffers |
| `Space f c` | This repository's `nixvim/` configuration |
| `Space f n` | New empty file |
| `Space s g` | Grep |
| `Space s w` | Grep the word under the cursor, or the selection |
| `Space s b` | Lines in the current buffer |
| `Space s h` / `s k` / `s C` | Help pages / keymaps / commands |
| `Space s u` | Undo history. Undo survives closing the file |
| `Space s m` / `s j` / `s "` | Marks / jumps / registers |
| `Space s M` | Man pages |
| `Space s q` / `s l` | Quickfix / location list entries |
| `Space :` | Command history |

## Buffers, windows and tabs

| Keys | Does |
|---|---|
| `Space b b` | Previous buffer (the `#` file) |
| `Space b d` | Close the buffer, keep the window |
| `Space b o` | Close every other buffer |
| `Space w` | All `<C-w>` window commands, listed by which-key |
| `Space w d` | Close the window |
| `Space w m` | Maximise or restore the window |
| `Ctrl-arrows` | Resize the window |
| `Space Tab Tab` | New tab |
| `Space Tab ]` / `[` | Next / previous tab |
| `Space Tab d` / `o` | Close the tab / every other tab |
| `Space x q` / `x l` | Open or close the quickfix / location list |

In help, quickfix and `:checkhealth` windows, `q` closes the window.

The buffer bar at the top appears once more than one buffer is open.

## Toggles: `Space u`

| Keys | Toggles |
|---|---|
| `Space u s` | Spell checking |
| `Space u w` | Soft wrap |
| `Space u l` / `u L` | Line numbers / relative numbers |
| `Space u z` | Zen mode: one centred 120-column window |
| `Space u Z` | Zoom the current window |
| `Space u n` | Dismiss notifications (`Space n` shows their history) |
| `Space u C` | Try another colour scheme for this session |
| `Space u t` | Pinned function/class context at the top |
| `Space u p` | Auto-closing brackets and quotes |
| `Space u G` | Git signs |
| `Space u d` | Diagnostics |
| `Space u h` | Inlay hints |
| `Space u f` / `u F` | Format on save, everywhere / this buffer |
| `Space u m` | Rendered Markdown |

## Text objects and motions

Operators (`d`, `c`, `y`, `v`, ...) combine with text objects: `a` takes the
whole thing, `i` the inside. `daf` deletes a function, `ci"` changes inside
quotes, `vic` selects a class body. They find the next match if the cursor is
not inside one, and a count reaches outwards (`2dib`).

| Object | Is |
|---|---|
| `f` | Function (from the syntax tree) |
| `c` | Class |
| `o` | Block, conditional or loop |
| `u` / `U` | Function call (`U` also for `obj.method(...)`) |
| `a` | Argument |
| `b` | Any bracket: `()`, `[]`, `{}` |
| `q` | Any quote |
| `t` | HTML/XML tag |
| `d` | Number |
| `g` | Whole file (`ig` skips blank lines at both ends) |
| `h` | Git hunk (`dih`, `vih`) |

Built-ins such as `iw`, `ip`, `i(` and `it` work as always.

| Keys | Moves to |
|---|---|
| `]f` / `[f` | Next / previous function start (`]F` / `[F`: end) |
| `]c` / `[c` | Next / previous class start (`]C` / `[C`: end). In diff mode: next / previous change |
| `]h` / `[h` | Next / previous Git hunk (`]H` / `[H`: last / first) |

The function or class around the cursor stays pinned at the top of the window
while you scroll (`Space u t` toggles it). Folds follow the syntax tree and
start open: `za` toggles one, `zM` closes all, `zR` opens all.

## Surround and pairs

Under `gs`, so the built-in `s` keeps working. The last key is the
surrounding: `)`, `]`, `}`, `"`, `'`, `` ` ``, `t` for a tag (asks for the
name), `f` for a function call (asks for the name).

| Keys | Does | Example |
|---|---|---|
| `gsa{motion}{char}` | Add | `gsaiw"` quotes a word; in visual mode `gsa"` |
| `gsd{char}` | Delete | `gsd)` removes the parentheses around the cursor |
| `gsr{old}{new}` | Replace | `gsr"'` turns double quotes into single |
| `gsf` / `gsF` | Find the next / previous surrounding | |
| `gsh` | Highlight it briefly | |

Opening brackets and quotes close themselves as you type; `Space u p` turns
that off.

## Git

Changed lines are marked in the sign column: a bar for added and changed, a
low line where lines were deleted. Staged changes are marked too, in a paler colour.

| Keys | Does |
|---|---|
| `Space g g` | lazygit in a floating window. `e` on a file opens it in this Neovim; `q` returns |
| `Space g s` | Changed files (picker) |
| `Space g d` | Changed hunks across the project (picker) |
| `Space g l` / `g f` | Log / history of this file |
| `Space g b` | Commits that touched the current line |
| `Space g B` | Open the file (or the selected lines) on GitHub |
| `Space g Y` | Copy that link |
| `Space g h s` | Stage the hunk (or the selected lines). On a staged hunk: unstage it |
| `Space g h r` | Reset the hunk to the index (discards the change) |
| `Space g h S` / `h R` | Stage / reset the whole file |
| `Space g h p` | Preview the hunk inline |
| `Space g h b` | Blame the line, with the full commit message |
| `Space g h B` | Blame the whole file in a side window |
| `Space g h d` / `h D` | Diff against the index / the last commit |
| `Space u G` | Toggle the Git signs |

Reviewing a large diff and resolving conflicts are still done in lazygit and
`ec` ([git.md](git.md)).

## Terminal

`Ctrl-/` opens a terminal at the bottom and hides it again, from normal and
terminal mode alike; the shell keeps running while hidden. `Space f t` does
the same. Inside, `Esc Esc` switches to normal mode for scrolling and
copying; `i` goes back.

## Sessions

When Neovim exits, the open files and windows for the current directory are
saved. The dashboard's `s`, or `Space q s`, brings them back.

| Keys | Does |
|---|---|
| `Space q s` | Restore this directory's session |
| `Space q l` | Restore the last session, wherever it was |
| `Space q S` | Pick a session |
| `Space q d` | Don't save the session when quitting this time |

## Code intelligence

A language server starts by itself when a file of its language opens. Built
into the editor for any directory: Nix (nixd, which knows this repository's
nix-darwin and Home Manager options), Lua, shell (sh and bash, with
shellcheck), Markdown, JSON, YAML and TOML. Python, Java, web, Go, Rust, C/C++,
Ruby, PHP, Elixir, Terraform and SQL have their own sections below; several of
them need the project's dev shell. `Space c l` lists the servers running for
the current file.

| Keys | Does |
|---|---|
| `K` | Documentation for the symbol (press again to enter the window) |
| `gd` | Go to definition (`Ctrl-o` comes back) |
| `gD` | Go to declaration |
| `grr` | References |
| `gri` / `grt` | Implementation / type definition |
| `gai` / `gao` | Incoming / outgoing calls |
| `gK` | Signature help (also shown automatically while typing arguments) |
| `]]` / `[[` | Next / previous use of the symbol under the cursor |
| `grn` or `Space c r` | Rename the symbol everywhere |
| `gra` or `Space c a` | Code action (quick fix) |
| `Space c A` | Source action (organise imports and the like) |
| `Space c R` | Rename the file, updating imports where the server supports it |
| `Space s s` / `s S` | Symbols in this file / in the project |
| `gO` | Outline of this file |

Other uses of the symbol under the cursor are highlighted after a moment.

## Diagnostics

Errors and warnings appear at the end of the line and as icons in the sign
column.

| Keys | Does |
|---|---|
| `Space c d` | Full message for the current line |
| `]d` / `[d` | Next / previous diagnostic |
| `]e` / `[e` | Next / previous error |
| `]w` / `[w` | Next / previous warning |
| `Space s d` / `s D` | Diagnostics in this file / the project (picker) |
| `Space x x` | Diagnostics (picker) |
| `Space u d` | Hide or show diagnostics |
| `Space u h` | Inlay hints (types and parameter names inline, where supported) |

## Completion

The menu opens as you type, with the first item selected.

| Keys | Does |
|---|---|
| `Enter` | Accept the selected item |
| `Tab` / `Shift-Tab`, `Ctrl-n` / `Ctrl-p`, arrows | Next / previous item |
| `Ctrl-Space` | Open the menu, or toggle the documentation beside it |
| `Ctrl-e` | Close the menu |
| `Ctrl-b` / `Ctrl-f` | Scroll the documentation |
| `Tab` / `Shift-Tab` in a snippet | Jump to the next / previous placeholder |

Items come from the language server, file paths (type `./` or `~/`),
snippets and words in open buffers.

## Formatting

`Space c f` formats the file, or the selection, at any time.

Format on save is **off unless the project asks for it**, so opening and
saving an existing file never rewrites code you did not touch. It turns on by
itself in a project that has a formatter configuration: `stylua.toml`, a
prettier config, `biome.json` (or `.biome.json`), `ruff.toml`, `rustfmt.toml`, `.clang-format`,
`treefmt.toml`, `rumdl.toml` or `tombi.toml`, or a `[tool.ruff]` or
`[tool.rumdl]` section in `pyproject.toml`, or `.rubocop.yml`,
`.standard.yml`, `pint.json`, `.php-cs-fixer.php`, `.formatter.exs` or
`.sql-formatter.json`. Go and Rust files also turn it on in a project with a
`go.mod` or `Cargo.toml` (other files there are left alone), and Terraform
files always do.

| Keys | Does |
|---|---|
| `Space u f` | Format on save for every buffer, this session |
| `Space u F` | Format on save for this buffer only (wins over `Space u f`) |

To turn it on or off permanently for one project, put a `.nvim.lua` in the
project root:

```lua
vim.g.autoformat = true   -- or false
```

The first time Neovim finds that file it asks whether to trust it (`a` to
allow); it asks again whenever the file changes.

Formatters: nixfmt for Nix, stylua for Lua, shfmt for shell, rumdl for
Markdown. For JavaScript, TypeScript, Vue, CSS, HTML and JSON: biome where
the project has a `biome.json`, else prettier (prettierd) where it configures
prettier, else the language server. YAML, SCSS and Less: prettier where
configured, else the language server.

## Markdown

Headings, lists, tables, code blocks and links are drawn formatted while you
read; the line under the cursor and insert mode show the plain text. Images
appear inline (Ghostty draws them). `Space u m` switches the rendering off.

| Keys | Does |
|---|---|
| `gd` on a link | Follow it to the file or heading |
| `Space s s` | Headings of this file |
| `Space c p` | Open the file in Typora (for Mermaid diagrams and a print view) |

rumdl checks Markdown style; the line-length rule is off unless a project's
own rumdl or markdownlint configuration turns it on. Mermaid diagrams, LaTeX
math and PDFs are not rendered in Neovim.

## Python

ty (types, navigation, hover) and ruff (lint, quick fixes, import sorting,
formatting) start with any `.py` file and use the project's uv `.venv`
by themselves. Open Neovim from the project directory.

The project provides the rest, as dev dependencies:

```bash
uv add --dev pytest          # tests
uv add --dev debugpy         # optional: the debugger adds it for the session if missing
```

Keep the project's configuration, including ruff's, in `pyproject.toml`
(example in [projects.md](projects.md#python)). A `[tool.ruff]` section
there turns format on save on for the project. `Space c f` runs ruff's import
sorting and formatter.

## Java and Spring

jdtls (the Eclipse Java language server) starts with any `.java` file in a
Maven or Gradle project. The project's own JDK comes from its dev shell
(`JAVA_HOME`, [projects.md](projects.md#java--spring)), so open Neovim from
the project directory. The first start imports the project, which takes a
while for a large one; the progress shows at the bottom right.

Everything from [Code intelligence](#code-intelligence) works, plus:

| Keys | Does |
|---|---|
| `gd` on a library class | Opens its source, or decompiled code where there is none |
| `gai` / `gao` | Call hierarchy (who calls this / what this calls) |
| `Space c o` | Organise imports |
| `Space c x v` | Extract variable (all occurrences; works on a selection) |
| `Space c x c` | Extract constant |
| `Space c x m` (visual) | Extract method |
| `Space c s` | Go to the method this one overrides |
| `Space c a` | Code actions: generate getters, constructors, `toString`, implement methods, … |

Lombok works out of the box: generated getters, setters and builders are
known to completion and navigation.

**Tests** run through jdtls (JUnit 4, 5 and 6), not neotest:

| Keys | Does |
|---|---|
| `Space t r` | Run the test method under the cursor |
| `Space t t` | Run the whole test class |
| `Space t d` / `t D` | Debug the method / the class (stops at breakpoints) |
| `Space t p` | Pick a test from the file |

Failures land in the quickfix list (`Space x q`), one line per failed test.

**Debugging an application**: set a breakpoint, `Space d c`, and pick the
main class; jdtls finds them. The rest of [Debugging](#debugging-space-d-and-the-f-keys)
applies, including the IntelliJ F-keys.

**Spring Boot**: in `application.properties` and `application.yml`, property
names complete and are validated, `K` documents them, and `gd` on
`@Value("${…}")` jumps to the property. In Java code, beans and request
mappings are recognised (`Space s s` lists them among the symbols).

## Web: TypeScript, JavaScript, Vue, HTML, CSS, Docker

Open Neovim from the project directory, inside its dev shell
([projects.md](projects.md#javascript--typescript--vue--react)), so the
project's Node and `node_modules` are found.

| Server | Starts for | Notes |
|---|---|---|
| vtsls | `.ts`, `.tsx`, `.js`, `.jsx`, `.vue` | Uses the project's `node_modules/typescript`, else its own |
| vue_ls | `.vue` | Templates and styles; script blocks go through vtsls |
| eslint | JS, TS, Vue | Only with an eslint config file; the eslint version is the project's |
| biome | JS, TS, JSON, CSS, HTML, Vue | Only with a `biome.json` |
| tailwindcss | HTML, CSS, JS/TS, Vue, Markdown, … | Only where `package.json` lists `tailwindcss` or there is a `tailwind.config.*` |
| html, cssls | `.html`, `.css`/`.scss`/`.less` | |
| emmet | HTML, CSS, JSX/TSX, Vue | Abbreviations such as `ul>li*3` appear in completion |
| docker-language-server | `Dockerfile`, `compose.yaml`, `docker-compose.yml`, Bake files | yamlls still validates Compose files against their schema |

Everything from [Code intelligence](#code-intelligence) works. `Space c A`
offers source actions: organise, sort or remove unused imports, add missing
imports, fix all fixable TypeScript issues, and "Fix all fixable ESLint
issues" (`:LspEslintFixAll` does that directly). Type hints for parameters
and return types show with `Space u h`. Renaming a file with `Space c R` does
**not** update imports here: vtsls does not offer it to Neovim.

There is no JavaScript test runner or debugger in the editor yet.

## Go

gopls starts with any `.go` file. The Go toolchain comes from the project's
dev shell ([projects.md](projects.md#go)), so open Neovim from the project
directory. Saving formats with plain gofmt (not gofumpt), because `go.mod`
counts as the project asking for it. `Space c A` offers "Organize Imports".

golangci-lint's findings appear only where the project has a
`.golangci.yml` (or `.yaml`, `.toml`, `.json`) and golangci-lint in its dev
shell.

Tests use the keys in [Tests](#tests-space-t); `Space t d` debugs one with
delve. `Space d c` offers to debug the package, the file or a test.

## Rust

rustaceanvim starts rust-analyzer with any `.rs` file in a Cargo project.
rust-analyzer, rustfmt, clippy and cargo come from the project's dev shell
([projects.md](projects.md#rust)) so they match its compiler; open Neovim
from the project directory. Saving formats with rustfmt (`Cargo.toml` counts
as the project asking for it), and clippy's warnings appear after each save.

| Keys | Does |
|---|---|
| `Space c a` | Code actions, including rust-analyzer's assists |
| `:RustLsp expandMacro` | Show what the macro under the cursor expands to |
| `:RustLsp explainError` | Explain the error under the cursor |
| `:RustLsp runnables` / `debuggables` | Pick something to run or debug |

In `Cargo.toml`, crates.nvim shows each dependency's latest version and
completes crate names, versions and features; it asks crates.io, so it needs
the network.

Tests use the keys in [Tests](#tests-space-t) (cargo test, or cargo-nextest
when installed); `Space t d` debugs one.

## C and C++

clangd starts with C and C++ files. It needs the project's build flags in a
`compile_commands.json` at the project root (CMake:
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`; Make: run the build under `bear`);
without one it guesses. It asks Apple's clang for the SDK headers.

| Keys | Does |
|---|---|
| `Space c h` | Switch between the source file and its header |

Formatting uses the project's `.clang-format`, which also turns format on
save on. clang-tidy's checks appear where the project has a `.clang-tidy`.

To debug, build with `-g`, set a breakpoint and `Space d c`: "Launch" asks for
the program and its arguments, "Attach to process" picks a running one.

## Ruby

ruby-lsp starts with `.rb` and `.erb` files. It and rubocop (or standard)
come from the project's `Gemfile` ([projects.md](projects.md#ruby-rails-sinatra-padrino)),
so they run under the project's Ruby; open Neovim from the project
directory. rubocop's offences appear as diagnostics, and a `.rubocop.yml` or
`.standard.yml` turns format on save on. In a large project, hover and `gd`
work once indexing has finished (the progress shows at the bottom right).

## PHP

phpactor starts with `.php` files in a project with `composer.json` or Git.
It works without `vendor/`, but then reports every framework class as
missing: run `composer install` first. Formatting uses the project's
`vendor/bin/pint` if installed, else `vendor/bin/php-cs-fixer`; `pint.json`
or a `.php-cs-fixer.php` turns format on save on.

## Elixir and Phoenix

Expert starts with `.ex`, `.exs` and `.heex` files. The first start in a
project builds its engine, which takes a while. Formatting is `mix format`
following the project's `.formatter.exs`, which also turns format on save
on.

Expert looks for the project's Erlang through a fresh login shell, not
through Neovim's environment, and otherwise falls back to the Elixir bundled
with it. If a project pins a different Elixir, that difference can matter.

## Terraform

terraform-ls starts with `.tf` and `.tfvars` files. The terraform CLI comes
from the project's dev shell ([projects.md](projects.md#terraform)), and
saving formats with `terraform fmt`, on by default for Terraform files.
tflint's findings appear where the project has a `.tflint.hcl` and tflint in
its dev shell.

## SQL and databases

In a project with a `postgres-language-server.jsonc`, the Postgres language
server checks SQL syntax (and, with a reachable database, names). A
`.sql-formatter.json` sets sql-formatter's style and turns format on save on;
`Space c f` formats with sql-formatter's defaults anywhere.

`Space D` opens the database browser (vim-dadbod-ui). Add a connection with
`A` in it, as a URL such as `postgresql://user@localhost/db` or
`sqlite:path/to.db`; saved connections live in Neovim's data directory
(`~/.local/share/nvim/db_ui`), never in a repository. A URL with a password
in it is stored in plain text there, so prefer `~/.pgpass` or an environment
variable. In a query buffer, table and column names complete from the
connection. `:DB <url> <query>` runs one query directly.

## Tests: `Space t`

neotest finds tests in the file and project and shows the result of each as a
sign beside it, with failures as diagnostics on the failing line.

| Keys | Does |
|---|---|
| `Space t r` | Run the test under the cursor |
| `Space t t` | Run every test in this file |
| `Space t T` | Run the whole project's tests |
| `Space t l` | Run the last run again |
| `Space t d` | Debug the test under the cursor (stops at breakpoints) |
| `Space t o` | Output of the test under the cursor |
| `Space t O` | Output panel for all runs |
| `Space t s` | Summary tree: every test and its state; inside, `r` runs, `d` debugs, `o` shows output, `i` jumps to the test, `Enter` expands |
| `Space t w` | Re-run this file's tests on every save |
| `Space t S` | Stop the run |

Python tests run with pytest from the project's `.venv`, Go tests with
`go test`, Rust tests with cargo. Java tests use the same keys but run through
jdtls ([Java and Spring](#java-and-spring)).

## Debugging: `Space d` and the F-keys

Set a breakpoint, then start. The debug panel opens at the bottom when a
session starts (variables, watches, call stack, breakpoints, threads, REPL,
console; switch with the letters shown in its bar) and closes when it ends.

| Keys | IntelliJ key | Does |
|---|---|---|
| `Space d b` | `Ctrl-F8` | Toggle breakpoint |
| `Space d B` | | Conditional breakpoint (asks for the condition) |
| `Space d L` | | Log point: prints a message instead of stopping |
| `Space d c` | `F9` | Start, or continue to the next breakpoint |
| `Space d C` | `Alt-F9` | Run to the cursor |
| `Space d O` | `F8` | Step over |
| `Space d i` | `F7` | Step into |
| `Space d o` | `Shift-F8` | Step out |
| `Space d P` | | Pause |
| `Space d t` | `Ctrl-F2` | Stop |
| `Space d l` | | Run the last configuration again |
| `Space d e` | | Value of the expression under the cursor or selected |
| `Space d w` | | Add the expression under the cursor to the watches |
| `Space d u` | | Show or hide the debug panel |

For Python, `Space d c` offers to run the current file, and `Space t d`
debugs a single test. The debugger runs as
`uv run --with debugpy python -m debugpy.adapter` in the project, so it uses
the project's interpreter and packages; the first run needs the network if
debugpy is not yet in uv's cache.

Go debugs with delve. C, C++ and Rust debug with Apple's `lldb-dap` from the
Command Line Tools; a Rust program's output appears in the panel's console.

## Claude Code in the editor

Claude Code runs in its own Ghostty split, not inside Neovim. With Neovim
open in the project, type `/ide` in Claude Code and pick Neovim. From then on
Claude sees the file you are in and what you have selected, and proposed
edits open here as a diff to accept or reject.

| Keys | Does |
|---|---|
| `Space a s` (visual) | Send the selection to Claude |
| `Space a b` | Add this file to Claude's context |
| `Space a a` | Accept Claude's proposed change (in the diff) |
| `Space a d` | Reject it |
| `Space a S` | Connection status |

## Spelling

English and Serbian Latin are checked together. Markdown, plain text and Git
commit messages start with spelling and soft wrap on; elsewhere use `Space u s`.

| Keys | Does |
|---|---|
| `]s` / `[s` | Next / previous misspelled word |
| `z=` | Suggestions |
| `zg` | Add the word to your list |
| `zw` | Mark the word as wrong |
| `zug` / `zuw` | Undo `zg` / `zw` |

Added words go to `~/.local/share/nvim/spell/en.utf-8.add`. That file is per
machine and outside the repository.

## Behaviour worth knowing

- Yank and paste use the macOS clipboard directly.
- Files changed outside Neovim (by Git, lazygit or Claude Code) reload when
  the Neovim window regains focus. With unsaved changes, Neovim asks first.
- There are no swap or backup files. Undo history is kept across sessions.
- Files larger than 1.5 MB open without syntax highlighting, to stay fast.
- Reopening a file returns to where you left it.
- Indentation defaults to four spaces; a project's `.editorconfig` overrides it.
- The colours are Monokai Pro "Sun", set to match Ghostty's
  "Monokai Pro Light Sun". Both are light themes.

## When something looks wrong

### Health checks

```vim
:checkhealth snacks which-key vim.provider
```

Expected, and not faults:

- The python3, Ruby, Node and Perl providers show as disabled: no plugin needs
  them, and they would need a global Python, Ruby, Node or Perl.
- `Snacks.image` errors about `gs`, `tectonic` and `mmdc`: PDF, LaTeX and
  Mermaid rendering are deliberately not installed. ImageMagick is.
- conform reports `prettierd unavailable: Condition failed` outside projects
  that configure prettier. That is the intended condition.
- Headless runs also report the dashboard setup and `vim.ui.select` as not
  done. Both hook into UIEnter; they are fine in a real terminal.

### Language servers

```vim
:checkhealth vim.lsp     " servers configured, attached, their root and log path
:lsp restart             " restart the servers of this buffer
```

`Space c l` lists the servers for the current buffer. The log is
`~/.local/state/nvim/lsp.log`; `:lua vim.lsp.log.set_level("debug")` makes it
verbose for the session.

A server that does not attach: check `:set filetype?`, then whether its root
markers exist (shown in `:checkhealth vim.lsp`). Servers that come from the
project rather than the editor (named in the language sections above) only
exist when Neovim was started inside that directory, after direnv loaded it.

nixd evaluates this flake for option completion. If option docs stop
appearing after a change, `:lsp restart`; a broken evaluation shows in the
LSP log.

### Formatting, tests, debugging

```vim
:ConformInfo             " formatters for this buffer, whether each is available, the log
:lua print(_G.workstation_autoformat(0))   " would saving format this buffer?
:checkhealth dap
:DapShowLog              " nvim-dap's log (adapter start-up, protocol errors)
```

A project's `.nvim.lua` is only read after `:trust`; `:trust ++remove`
revokes it. Python's debug adapter writes its stderr to
`~/.local/state/nvim/dap-python-stderr.log`; a session that never starts is
usually uv failing to resolve the project (read that log) or a project without
a `.venv` yet (`uv sync`). neotest has no health check: if every test shows as
skipped, run `:lua require("neotest.logging"):set_level(vim.log.levels.DEBUG)`,
run again, then read `~/.local/state/nvim/neotest.log`.

### Java

```vim
:JdtShowLogs             " jdtls' own log
:JdtWipeDataAndRestart   " forget the project import and start over
:JdtUpdateConfig         " re-read pom.xml / build.gradle after editing it
:JdtUpdateDebugConfig    " re-scan main classes for Space d c
```

jdtls keeps one workspace per project under `~/.cache/nvim/jdtls/workspace/`;
its OSGi log is `.metadata/.log` in there, where a debug or test extension that
does not load shows as `Could not resolve module`. The Spring Boot server logs
to `~/.local/state/nvim/spring-boot-ls.log`. The project's JDK is read from
`JAVA_HOME` when jdtls starts; if the project shell was not loaded then,
`:JdtSetRuntime` switches it afterwards.

### Claude Code connection

`:ClaudeCodeStatus` shows whether the server runs and a client is connected.
The server writes `~/.claude/ide/<port>.lock` while Neovim runs; `/ide` in
Claude Code lists the Neovim instances it finds there.

### Treesitter

```vim
:checkhealth vim.treesitter
:InspectTree            " the syntax tree of the current buffer
:Inspect                " highlight groups and captures under the cursor
```

Every grammar comes from Nix; `:TSInstall` is never needed. If a file type has
no highlighting, check `:set filetype?` first, then whether
`vim.treesitter.language.get_lang(vim.bo.filetype)` names a parser.

## How the editor is built

### Building without activating

The editor alone, much faster than a full system build:

```bash
host=$(cat /etc/workstation-host)
nix build --no-link --print-out-paths \
  ".#darwinConfigurations.$host.config.home-manager.users.$USER.programs.nixvim.build.package"
nix build --no-link --print-out-paths \
  ".#darwinConfigurations.$host.config.home-manager.users.$USER.programs.nixvim.build.initFile"
```

The built `nvim` runs against that `init.lua` without touching `~/.config`:
`<package>/bin/nvim -u <initFile> somefile`. To leave your real undo history,
shada and spell list alone while testing, point `XDG_DATA_HOME`,
`XDG_STATE_HOME` and `XDG_CACHE_HOME` at a scratch directory. After
activation, `nixvim-print-init` prints the active `init.lua`.

### One plugin directory

`performance.combinePlugins` merges all plugins into one directory, and a
build fails if two plugins ship the same file. The fix is to list one of them
in `performance.combinePlugins.standalonePlugins` next to its config. Plugins
that read files outside the standard runtime directories must be standalone
too, or they break quietly (neotest-python runs `neotest.py` from its plugin
root). The current list: snacks, blink.cmp, friendly-snippets, neotest-python,
nvim-jdtls.

### Lazy loading

Some plugins load on first use instead of at startup (`nixvim/lazy.nix`,
lz.n):

| Plugin | Loads |
|---|---|
| nvim-dap, nvim-dap-view | First `Space d` key or F-key, a `:Dap…` command, a Java file (jdtls) or a Rust file (rust-analyzer attaching) |
| neotest | First `Space t` key, `:Neotest`, or a Rust file (rust-analyzer attaching) |
| claudecode | Straight after the first screen is drawn |
| bufferline | Straight after the first screen is drawn |
| render-markdown | First Markdown file |
| crates.nvim | First `Cargo.toml` opened |

Everything else loads at startup, on purpose: blink.cmp (servers need its
capabilities before they start), schemastore (read while server configs are
built), nvim-jdtls and spring-boot (must be in place before a Java file's
`FileType` and attach events), and the rest cost too little to matter.

Code that uses a lazy plugin loads it with
`require("lz.n").trigger_load("<plugin directory name>")` first: Neovim can
`require` a Lua module from a not-yet-loaded plugin and would then skip its
setup. `:lua require("lz.n").trigger_load("nvim-dap")` loads one by hand.

### Startup time

```bash
for i in 1 2 3 4 5; do nvim --headless --startuptime /tmp/nvim-st.$i +qa; tail -1 /tmp/nvim-st.$i; done
```

The last line of each log is the total in milliseconds. When a start passes
about 100 ms, look for plugins that could load lazily. Opening the first file
of a type also adds one-time work that lazy loading cannot defer: its
Treesitter grammar, spell files and language servers.

`which -a nvim` shows only the Nix copy
(`/etc/profiles/per-user/$USER/bin/nvim`). A broken build is undone with
`ws rollback`.
