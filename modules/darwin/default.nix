{ ... }:

{
  imports = [ ./macos-defaults.nix ./homebrew.nix ./user.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Weekly (nix-darwin default: Sunday 03:15), keep 30 days of generations:
  # a comfortable rollback window without old generations filling the disk.
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  # Touch ID for sudo, written to /etc/pam.d/sudo_local, which macOS includes
  # and keeps across updates. Falls back to the password where Touch ID is
  # unavailable (clamshell without a Touch ID keyboard, SSH sessions).
  security.pam.services.sudo_local.touchIdAuth = true;

  # macOS application firewall: blocks incoming connections to apps, not
  # outgoing traffic. Built-in and downloaded signed software stays allowed
  # automatically (the macOS defaults, kept explicit); stealth mode leaves
  # pings and probes unanswered.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    allowSigned = true;
    allowSignedApp = true;
  };

  programs.zsh.enable = true;
  # Home Manager runs compinit once, after Homebrew's completions are on fpath,
  # and Starship replaces the default prompt.
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.promptInit = "";
  programs.zsh.interactiveShellInit = ''
    typeset -U path
    path=( ''${^''${(s: :)NIX_PROFILES}}/bin $path )
  '';

  system.stateVersion = 6;
}
