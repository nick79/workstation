{ ... }:

# GUI applications stay Homebrew casks, since most update themselves and Nix
# fits self-updating signed macOS apps poorly, but the list is declared here
# so a clean install reproduces it. The module manages an existing Homebrew;
# it does not install one (bootstrap Step 4).
#
# This list is for every Mac. A host adds its own apps with
# homebrew.casks in hosts/<name>/default.nix; nix-darwin joins the two lists.
{
  homebrew = {
    enable = true;

    casks = [
      "bbedit"
      "claude"
      "claude-code@latest"
      "firefox"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "iina"
      "rectangle"
      "the-unarchiver"
      "typora"
    ];

    onActivation = {
      # Never uninstall anything that is not declared. An app taken off a
      # list is removed by hand with `ws remove`, not by activation.
      cleanup = "none";
      # Activation only installs what is missing. Casks update themselves or
      # through `brew upgrade`, run deliberately.
      autoUpdate = false;
      upgrade = false;
    };
  };
}
