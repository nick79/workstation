{ ... }:

# Neovim, built with NixVim: a small editor for quick edits in the terminal
# (commit messages, configuration files, a file that Claude Code or a script
# points to). Development happens in IntelliJ IDEA (docs/tools/intellij.md),
# so there are no language servers, completion, formatters or debuggers here.
# A Home Manager module: it writes ~/.config/nvim/init.lua and puts the Nix
# `nvim` on PATH. User guide: docs/tools/neovim.md.
{
  programs.nixvim = {
    enable = true;

    imports = [
      ./options.nix
      ./colorscheme.nix
      ./keymaps.nix
      ./treesitter.nix
    ];
  };
}
