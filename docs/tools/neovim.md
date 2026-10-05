# Neovim

NixVim builds Neovim from the `nixvim/` directory of this repository. The
editor has no plugin manager, and it downloads no plugins while it runs. All
plugins come from Nix.

To change the editor, edit the files in `nixvim/`. Then run `ws build` and
`ws switch`. A change to `~/.config/nvim/init.lua` does not last, because that
file is a link into the Nix store.

The leader key is `Space`. Press `Space` and wait. which-key then shows the
keys that can follow. which-key does the same after `g`, `z`, `[`, `]` and
`Ctrl-w`.

In this guide, `Space f f` means: press `Space`, then `f`, then `f`.

## Daily keys

| Keys | Action |
|---|---|
| `Ctrl-S` | Save, in all modes |
| `Esc` | Also removes the search highlight |
| `Space Space` | Find a file |
| `Space /` | Search for text in the project (grep) |
| `Space ,` | Go to a different buffer |
| `Space e` | Open the file explorer. `nvim .` also opens it |
| `Shift-H` / `Shift-L` | Go to the previous / next buffer |
| `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` | Go to the window on the left / below / above / on the right |
| `Space -` / `Space \|` | Split the window below / to the right |
| `Space q q` | Quit Neovim. It asks about files that are not saved |

`j` and `k` move by screen line in wrapped text. With a count, for example
`5j`, they move by real line. Thus relative line numbers continue to work.

### Example: open a project and find a setting

1. Start Neovim in the repository:

   ```bash
   cd ~/github/workstation
   nvim .
   ```

2. Press `Space Space`, type `shell`, and press `Enter`. Neovim opens
   `modules/home/shell.nix`.
3. Press `Space /` and type `stateVersion`. The picker shows each line that
   contains the text.
4. Press `Ctrl-v` on a match to open it in a vertical split.
5. Press `Ctrl-h` and `Ctrl-l` to move between the two windows.
6. Press `Space q q` to quit.

## Find things: `Space f` and `Space s`

All pickers work in the same way:

| Keys in a picker | Action |
|---|---|
| Text | Filter the list |
| `Ctrl-j` / `Ctrl-k`, or the arrow keys | Move in the list |
| `Enter` | Open the item |
| `Ctrl-v` / `Ctrl-s` | Open the item in a vertical / horizontal split |
| `Esc` | Close the picker |

`Space s R` opens the last picker again, in the state that it had when you
closed it.

| Keys | Picker |
|---|---|
| `Space f f` | Files. It obeys `.gitignore` |
| `Space f F` | Files, with hidden files and ignored files |
| `Space f r` | Recent files |
| `Space f b` | Buffers |
| `Space f c` | The `nixvim/` configuration of this repository |
| `Space f n` | A new empty file |
| `Space s g` | Grep |
| `Space s w` | Grep for the word at the cursor, or for the selection |
| `Space s b` | Lines in the current buffer |
| `Space s h` / `s k` / `s C` | Help pages / keymaps / commands |
| `Space s u` | Undo history. The history stays after you close the file |
| `Space s m` / `s j` / `s "` | Marks / jumps / registers |
| `Space s M` | Man pages |
| `Space s q` / `s l` | Quickfix list / location list |
| `Space :` | Command history |

### Examples

Find all uses of a word:

1. Put the cursor on the word.
2. Press `Space s w`.
3. Type more text to make the list smaller, then press `Enter` on a line.

Find the key for an action:

1. Press `Space s k`.
2. Type a word from the action, for example `rename`.
3. Read the key in the list.

Go back to an old state of a file:

1. Press `Space s u`.
2. Move in the list. The preview shows the difference for each state.
3. Press `Enter` to restore that state.

## Buffers, windows and tabs

| Keys | Action |
|---|---|
| `Space b b` | Go to the previous buffer (the `#` file) |
| `Space b d` | Close the buffer and keep the window |
| `Space b o` | Close all other buffers |
| `Space w` | Show all `Ctrl-w` window commands in which-key |
| `Space w d` | Close the window |
| `Space w m` | Make the window as large as possible, or restore it |
| `Ctrl` + arrow keys | Change the size of the window |
| `Space Tab Tab` | Open a new tab |
| `Space Tab ]` / `[` | Go to the next / previous tab |
| `Space Tab d` / `o` | Close the tab / all other tabs |
| `Space x q` / `x l` | Open or close the quickfix list / the location list |

In a help window, a quickfix window or a `:checkhealth` window, `q` closes the
window.

The buffer bar at the top shows when more than one buffer is open.

## Toggles: `Space u`

Most toggles show a message with their new state, and which-key shows their
current state.

| Keys | Toggle |
|---|---|
| `Space u s` | Spell check |
| `Space u w` | Soft wrap |
| `Space u l` / `u L` | Line numbers / relative line numbers |
| `Space u z` | Zen mode: one window of 120 columns in the centre |
| `Space u Z` | Zoom of the current window |
| `Space u n` | Hide the notifications. `Space n` shows their history |
| `Space u C` | Use a different colour scheme for this session |
| `Space u t` | The function or class context at the top of the window |
| `Space u p` | Automatic pairs of brackets and quotes |
| `Space u G` | Git signs |
| `Space u d` | Diagnostics |
| `Space u h` | Inlay hints |
| `Space u f` / `u F` | Format on save, for all buffers / for this buffer |
| `Space u m` | Rendered Markdown |

## Text objects and motions

An operator (`d`, `c`, `y`, `v`) works together with a text object. `a` selects
the full object, and `i` selects its contents.

If the cursor is not in an object of that type, the editor uses the next one.
A count selects an object that is farther out.

| Keys | Result |
|---|---|
| `daf` | Deletes the function |
| `ci"` | Changes the text between the quotes |
| `vic` | Selects the body of the class |
| `yia` | Copies the argument at the cursor |
| `dab` | Deletes the brackets and their contents |
| `cit` | Changes the contents of the HTML tag |
| `yig` | Copies the file, without the blank lines at its start and its end |
| `dih` | Deletes the Git hunk |
| `2dib` | Deletes the contents of the second pair of brackets around the cursor |

These are the objects:

| Object | Meaning |
|---|---|
| `f` | Function, from the syntax tree |
| `c` | Class |
| `o` | Block, conditional or loop |
| `u` / `U` | Function call. `U` also matches `obj.method(...)` |
| `a` | Argument |
| `b` | A bracket of each type: `()`, `[]`, `{}` |
| `q` | A quote of each type |
| `t` | HTML or XML tag |
| `d` | Number |
| `g` | The full file. `ig` omits the blank lines at the two ends |
| `h` | Git hunk (`dih`, `vih`) |

The built-in objects, for example `iw`, `ip`, `i(` and `it`, continue to work.

| Keys | Destination |
|---|---|
| `]f` / `[f` | The start of the next / previous function. `]F` / `[F` go to the end |
| `]c` / `[c` | The start of the next / previous class. `]C` / `[C` go to the end. In diff mode: the next / previous change |
| `]h` / `[h` | The next / previous Git hunk. `]H` / `[H` go to the last / first hunk |

While you scroll, the function or class around the cursor stays at the top of
the window. `Space u t` toggles this context.

Folds use the syntax tree, and all folds are open when you open a file. `za`
toggles one fold, `zM` closes all folds, and `zR` opens all folds.

## Surround and pairs

The surround keys start with `gs`. Thus the built-in `s` key continues to
work.

The last key is the surrounding character: `)`, `]`, `}`, `"`, `'` or `` ` ``.
Two letters have a special meaning. `t` is a tag and `f` is a function call,
and for these two the editor asks for the name.

| Keys | Action |
|---|---|
| `gsa{motion}{char}` | Add a surrounding. In visual mode, use `gsa{char}` |
| `gsd{char}` | Delete a surrounding |
| `gsr{old}{new}` | Replace a surrounding |
| `gsf` / `gsF` | Find the next / previous surrounding |
| `gsh` | Highlight the surrounding for a short time |

Examples:

| Text before | Keys | Text after |
|---|---|---|
| `hello` | `gsaiw"` | `"hello"` |
| `(a + b)` | `gsd)` | `a + b` |
| `"name"` | `gsr"'` | `'name'` |
| `value` | `gsaiwf`, then `str` and `Enter` | `str(value)` |
| `title` | `gsaiwt`, then `h1` and `Enter` | `<h1>title</h1>` |

When you type an opening bracket or quote, the editor adds the closing one.
`Space u p` stops this.

## Git

The sign column shows the changed lines. A bar shows a line that you added or
changed. A low line shows the position of deleted lines. Staged changes have
the same signs in a paler colour.

| Keys | Action |
|---|---|
| `Space g g` | Open lazygit in a floating window. `e` on a file opens it in this Neovim, and `q` goes back |
| `Space g s` | Changed files (picker) |
| `Space g d` | Changed hunks in the project (picker) |
| `Space g l` / `g f` | The log / the history of this file |
| `Space g b` | The commits that changed the current line |
| `Space g B` | Open the file, or the selected lines, on GitHub |
| `Space g Y` | Copy that link |
| `Space g h s` | Stage the hunk, or the selected lines. On a staged hunk, it unstages the hunk |
| `Space g h r` | Reset the hunk to the index |
| `Space g h S` / `h R` | Stage / reset the full file |
| `Space g h p` | Show the hunk in the buffer |
| `Space g h b` | Show the blame for the line, with the full commit message |
| `Space g h B` | Show the blame for the full file in a side window |
| `Space g h d` / `h D` | Diff against the index / against the last commit |
| `Space u G` | Toggle the Git signs |

Caution: `Space g h r` and `Space g h R` discard your changes.

Use lazygit and `ec` to read a large diff and to solve conflicts. See
[git.md](git.md).

### Example: commit one hunk of a file

1. Press `]h` to go to the next hunk.
2. Press `Space g h p` to see the old lines and the new lines.
3. Press `Space g h s` to stage the hunk.
4. Press `Space g g` to open lazygit.
5. Press `c`, type the commit message, and press `Enter`.
6. Press `q` to go back to Neovim.

## Terminal

`Ctrl-/` opens a terminal at the bottom of the window. The same key hides it.
The key works in normal mode and in terminal mode. The shell continues to run
while the terminal is hidden. `Space f t` does the same.

In the terminal, press `Esc Esc` to go to normal mode. There you can scroll
and copy text. Press `i` to go back.

Example: run a long command and continue to edit.

1. Press `Ctrl-/` and run `uv run pytest`.
2. Press `Ctrl-/` to hide the terminal, and continue to edit.
3. Press `Ctrl-/` again to read the result.

## Sessions

When Neovim exits, it saves the open files and the windows for the current
directory. To restore them, press `s` on the dashboard or `Space q s`.

| Keys | Action |
|---|---|
| `Space q s` | Restore the session of this directory |
| `Space q l` | Restore the last session, from any directory |
| `Space q S` | Select a session |
| `Space q d` | Do not save the session when you quit this time |

Example: continue the work of the previous day.

```bash
cd ~/github/myapp
nvim
```

The dashboard opens. Press `s`, and Neovim opens the same files in the same
windows.

## Code intelligence

A language server starts automatically when you open a file of its language.

The editor contains the servers for these languages, and they work in each
directory: Nix, Lua, shell (sh and bash, with shellcheck), Markdown, JSON, YAML
and TOML. The Nix server is nixd, and it knows the nix-darwin options and the
Home Manager options of this repository.

Python, Java, web, Go, Rust, C/C++, Ruby, PHP, Elixir, Terraform and SQL have
their own sections below. For some of them, the dev shell of the project is
necessary.

`Space c l` shows the servers that run for the current file.

| Keys | Action |
|---|---|
| `K` | Show the documentation of the symbol. Press `K` again to go into the window |
| `gd` | Go to the definition. `Ctrl-o` goes back |
| `gD` | Go to the declaration |
| `grr` | Show the references |
| `gri` / `grt` | Go to the implementation / the type definition |
| `gai` / `gao` | Show the incoming / outgoing calls |
| `gK` | Show the signature help. The editor also shows it while you type arguments |
| `]]` / `[[` | Go to the next / previous use of the symbol at the cursor |
| `grn` or `Space c r` | Rename the symbol in all files |
| `gra` or `Space c a` | Code action (quick fix) |
| `Space c A` | Source action, for example organise imports |
| `Space c R` | Rename the file. Where the server supports it, the server updates the imports |
| `Space s s` / `s S` | Symbols in this file / in the project |
| `gO` | Outline of this file |

After a short time, the editor highlights the other uses of the symbol at the
cursor.

### Example: read about a function and go to its source

1. Put the cursor on the name of the function.
2. Press `K` to read its documentation.
3. Press `gd` to go to its definition.
4. Press `Ctrl-o` to go back.

### Example: rename a function in all files

1. Put the cursor on the name of the function.
2. Press `grr` to see all references in the quickfix list. Press `q` in that
   list to close it.
3. Press `grn`, type the new name, and press `Enter`.
4. Run `:wa` to save all changed files.

## Diagnostics

Errors and warnings show at the end of the line and as icons in the sign
column.

| Keys | Action |
|---|---|
| `Space c d` | Show the full message for the current line |
| `]d` / `[d` | Go to the next / previous diagnostic |
| `]e` / `[e` | Go to the next / previous error |
| `]w` / `[w` | Go to the next / previous warning |
| `Space s d` / `s D` | Diagnostics in this file / in the project (picker) |
| `Space x x` | Diagnostics (picker) |
| `Space u d` | Hide or show the diagnostics |
| `Space u h` | Inlay hints: types and parameter names in the line, where the server supports them |

Example: correct the next error.

1. Press `]e` to go to the next error.
2. Press `Space c d` to read the full message.
3. Press `Space c a` and select a correction, if the server offers one.

## Completion

The menu opens while you type, and the first item is selected.

| Keys | Action |
|---|---|
| `Enter` | Accept the selected item |
| `Tab` / `Shift-Tab`, `Ctrl-n` / `Ctrl-p`, or the arrow keys | Go to the next / previous item |
| `Ctrl-Space` | Open the menu, or show and hide the documentation next to it |
| `Ctrl-e` | Close the menu |
| `Ctrl-b` / `Ctrl-f` | Scroll the documentation |
| `Tab` / `Shift-Tab` in a snippet | Go to the next / previous placeholder |

The items come from four sources: the language server, file paths, snippets,
and the words in the open buffers. To get file paths, type `./` or `~/`.

## Formatting

`Space c f` formats the file or the selection. It works at all times.

### Format on save

Format on save is off unless the project asks for it. Thus a save of an old
file does not change code that you did not edit.

Format on save becomes on automatically in a project that has a configuration
file for a formatter:

| Formatter | File in the project |
|---|---|
| stylua | `stylua.toml` |
| prettier | A prettier configuration file |
| biome | `biome.json` or `.biome.json` |
| ruff | `ruff.toml`, or a `[tool.ruff]` section in `pyproject.toml` |
| rustfmt | `rustfmt.toml` |
| clang-format | `.clang-format` |
| treefmt | `treefmt.toml` |
| rumdl | `rumdl.toml`, or a `[tool.rumdl]` section in `pyproject.toml` |
| tombi | `tombi.toml` |
| rubocop, standard | `.rubocop.yml`, `.standard.yml` |
| pint, php-cs-fixer | `pint.json`, `.php-cs-fixer.php` |
| mix format | `.formatter.exs` |
| sql-formatter | `.sql-formatter.json` |

Three languages have their own rule:

- Go files format on save in a project with a `go.mod`.
- Rust files format on save in a project with a `Cargo.toml`.
- Terraform files always format on save.

In a Go project or a Rust project, the other files stay as they are.

You can change the setting with two toggles:

| Keys | Action |
|---|---|
| `Space u f` | Format on save for all buffers, for this session |
| `Space u F` | Format on save for this buffer only. It has priority over `Space u f` |

To set format on save permanently for one project, put a `.nvim.lua` file in
the project root:

```lua
vim.g.autoformat = true   -- or false
```

The first time that Neovim finds that file, it asks if you trust it. Press `a`
to allow it. Neovim asks again after each change to the file.

The editor uses the first of these settings that exists:

1. The setting of the buffer (`Space u F`)
2. The global setting (`Space u f`, or a trusted `.nvim.lua`)
3. The configuration files of the project

To see the result for the current buffer, run this command. It prints `true`
or `false`:

```vim
:lua print(_G.workstation_autoformat(0))
```

### The formatter for each language

| Language | Formatter |
|---|---|
| Nix | nixfmt |
| Lua | stylua |
| Shell | shfmt |
| Markdown | rumdl |
| JavaScript, TypeScript, Vue, CSS, HTML, JSON | biome if the project has a `biome.json`. If not, prettier (prettierd) if the project configures prettier. If not, the language server |
| YAML, SCSS, Less | prettier if the project configures it. If not, the language server |

## Markdown

The editor shows headings, lists, tables, code blocks and links with their
format while you read. The line at the cursor shows the plain text, and insert
mode shows the plain text for all lines.

Images show in the buffer, because Ghostty can draw them. `Space u m` stops
the rendering.

| Keys | Action |
|---|---|
| `gd` on a link | Go to the file or the heading |
| `Space s s` | Show the headings of this file |
| `Space c p` | Open the file in Typora, for Mermaid diagrams and a print view |

rumdl examines the Markdown style. Its line-length rule is off, unless the
rumdl or markdownlint configuration of a project sets it to on.

Neovim does not render Mermaid diagrams, LaTeX formulas or PDF files.

## Python

Two servers start with each `.py` file. ty gives types, navigation and hover
text. ruff gives lint results, quick fixes, import sort and formatting. The
two servers find the uv `.venv` of the project automatically.

Open Neovim from the project directory.

The project supplies the other tools as development dependencies:

```bash
uv add --dev pytest          # tests
uv add --dev debugpy         # optional: the debugger adds it for the session if it is not there
```

Keep the configuration of the project, with the ruff settings, in
`pyproject.toml`. [projects.md](projects.md#python) has an example. A
`[tool.ruff]` section in that file sets format on save to on for the project.

`Space c f` runs the import sort and the formatter of ruff.

### Example: debug one test

1. Open the test file and put the cursor on a line in the test.
2. Press `Space d b` to set a breakpoint.
3. Press `Space t d`. The test starts and stops at the breakpoint.
4. Press `Space d O` to step over a line, or `Space d i` to step into a call.
5. Put the cursor on a variable and press `Space d e` to see its value.
6. Press `Space d c` to continue, or `Space d t` to stop.

## Java and Spring

jdtls is the Eclipse Java language server. It starts with each `.java` file in
a Maven project or a Gradle project.

The JDK of the project comes from its dev shell, through `JAVA_HOME`. See
[projects.md](projects.md#java--spring). Thus you must open Neovim from the
project directory.

The first start imports the project. For a large project this takes some time,
and the progress shows at the bottom right.

All keys from [Code intelligence](#code-intelligence) work. Java adds these
keys:

| Keys | Action |
|---|---|
| `gd` on a library class | Open its source. If there is no source, open the decompiled code |
| `gai` / `gao` | Call hierarchy: the callers of this method / the calls of this method |
| `Space c o` | Organise imports |
| `Space c x v` | Extract a variable, for all occurrences. It also works on a selection |
| `Space c x c` | Extract a constant |
| `Space c x m` (visual mode) | Extract a method |
| `Space c s` | Go to the method that this method overrides |
| `Space c a` | Code actions: generate getters, constructors and `toString`, implement methods, and others |

Lombok works with no configuration. Completion and navigation know the
generated getters, setters and builders.

### Tests

Java tests run through jdtls (JUnit 4, 5 and 6), not through neotest.

| Keys | Action |
|---|---|
| `Space t r` | Run the test method at the cursor |
| `Space t t` | Run the full test class |
| `Space t d` / `t D` | Debug the method / the class. The run stops at breakpoints |
| `Space t p` | Select a test from the file |

Failed tests go to the quickfix list, with one line for each failed test. Open
the list with `Space x q`.

### Debug an application

1. Set a breakpoint with `Space d b`.
2. Press `Space d c`.
3. Select the main class. jdtls finds the main classes of the project.

All other keys from [Debugging](#debugging-space-d-and-the-f-keys) apply, with
the IntelliJ F-keys.

### Spring Boot

In `application.properties` and `application.yml`, the editor completes and
validates the property names. `K` shows the documentation of a property.

`gd` on `@Value("${...}")` goes to the property.

In Java code, the editor knows the beans and the request mappings. `Space s s`
shows them in the symbol list.

## Web: TypeScript, JavaScript, Vue, HTML, CSS, Docker

Open Neovim from the project directory, in its dev shell. See
[projects.md](projects.md#javascript--typescript--vue--react). The editor then
finds the Node and the `node_modules` of the project.

| Server | Starts for | Notes |
|---|---|---|
| vtsls | `.ts`, `.tsx`, `.js`, `.jsx`, `.vue` | Uses `node_modules/typescript` of the project. If that is absent, it uses its own TypeScript |
| vue_ls | `.vue` | Templates and styles. The script blocks go through vtsls |
| eslint | JavaScript, TypeScript, Vue | Only with an eslint configuration file. The eslint version is that of the project |
| biome | JavaScript, TypeScript, JSON, CSS, HTML, Vue | Only with a `biome.json` |
| tailwindcss | HTML, CSS, JavaScript, TypeScript, Vue, Markdown and others | Only if `package.json` contains `tailwindcss`, or the project has a `tailwind.config.*` file |
| html, cssls | `.html`, `.css`, `.scss`, `.less` | |
| emmet | HTML, CSS, JSX, TSX, Vue | Completion shows abbreviations, for example `ul>li*3` |
| docker-language-server | `Dockerfile`, `compose.yaml`, `docker-compose.yml`, Bake files | yamlls continues to validate Compose files against their schema |

All keys from [Code intelligence](#code-intelligence) work.

`Space c A` offers these source actions:

- Organise the imports
- Sort the imports
- Remove the imports that are not used
- Add the missing imports
- Correct all TypeScript problems that have an automatic correction
- "Fix all fixable ESLint issues". `:LspEslintFixAll` does this directly

`Space u h` shows type hints for parameters and return types.

Note: in a web project, `Space c R` renames the file but does not update the
imports. vtsls does not offer that function to Neovim.

The editor has no JavaScript test runner and no JavaScript debugger.

Example: use an emmet abbreviation. In an HTML file, type `ul>li*3` and accept
the emmet item in the completion menu. The result is:

```html
<ul>
  <li></li>
  <li></li>
  <li></li>
</ul>
```

## Go

gopls starts with each `.go` file. The Go toolchain comes from the dev shell of
the project. See [projects.md](projects.md#go). Thus you must open Neovim from
the project directory.

A save formats the file with plain gofmt, not with gofumpt. The `go.mod` file
sets format on save to on. `Space c A` offers "Organize Imports".

The results of golangci-lint show only when two conditions are true:

- The project has a `.golangci.yml` file (or `.yaml`, `.toml`, `.json`).
- The dev shell of the project contains golangci-lint.

Tests use the keys in [Tests](#tests-space-t). `Space t d` debugs one test with
delve. `Space d c` offers to debug the package, the file or a test.

## Rust

rustaceanvim starts rust-analyzer with each `.rs` file in a Cargo project.

rust-analyzer, rustfmt, clippy and cargo come from the dev shell of the
project, because they must match its compiler. See
[projects.md](projects.md#rust). Open Neovim from the project directory.

A save formats the file with rustfmt, because `Cargo.toml` sets format on save
to on. The warnings of clippy show after each save.

| Keys | Action |
|---|---|
| `Space c a` | Code actions, with the assists of rust-analyzer |
| `:RustLsp expandMacro` | Show the expansion of the macro at the cursor |
| `:RustLsp explainError` | Explain the error at the cursor |
| `:RustLsp runnables` / `debuggables` | Select an item to run / to debug |

In `Cargo.toml`, crates.nvim shows the latest version of each dependency. It
also completes crate names, versions and features. It gets the data from
crates.io, thus a network connection is necessary.

Tests use the keys in [Tests](#tests-space-t). They run with cargo test, or
with cargo-nextest if it is installed. `Space t d` debugs one test.

## C and C++

clangd starts with C files and C++ files. The build flags of the project must
be in a `compile_commands.json` file in the project root. Without that file,
clangd estimates the flags.

| Build system | How to get `compile_commands.json` |
|---|---|
| CMake | Configure with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` |
| Make | Run the build with `bear`, for example `bear -- make` |

clangd asks Apple clang for the SDK headers.

| Keys | Action |
|---|---|
| `Space c h` | Go between the source file and its header |

The formatter uses the `.clang-format` file of the project. That file also
sets format on save to on. The checks of clang-tidy show if the project has a
`.clang-tidy` file.

To debug a program, do these steps:

1. Build the program with `-g`.
2. Set a breakpoint with `Space d b`.
3. Press `Space d c`.
4. Select "Launch" to start the program. The editor asks for the program and
   its arguments. Or select "Attach to process" to use a program that runs.

## Ruby

ruby-lsp starts with `.rb` files and `.erb` files. ruby-lsp and rubocop (or
standard) come from the `Gemfile` of the project. Thus they run with the Ruby
of the project. See [projects.md](projects.md#ruby-rails-sinatra-padrino).

Open Neovim from the project directory.

The offences that rubocop finds show as diagnostics. A `.rubocop.yml` file or a
`.standard.yml` file sets format on save to on.

In a large project, hover and `gd` work after the server completes its index.
The progress shows at the bottom right.

## PHP

phpactor starts with `.php` files in a project that has a `composer.json` file
or a Git repository.

phpactor works without `vendor/`, but then it reports each framework class as
missing. Run `composer install` first.

The formatter is `vendor/bin/pint` of the project, if it is installed. If not,
the formatter is `vendor/bin/php-cs-fixer`. A `pint.json` file or a
`.php-cs-fixer.php` file sets format on save to on.

## Elixir and Phoenix

Expert starts with `.ex`, `.exs` and `.heex` files. The first start in a
project builds the engine of Expert. This takes some time.

The formatter is `mix format`. It obeys the `.formatter.exs` file of the
project, and that file also sets format on save to on.

Expert looks for the Erlang of the project in a new login shell. It does not
use the environment of Neovim. If it finds no Erlang, it uses the Elixir that
comes with Expert. If a project pins a different Elixir version, this
difference can change the results.

## Terraform

terraform-ls starts with `.tf` files and `.tfvars` files. The terraform CLI
comes from the dev shell of the project. See
[projects.md](projects.md#terraform).

A save formats the file with `terraform fmt`. Format on save is on by default
for Terraform files.

The results of tflint show if the project has a `.tflint.hcl` file and tflint
in its dev shell.

## SQL and databases

In a project with a `postgres-language-server.jsonc` file, the Postgres
language server examines the SQL syntax. If it can connect to a database, it
also examines the names.

A `.sql-formatter.json` file sets the style of sql-formatter and sets format on
save to on. Without that file, `Space c f` formats with the defaults of
sql-formatter.

`Space D` opens the database browser (vim-dadbod-ui).

1. Press `A` in the browser to add a connection.
2. Type the connection as a URL, for example `postgresql://user@localhost/db`
   or `sqlite:path/to.db`.

The editor keeps the saved connections in the data directory of Neovim
(`~/.local/share/nvim/db_ui`). They do not go into a repository.

Caution: a URL with a password is plain text in that directory. Use
`~/.pgpass` or an environment variable for the password.

In a query buffer, the editor completes table names and column names from the
connection. To run one query directly, use `:DB`:

```vim
:DB postgresql://user@localhost/db select count(*) from users
```

## Tests: `Space t`

neotest finds the tests in the file and in the project. It shows the result of
each test as a sign next to the test. A failure also shows as a diagnostic on
the line that failed.

| Keys | Action |
|---|---|
| `Space t r` | Run the test at the cursor |
| `Space t t` | Run all tests in this file |
| `Space t T` | Run the tests of the full project |
| `Space t l` | Run the last run again |
| `Space t d` | Debug the test at the cursor. The run stops at breakpoints |
| `Space t o` | Show the output of the test at the cursor |
| `Space t O` | Show the output panel for all runs |
| `Space t s` | Show the summary tree, with each test and its state |
| `Space t w` | Run the tests of this file again after each save |
| `Space t S` | Stop the run |

The summary tree has its own keys:

| Key in the summary | Action |
|---|---|
| `r` | Run the test |
| `d` | Debug the test |
| `o` | Show the output |
| `i` | Go to the test |
| `Enter` | Expand the item |

Python tests run with pytest from the `.venv` of the project. Go tests run with
`go test`, and Rust tests run with cargo. Java tests use the same keys but run
through jdtls. See [Java and Spring](#java-and-spring).

### Example: correct a test that fails

1. Open the test file and press `Space t t`. A sign shows next to each test.
2. Press `]d` to go to the diagnostic of the failed test.
3. Press `Space t o` to read the output of that test.
4. Press `Space t w`. From now on, each save runs the tests of the file again.
5. Correct the code and save with `Ctrl-S`. The sign changes when the test
   passes.

## Debugging: `Space d` and the F-keys

Set a breakpoint, then start. When a session starts, the debug panel opens at
the bottom. It closes when the session ends.

The panel has these views: variables, watches, call stack, breakpoints,
threads, REPL and console. The bar of the panel shows a letter for each view.
Press the letter to go to the view.

| Keys | IntelliJ key | Action |
|---|---|---|
| `Space d b` | `Ctrl-F8` | Toggle a breakpoint |
| `Space d B` | | Set a conditional breakpoint. The editor asks for the condition |
| `Space d L` | | Set a log point. It prints a message and does not stop |
| `Space d c` | `F9` | Start, or continue to the next breakpoint |
| `Space d C` | `Alt-F9` | Run to the cursor |
| `Space d O` | `F8` | Step over |
| `Space d i` | `F7` | Step into |
| `Space d o` | `Shift-F8` | Step out |
| `Space d P` | | Pause |
| `Space d t` | `Ctrl-F2` | Stop |
| `Space d l` | | Run the last configuration again |
| `Space d e` | | Show the value of the expression at the cursor, or of the selection |
| `Space d w` | | Add the expression at the cursor to the watches |
| `Space d u` | | Show or hide the debug panel |

The debugger is different for each language:

| Language | Debugger |
|---|---|
| Python | debugpy. `Space d c` offers to run the current file, and `Space t d` debugs one test |
| Go | delve |
| C, C++, Rust | `lldb-dap` from Apple. It comes with the Command Line Tools. The output of a Rust program shows in the console of the panel |
| Java | jdtls. See [Java and Spring](#java-and-spring) |

For Python, the debugger runs in the project as
`uv run --with debugpy python -m debugpy.adapter`. Thus it uses the interpreter
and the packages of the project. A network connection is necessary for the
first run if debugpy is not in the cache of uv.

### Example: stop only when a condition is true

1. Put the cursor on a line in a loop.
2. Press `Space d B` and type the condition, for example `i == 42`.
3. Press `Space d c` to start. The program stops only when `i` is 42.
4. Press `Space d w` on a variable to add it to the watches.
5. Press `Space d t` to stop the session.

## Claude Code in the editor

Claude Code runs in its own Ghostty split, not in Neovim. To connect the two,
do these steps:

1. Open Neovim in the project.
2. Type `/ide` in Claude Code.
3. Select Neovim.

After that, Claude sees the current file and your selection. Each edit that
Claude proposes opens in Neovim as a diff, and you accept it or reject it.

| Keys | Action |
|---|---|
| `Space a s` (visual mode) | Send the selection to Claude |
| `Space a b` | Add this file to the context of Claude |
| `Space a a` | Accept the change that Claude proposes (in the diff) |
| `Space a d` | Reject the change |
| `Space a S` | Show the connection status |

Example: ask about a part of a file.

1. Select the lines in visual mode (`V`, then `j`).
2. Press `Space a s`.
3. Go to the Claude Code split and type your question.
4. When Claude proposes an edit, read the diff in Neovim.
5. Press `Space a a` to accept the edit, or `Space a d` to reject it.

## Spelling

The spell check uses English and Serbian Latin together. It is on, with soft
wrap, in Markdown files, plain text files and Git commit messages. In other
files, use `Space u s`.

| Keys | Action |
|---|---|
| `]s` / `[s` | Go to the next / previous word with an error |
| `z=` | Show the suggestions |
| `zg` | Add the word to your list |
| `zw` | Mark the word as incorrect |
| `zug` / `zuw` | Undo `zg` / `zw` |

The words that you add go to `~/.local/share/nvim/spell/en.utf-8.add`. That
file stays on the Mac and is not in the repository.

Example: correct a word and add a name.

1. Press `]s` to go to the next word with an error.
2. Press `z=`, and type the number of the correct suggestion.
3. On a correct name that the dictionary does not know, press `zg`.

## Other behaviour

- Yank and paste use the macOS clipboard directly.
- Neovim loads a file again when a different program changes it, for example
  Git, lazygit or Claude Code. This occurs when the Neovim window gets the
  focus. If the buffer has changes that are not saved, Neovim asks first.
- Neovim writes no swap files and no backup files. It keeps the undo history
  between sessions.
- A file larger than 1.5 MB opens without syntax highlighting. This keeps the
  editor fast.
- When you open a file again, the cursor goes to its last position.
- The default indentation is four spaces. The `.editorconfig` file of a
  project has priority.
- The colour scheme is Monokai Pro "Sun". It matches the "Monokai Pro Light
  Sun" theme of Ghostty. The two are light themes.

Example: an `.editorconfig` file that sets two spaces for all files and tabs
for Makefiles.

```ini
root = true

[*]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
```

## Problems and solutions

### Health checks

```vim
:checkhealth snacks which-key vim.provider
```

These results are normal. They are not faults:

- The python3, Ruby, Node and Perl providers show as disabled. No plugin uses
  them, and a global Python, Ruby, Node or Perl is necessary for them.
- `Snacks.image` shows errors about `gs`, `tectonic` and `mmdc`. The tools to
  render PDF, LaTeX and Mermaid are intentionally not installed. ImageMagick is
  installed.
- conform reports `prettierd unavailable: Condition failed` outside projects
  that configure prettier. That is the intended condition.
- A headless run also reports that the dashboard setup and `vim.ui.select` are
  not done. The two start on the `UIEnter` event, and they work in a terminal.

### Language servers

```vim
:checkhealth vim.lsp     " the configured servers, the attached servers, their root and log path
:lsp restart             " restart the servers of this buffer
```

`Space c l` shows the servers of the current buffer. The log is
`~/.local/state/nvim/lsp.log`. To get more detail in the log for this session,
run `:lua vim.lsp.log.set_level("debug")`.

If a server does not attach, do these checks in sequence:

1. Run `:set filetype?` and make sure that the file type is correct.
2. Run `:checkhealth vim.lsp` and make sure that the root markers of the
   server exist.
3. If the server comes from the project, make sure that you started Neovim in
   the project directory after direnv loaded the dev shell. The language
   sections above name these servers.

nixd evaluates this flake to complete options. If the option documentation
stops after a change, run `:lsp restart`. An evaluation that fails shows in the
LSP log.

### Formatting, tests and debugging

```vim
:ConformInfo             " the formatters of this buffer, if each one is available, and the log
:lua print(_G.workstation_autoformat(0))   " does a save format this buffer?
:checkhealth dap
:DapShowLog              " the log of nvim-dap (adapter start, protocol errors)
```

| Symptom | Cause and solution |
|---|---|
| A `.nvim.lua` file has no effect | Neovim reads the file only after `:trust`. `:trust ++remove` cancels the trust |
| A Python debug session does not start | uv cannot resolve the project, or the project has no `.venv`. Read `~/.local/state/nvim/dap-python-stderr.log`, and run `uv sync` |
| neotest shows all tests as skipped | Get the log. See the procedure below |

neotest has no health check. To get its log, do these steps:

1. Run `:lua require("neotest.logging"):set_level(vim.log.levels.DEBUG)`.
2. Run the tests again.
3. Read `~/.local/state/nvim/neotest.log`.

### Java

```vim
:JdtShowLogs             " the log of jdtls
:JdtWipeDataAndRestart   " delete the project import and start again
:JdtUpdateConfig         " read pom.xml or build.gradle again after an edit
:JdtUpdateDebugConfig    " find the main classes again for Space d c
```

jdtls keeps one workspace for each project in
`~/.cache/nvim/jdtls/workspace/`. Its OSGi log is `.metadata/.log` in that
workspace. If a debug extension or a test extension does not load, the log
shows `Could not resolve module`.

The Spring Boot server writes its log to
`~/.local/state/nvim/spring-boot-ls.log`.

jdtls reads the JDK of the project from `JAVA_HOME` when it starts. If the
project shell was not loaded at that time, use `:JdtSetRuntime` to change the
JDK.

### The connection to Claude Code

`:ClaudeCodeStatus` shows if the server runs and if a client is connected.

While Neovim runs, the server writes the file `~/.claude/ide/<port>.lock`.
`/ide` in Claude Code shows the Neovim instances that it finds there.

### Treesitter

```vim
:checkhealth vim.treesitter
:InspectTree            " the syntax tree of the current buffer
:Inspect                " the highlight groups and captures at the cursor
```

All grammars come from Nix. `:TSInstall` is never necessary.

If a file type has no highlighting, do these checks:

1. Run `:set filetype?` and make sure that the file type is correct.
2. Run this command and make sure that it prints the name of a parser:

   ```vim
   :lua print(vim.treesitter.language.get_lang(vim.bo.filetype))
   ```

## How the editor is built

### Build the editor without activation

You can build only the editor. This is much faster than a full system build.

```bash
host=$(cat /etc/workstation-host)
nix build --no-link --print-out-paths \
  ".#darwinConfigurations.$host.config.home-manager.users.$USER.programs.nixvim.build.package"
nix build --no-link --print-out-paths \
  ".#darwinConfigurations.$host.config.home-manager.users.$USER.programs.nixvim.build.initFile"
```

The first command prints the path of the package. The second command prints
the path of its `init.lua`. Run the built `nvim` with that file, and
`~/.config` stays unchanged:

```bash
<package>/bin/nvim -u <initFile> somefile
```

A test can change your real undo history, shada file and spell list. To
prevent that, point `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` to a
scratch directory:

```bash
scratch=$(mktemp -d)
XDG_DATA_HOME=$scratch/data XDG_STATE_HOME=$scratch/state XDG_CACHE_HOME=$scratch/cache \
  <package>/bin/nvim -u <initFile> somefile
```

After activation, `nixvim-print-init` prints the active `init.lua`.

### One plugin directory

`performance.combinePlugins` merges all plugins into one directory. The build
fails if two plugins contain the same file. To correct that, add one of the two
plugins to `performance.combinePlugins.standalonePlugins`, next to its
configuration.

A plugin that reads files outside the standard runtime directories must also
be standalone. If it is not, it fails without an error message. An example is
neotest-python. It runs `neotest.py` from its plugin root.

The standalone plugins are snacks, blink.cmp, friendly-snippets,
neotest-python and nvim-jdtls.

### Lazy loading

Some plugins load when you first use them, not at startup. The configuration
is in `nixvim/lazy.nix`, and the loader is lz.n.

| Plugin | Loads with |
|---|---|
| nvim-dap, nvim-dap-view | The first `Space d` key or F-key, a command that starts with `:Dap`, a Java file (jdtls), or a Rust file (when rust-analyzer attaches) |
| neotest | The first `Space t` key, `:Neotest`, or a Rust file (when rust-analyzer attaches) |
| claudecode | Immediately after Neovim draws the first screen |
| bufferline | Immediately after Neovim draws the first screen |
| render-markdown | The first Markdown file |
| crates.nvim | The first `Cargo.toml` file |

All other plugins load at startup. Some of them must:

| Plugin | Reason |
|---|---|
| blink.cmp | The language servers must have its capabilities before they start |
| schemastore | The server configurations read it while they are built |
| nvim-jdtls, spring-boot | They must be loaded before the `FileType` event and the attach event of a Java file |

The other plugins are so small that lazy loading gives no advantage.

Code that uses a lazy plugin must load it first, with this call:

```lua
require("lz.n").trigger_load("<plugin directory name>")
```

The reason is that Neovim can `require` a Lua module from a plugin that is not
loaded. It then does not run the setup of the plugin.

To load one plugin manually, run for example
`:lua require("lz.n").trigger_load("nvim-dap")`.

### Startup time

```bash
for i in 1 2 3 4 5; do nvim --headless --startuptime /tmp/nvim-st.$i +qa; tail -1 /tmp/nvim-st.$i; done
```

The last line of each log is the total time in milliseconds. If a start takes
more than approximately 100 ms, look for plugins that can load lazily.

The first file of a type also adds work that occurs one time and that lazy
loading cannot move: its Treesitter grammar, the spell files and the language
servers.

`which -a nvim` shows only the Nix copy:

```console
$ which -a nvim
/etc/profiles/per-user/alice/bin/nvim
```

If a new build of the editor does not work, run `ws rollback`.
