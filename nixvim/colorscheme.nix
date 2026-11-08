{ lib, ... }:

# Monokai Pro "Sun", matched to Ghostty's "Monokai Pro Light Sun" theme.
# The plugin's `light` filter is close but not the same palette, so the
# palette below sets its own neutrals and takes the accents from Ghostty's
# ANSI colours: the editor and the terminal around it agree.
let
  palette = {
    background = "#f8efe7";
    dark1 = "#efe4db";
    dark2 = "#e2d5cb";
    text = "#2c232e";
    accent1 = "#ce4770"; # red
    accent2 = "#d4572b"; # orange
    accent3 = "#b16803"; # yellow
    accent4 = "#218871"; # green
    accent5 = "#2473b6"; # blue
    accent6 = "#6851a2"; # purple
    dimmed1 = "#72696d";
    dimmed2 = "#918580";
    dimmed3 = "#a59c9c";
    dimmed4 = "#beb5b3";
    dimmed5 = "#e2d5cb";
  };

  paletteLua = lib.nixvim.toLuaObject palette;
in
{
  opts.background = "light";

  colorschemes.monokai-pro = {
    enable = true;
    settings = {
      filter = "light";
      override_palette.__raw = ''
        function(filter)
          if filter ~= "light" then return {} end
          return ${paletteLua}
        end
      '';
      # The plugin caches its highlights in ~/.cache/nvim and notices only
      # *that* a palette override exists, not what it contains, so a changed
      # palette would keep the old colours. This unused `plugins` entry is
      # part of the cache key: a new palette means a new hash and a rebuild.
      plugins.workstation_palette.hash = builtins.hashString "sha256" paletteLua;
    };
  };

  # Directory names (netrw, `nvim .`) in the plain text colour. The theme
  # draws them pale grey on a background band, which looks disabled.
  highlightOverride.Directory.fg = palette.text;
}
