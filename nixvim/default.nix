{ ... }:

# Neovim, built with NixVim. A Home Manager module: it writes
# ~/.config/nvim/init.lua and puts the Nix `nvim` on PATH. One file per
# concern, and one per language under ./lang.
# User guide: docs/tools/neovim.md.
{
  programs.nixvim = {
    enable = true;

    imports = [
      ./options.nix
      ./lazy.nix
      ./colorscheme.nix
      ./keymaps.nix
      ./ui.nix
      ./snacks.nix
      ./spell.nix
      ./treesitter.nix
      ./editing.nix
      ./git.nix
      ./lsp.nix
      ./completion.nix
      ./formatting.nix
      ./lang/nix.nix
      ./lang/lua.nix
      ./lang/shell.nix
      ./lang/markdown.nix
      ./lang/data.nix
      ./debug.nix
      ./test.nix
      ./lang/python.nix
      ./claude.nix
      ./lang/java.nix
      ./lang/web.nix
      ./lang/go.nix
      ./lang/rust.nix
      ./lang/c.nix
      ./lang/ruby.nix
      ./lang/php.nix
      ./lang/elixir.nix
      ./lang/terraform.nix
      ./lang/sql.nix
    ];
  };

  # rumdl's fallback configuration, used only where a project has none of its
  # own: no line-length rule, since Markdown here is soft-wrapped.
  xdg.configFile."rumdl/rumdl.toml".text = ''
    [global]
    disable = ["MD013"]
  '';
}
