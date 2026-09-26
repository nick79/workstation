{ ... }:

# Key hints, statusline, buffer tab bar and icons.
{
  plugins.mini-icons = {
    enable = true;
    # Plugins that ask for nvim-web-devicons (bufferline, lualine) get
    # mini.icons instead; no second icon plugin.
    mockDevIcons = true;
  };

  plugins.which-key = {
    enable = true;
    settings = {
      preset = "classic"; # full-width panel along the bottom of the screen
      # Group names for the leader menus. A group appears only once it has
      # at least one mapping.
      spec = [
        { __unkeyed-1 = "<leader>b"; group = "buffer"; }
        { __unkeyed-1 = "<leader>c"; group = "code"; }
        { __unkeyed-1 = "<leader>d"; group = "debug"; }
        { __unkeyed-1 = "<leader>f"; group = "file/find"; }
        { __unkeyed-1 = "<leader>g"; group = "git"; }
        { __unkeyed-1 = "<leader>gh"; group = "hunks"; }
        { __unkeyed-1 = "<leader>q"; group = "quit"; }
        { __unkeyed-1 = "<leader>s"; group = "search"; }
        { __unkeyed-1 = "<leader>t"; group = "test"; }
        { __unkeyed-1 = "<leader>u"; group = "toggles"; }
        { __unkeyed-1 = "<leader>x"; group = "lists"; }
        { __unkeyed-1 = "<leader><tab>"; group = "tabs"; }
        # <leader>w shows every <C-w> window command, plus wd and wm.
        { __unkeyed-1 = "<leader>w"; group = "windows"; proxy = "<c-w>"; }
        { __unkeyed-1 = "["; group = "previous"; }
        { __unkeyed-1 = "]"; group = "next"; }
        { __unkeyed-1 = "g"; group = "goto"; }
        { __unkeyed-1 = "z"; group = "fold/spell/scroll"; }
      ];
    };
  };

  plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "monokai-pro";
        globalstatus = true;
        disabled_filetypes.statusline = [ "snacks_dashboard" ];
      };
      sections = {
        lualine_c = [
          { __unkeyed-1 = "filename"; path = 1; } # relative path
        ];
      };
    };
  };

  plugins.bufferline = {
    enable = true;
    # Hidden while one buffer is open anyway; ready a moment after startup.
    lazyLoad.settings.event = "DeferredUIEnter";
    settings.options = {
      always_show_bufferline = false; # hidden while only one buffer is open
      close_command.__raw = "function(n) Snacks.bufdelete(n) end";
      right_mouse_command.__raw = "function(n) Snacks.bufdelete(n) end";
      diagnostics = "nvim_lsp";
      offsets = [
        { filetype = "snacks_layout_box"; }
      ];
    };
  };
}
