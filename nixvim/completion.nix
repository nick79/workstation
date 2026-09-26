{ config, ... }:

# Completion: blink.cmp, IDE-style. Enter accepts, Tab / Shift-Tab and the
# arrows move, Ctrl-Space opens the menu, Ctrl-e closes it. Sources: the
# language server, file paths, snippets (friendly-snippets) and words from
# the buffer. No AI completion; AI help comes from Claude Code (claude.nix).
{
  plugins.friendly-snippets.enable = true;

  # Outside the combined plugin pack: blink.cmp and conform.nvim both ship
  # doc/recipes.md, which collides when merged, and blink.cmp finds
  # friendly-snippets only as a separate plugin directory.
  performance.combinePlugins.standalonePlugins = [
    config.plugins.blink-cmp.package
    config.plugins.friendly-snippets.package
  ];

  plugins.blink-cmp = {
    enable = true;
    settings = {
      keymap = {
        preset = "enter";
        "<Tab>" = [ "select_next" "snippet_forward" "fallback" ];
        "<S-Tab>" = [ "select_prev" "snippet_backward" "fallback" ];
      };
      completion = {
        # The first item is preselected, as in IntelliJ: Enter takes it.
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
        };
        menu.border = "rounded";
        documentation.window.border = "rounded";
      };
      signature = {
        enabled = true;
        window.border = "rounded";
      };
      sources.default = [ "lsp" "path" "snippets" "buffer" ];
      # The Rust fuzzy matcher is prebuilt by nixpkgs; nothing is downloaded.
      fuzzy.implementation = "prefer_rust_with_warning";
    };
  };
}
