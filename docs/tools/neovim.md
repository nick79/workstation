# Neovim

Neovim is the editor for quick edits in the terminal. Examples are a Git commit
message, a configuration file, or a file that a script or Claude Code names.
For development, use IntelliJ IDEA. See [intellij.md](intellij.md).

NixVim builds Neovim from the `nixvim/` directory of this repository. The
editor has two plugins: the Monokai Pro colour scheme and Treesitter. It has
no language servers, no completion, no formatters and no file finder. All
plugins come from Nix, and the editor downloads nothing while it runs.

To change the editor, edit the files in `nixvim/`. Then run `ws build` and
`ws switch`. A change to `~/.config/nvim/init.lua` does not last, because that
file is a link into the Nix store.

Neovim is the `EDITOR` of the shell. Git, lazygit and ec open it when they
need an editor.

The leader key is `Space`. In this guide, `Space q q` means: press `Space`,
then `q`, then `q`.

## Keys

The configuration adds these keys to the keys of Neovim:

| Keys | Action |
|---|---|
| `Ctrl-S` | Save, in all modes |
| `Esc` | Also removes the search highlight |
| `Shift-H` / `Shift-L` | Go to the previous / next buffer |
| `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` | Go to the window on the left / below / above / on the right |
| `Space q q` | Quit Neovim. It asks about files that are not saved |
| `<` / `>` in visual mode | Indent the selection, and keep the selection |

`j` and `k` move by screen line in wrapped text. With a count, for example
`5j`, they move by real line. Thus relative line numbers continue to work.

These keys of Neovim itself are also useful:

| Keys | Action |
|---|---|
| `Ctrl-w s` / `Ctrl-w v` | Split the window below / to the right |
| `Ctrl-w c` | Close the window |
| `gcc` / `gc` in visual mode | Comment or uncomment the line / the selection |
| `:e <file>` | Open a different file. `Tab` completes the name |
| `u` / `Ctrl-r` | Undo / redo |

### Example: change a configuration file

1. Open the file:

   ```bash
   nvim ~/.ssh/config.local
   ```

2. Type `/Host`, and press `Enter` to go to the first match. Press `n` to go
   to the next match.
3. Make the change.
4. Press `Ctrl-S` to save.
5. Press `Space q q` to quit.

### Example: open a file that you find with fzf

Type `nvim **` and press `Tab`. fzf shows the files below the current
directory. Select a file and press `Enter`. Then press `Enter` again to start
Neovim. See [shell.md](shell.md) for the other fzf keys.

## Files and directories

`nvim .` opens netrw, the file browser of Neovim. `:Explore` opens it from
the directory of the current file.

| Key in netrw | Action |
|---|---|
| `Enter` | Open the file or the directory |
| `-` | Go to the parent directory |
| `%` | Open a new file in this directory. netrw asks for the name. Save the file to create it |
| `d` | Create a directory |
| `R` | Rename the file under the cursor |
| `gh` | Show or hide the hidden files |

## Spelling

The spell check uses English. It is on, with soft wrap, in Markdown files,
plain text files and Git commit messages. In other files, type `:set spell`.
Type `:set nospell` to set it to off.

| Keys | Action |
|---|---|
| `]s` / `[s` | Go to the next / previous word with an error |
| `z=` | Show the suggestions |
| `zg` | Add the word to your list |
| `zw` | Mark the word as incorrect |
| `zug` / `zuw` | Undo `zg` / `zw` |

The words that you add go to `~/.local/share/nvim/spell/en.utf-8.add`. That
file stays on the Mac and is not in the repository.

Example: correct a word in a commit message.

1. Run `git commit`. Neovim opens the commit message.
2. Press `]s` to go to the next word with an error.
3. Press `z=`, type the number of the correct suggestion, and press `Enter`.
4. On a correct name that the dictionary does not know, press `zg`.

## Folds

Treesitter makes the folds, for example one fold for each function or each
YAML block. All folds are open when a file opens.

| Keys | Action |
|---|---|
| `zc` / `zo` | Close / open the fold at the cursor |
| `za` | Close or open the fold at the cursor |
| `zM` / `zR` | Close / open all folds |

## Other behaviour

- Yank and paste use the macOS clipboard directly.
- Neovim loads a file again when a different program changes it, for example
  Git, IntelliJ IDEA or Claude Code. This occurs when the Neovim window gets
  the focus. If the buffer has changes that are not saved, Neovim asks first.
- Neovim writes no swap files and no backup files. It keeps the undo history
  between sessions.
- When you open a file again, the cursor goes to its last position.
- Treesitter supplies the syntax colours for all usual file types. All
  grammars come from Nix. `:TSInstall` is never necessary.
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
:checkhealth vim.treesitter vim.provider
```

The python3, Ruby, Node and Perl providers show as disabled. This is normal.
No plugin uses them.

### A file type has no colours

```vim
:InspectTree            " the syntax tree of the current buffer
:Inspect                " the highlight groups and captures at the cursor
```

Do these checks:

1. Run `:set filetype?` and make sure that the file type is correct.
2. Run this command and make sure that it prints the name of a parser:

   ```vim
   :lua print(vim.treesitter.language.get_lang(vim.bo.filetype))
   ```

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
