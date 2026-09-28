{ pkgs, ... }:

# The work Mac. Its host name and computer name are not declared: macOS
# keeps whatever the Mac is called, and the name stays out of this repository.
# Nothing work-specific belongs here: private hosts go in ~/.ssh/config.local,
# the Git email in ~/.config/git/local.
{
  # The account; every home path derives from it (modules/darwin/user.nix).
  system.primaryUser = "milannikicnik";

  # Power differs by source here, which power.sleep cannot express: on
  # battery the display sleeps after 5 minutes and Energy Mode is High Power
  # (powermode 2); on the power adapter the Mac itself never sleeps.
  # Activation runs as root.
  system.activationScripts.postActivation.text = ''
    /usr/bin/pmset -b displaysleep 5
    /usr/bin/pmset -b powermode 2
    /usr/bin/pmset -c sleep 0
  '';

  # Apps for this Mac only, on top of the shared list in modules/darwin/homebrew.nix.
  homebrew.casks = [
    "chatgpt"
    "codex"
    "google-chrome"
    "parallels"
    "slack"
  ];

  home-manager.users.milannikicnik = {
    # Security tooling for this Mac only: CycloneDX SBOMs and static analysis.
    home.packages = [
      pkgs.cdxgen
      pkgs.semgrep
    ];

    # This Mac's GitHub key (docs/tools/ssh.md). The key itself is never in
    # the repository; each Mac names its own.
    programs.ssh.settings."github.com" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/id_rsa_work";
      IdentitiesOnly = "yes";
    };
  };
}
