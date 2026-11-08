{ ... }:

# Treesitter: syntax highlighting, indentation and folding from real syntax
# trees, every grammar built by Nix (nothing compiled at runtime).
{
  plugins.treesitter = {
    enable = true;
    # grammarPackages defaults to all grammars nixpkgs builds for this
    # nvim-treesitter (about 320), so any file type highlights without setup.
    highlight.enable = true;
    indent.enable = true;
    folding.enable = true;
  };

  # Folds come from Treesitter but start open; zc / zo / za / zR / zM as usual.
  opts = {
    foldlevel = 99;
    foldtext = ""; # show the folded line itself, highlighted
  };
}
