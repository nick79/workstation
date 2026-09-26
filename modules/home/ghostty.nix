{ ... }:

{
  # Ghostty itself is the Homebrew cask; Home Manager writes only
  # ~/.config/ghostty/config, which Ghostty reads on macOS.
  programs.ghostty = {
    enable = true;
    package = null;
    # Ghostty already injects its zsh integration automatically; the module's
    # extra `source` line in .zshrc would only duplicate it.
    enableZshIntegration = false;
    settings = {
      font-size = 17;
      # Neovim's palette is tuned to this theme.
      theme = "Monokai Pro Light Sun";
      # Literal \x1b\r: sends ESC+CR, which Claude Code reads as a newline
      # instead of submit.
      keybind = "shift+enter=text:\\x1b\\r";
    };
  };
}
