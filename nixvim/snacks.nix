{ config, ... }:

# snacks.nvim first: one plugin for the picker, explorer, dashboard,
# notifications, zen mode, big-file handling and toggles. Other files use more
# of it: the terminal (editing.nix), lazygit and gitbrowse (git.nix), word
# highlights (lsp.nix) and images (lang/markdown.nix).
let
  bind = key: action: desc: {
    mode = "n";
    inherit key;
    action.__raw = action;
    options = { inherit desc; silent = true; };
  };
  pick = key: source: desc: bind key "function() Snacks.picker.${source}() end" desc;

  # The editor configuration is Nix in this repository, not ~/.config/nvim.
  configDir = ''(vim.env.WORKSTATION_DIR or vim.fn.expand("~/github/workstation")) .. "/nixvim"'';
in
{
  plugins.snacks = {
    enable = true;
    settings = {
      bigfile.enabled = true; # plain syntax, no Treesitter or LSP past 1.5 MB
      quickfile.enabled = true; # draw `nvim file` before plugins finish loading
      notifier.enabled = true; # replaces vim.notify
      picker.enabled = true;
      explorer = {
        enabled = true;
        replace_netrw = true;
      };
      zen = {
        enabled = true;
        win.width = 120;
      };
      dashboard = {
        enabled = true;
        # Nerd Font icons as Lua escapes: the glyphs are private-use characters
        # that do not survive every editor and copy-paste.
        preset.keys = [
          { icon.__raw = ''"\u{f002} "''; key = "f"; desc = "Find file"; action = ":lua Snacks.picker.files()"; }
          { icon.__raw = ''"\u{f15b} "''; key = "n"; desc = "New file"; action = ":ene | startinsert"; }
          { icon.__raw = ''"\u{f022} "''; key = "g"; desc = "Find text"; action = ":lua Snacks.picker.grep()"; }
          { icon.__raw = ''"\u{f0c5} "''; key = "r"; desc = "Recent files"; action = ":lua Snacks.picker.recent()"; }
          { icon.__raw = ''"\u{f423} "''; key = "c"; desc = "Config"; action.__raw = "function() Snacks.picker.files({ cwd = ${configDir} }) end"; }
          { icon.__raw = ''"\u{e348} "''; key = "s"; desc = "Restore session"; section = "session"; } # persistence, editing.nix
          { icon.__raw = ''"\u{f426} "''; key = "q"; desc = "Quit"; action = ":qa"; }
        ];
        # The default list ends with a startup section that needs lazy.nvim.
        sections = [
          { section = "header"; }
          { section = "keys"; gap = 1; padding = 1; }
        ];
      };
    };
  };

  # Kept out of the combined plugin pack (options.nix): snacks ships its own
  # queries/markdown/injections.scm, which extends nvim-treesitter's file of
  # the same name and would collide with it when merged.
  performance.combinePlugins.standalonePlugins = [ config.plugins.snacks.package ];

  keymaps = [
    # Top level
    (pick "<leader><space>" "files" "Find files")
    (pick "<leader>/" "grep" "Grep")
    (pick "<leader>," "buffers" "Buffers")
    (pick "<leader>:" "command_history" "Command history")
    (bind "<leader>e" "function() Snacks.explorer() end" "Explorer")
    (bind "<leader>n" "function() Snacks.notifier.show_history() end" "Notification history")

    # f: files
    (pick "<leader>ff" "files" "Find files")
    (bind "<leader>fF" "function() Snacks.picker.files({ hidden = true, ignored = true }) end" "Find files (hidden and ignored too)")
    (pick "<leader>fr" "recent" "Recent files")
    (pick "<leader>fb" "buffers" "Buffers")
    (bind "<leader>fc" "function() Snacks.picker.files({ cwd = ${configDir} }) end" "Find config file")

    # s: search
    (pick "<leader>sg" "grep" "Grep")
    {
      mode = [ "n" "x" ];
      key = "<leader>sw";
      action.__raw = "function() Snacks.picker.grep_word() end";
      options = { desc = "Word or selection"; silent = true; };
    }
    (pick "<leader>sb" "lines" "Buffer lines")
    (pick "<leader>sh" "help" "Help pages")
    (pick "<leader>sk" "keymaps" "Keymaps")
    (pick "<leader>sc" "command_history" "Command history")
    (pick "<leader>sC" "commands" "Commands")
    (pick "<leader>sm" "marks" "Marks")
    (pick "<leader>sj" "jumps" "Jumps")
    (pick "<leader>sM" "man" "Man pages")
    (pick "<leader>sH" "highlights" "Highlights")
    (pick "<leader>su" "undo" "Undo history")
    (pick "<leader>sq" "qflist" "Quickfix list")
    (pick "<leader>sl" "loclist" "Location list")
    (bind "<leader>s\"" "function() Snacks.picker.registers() end" "Registers")
    (pick "<leader>sR" "resume" "Resume last search")

    # u: toggles (the Snacks.toggle ones are registered below)
    (pick "<leader>uC" "colorschemes" "Colorschemes")
    (bind "<leader>un" "function() Snacks.notifier.hide() end" "Dismiss notifications")
  ];

  # Toggles that show their state in which-key and notify when flipped.
  extraConfigLua = ''
    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    Snacks.toggle.line_number():map("<leader>ul")
    Snacks.toggle.option("relativenumber", { name = "Relative number" }):map("<leader>uL")
    Snacks.toggle.zen():map("<leader>uz")
    Snacks.toggle.zoom():map("<leader>uZ"):map("<leader>wm")
  '';
}
