{ pkgs, ... }:

# Shell: bash-language-server, which runs shellcheck for diagnostics itself;
# shfmt for formatting. Both tools live on the editor's PATH only, not the
# global one; outside the editor use `nix run nixpkgs#shellcheck`.
{
  # sh and bash files only: shellcheck rejects zsh (SC1071 on every file).
  lsp.servers.bashls.enable = true;

  plugins.conform-nvim.settings.formatters_by_ft = {
    sh = [ "shfmt" ];
    bash = [ "shfmt" ];
  };

  extraPackages = [
    pkgs.shellcheck
    pkgs.shfmt
  ];
}
