{ pkgs, ... }:

# Spell checking in English and Serbian Latin. English ships with
# Neovim. Serbian Latin comes from Vim's spell-file archive, pinned by hash;
# upstream calls it `sr@latin`, but '@' is not allowed in a Nix store name or
# a 'spelllang' entry, so it is installed as `sr-latin`.
let
  srLatin = pkgs.fetchurl {
    name = "sr-latin.utf-8.spl";
    url = "https://ftp.nluug.nl/pub/vim/runtime/spell/sr%40latin.utf-8.spl";
    hash = "sha256-3s5N80xo6gtQKbREvvbwJ/wyZ7TNq0/os+AoQ+wcgDU=";
  };

  spellFiles = pkgs.runCommand "vim-spell-sr-latin" { } ''
    mkdir -p $out/spell
    cp ${srLatin} $out/spell/sr-latin.utf-8.spl
  '';
in
{
  extraPlugins = [ spellFiles ];

  # Words added with `zg` go to a personal list outside the Nix-managed
  # ~/.config/nvim, so they survive rebuilds. Not tracked in the repository.
  extraConfigLua = ''
    do
      local dir = vim.fn.stdpath("data") .. "/spell"
      vim.fn.mkdir(dir, "p")
      vim.opt.spellfile = dir .. "/en.utf-8.add"
    end
  '';
}
