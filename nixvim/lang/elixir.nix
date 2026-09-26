{ pkgs, ... }:

# Elixir and Phoenix: Expert, the official language server. It builds
# its analysis engine with the project's Elixir from PATH, so open Neovim in
# the project shell. Formatting is `mix format` through Expert, following the
# project's .formatter.exs, which also turns format on save on.
{
  lsp.servers.expert = {
    enable = true;
    # Not mapped by NixVim at this pin.
    package = pkgs.beamPackages.expert;
  };
}
