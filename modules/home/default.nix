{ pkgs, ... }:

{
  imports = [ ./shell.nix ./ws ./git.nix ./cli.nix ./containers.nix ./ghostty.nix ./ssh.nix ./claude ../../nixvim ];

  home.stateVersion = "26.05";
}
