{ ... }:

# Editing helpers: surround, auto pairs, a terminal, and sessions.
let
  bind = mode: key: action: desc: {
    inherit mode key;
    action.__raw = action;
    options = { inherit desc; silent = true; };
  };
in
{
  # Add, delete, replace surrounding brackets, quotes or tags. Under `gs`,
  # as in LazyVim, so the built-in `s` keeps working.
  plugins.mini-surround = {
    enable = true;
    settings.mappings = {
      add = "gsa";
      delete = "gsd";
      replace = "gsr";
      find = "gsf";
      find_left = "gsF";
      highlight = "gsh";
      update_n_lines = "gsn";
    };
  };

  # Closing brackets and quotes as you type. `Space u p` turns it off.
  plugins.mini-pairs.enable = true;

  # Sessions per working directory, saved on exit to ~/.local/state/nvim.
  plugins.persistence.enable = true;
  opts.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds";

  keymaps = [
    # Terminal. Ghostty sends Ctrl-/ as Ctrl-_, so both are mapped.
    (bind [ "n" "t" ] "<C-/>" "function() Snacks.terminal() end" "Terminal")
    (bind [ "n" "t" ] "<C-_>" "function() Snacks.terminal() end" "which_key_ignore")
    (bind "n" "<leader>ft" "function() Snacks.terminal() end" "Terminal")

    # Sessions (q = quit/session)
    (bind "n" "<leader>qs" ''function() require("persistence").load() end'' "Restore session for this directory")
    (bind "n" "<leader>qS" ''function() require("persistence").select() end'' "Select session")
    (bind "n" "<leader>ql" ''function() require("persistence").load({ last = true }) end'' "Restore last session")
    (bind "n" "<leader>qd" ''function() require("persistence").stop() end'' "Don't save this session")
  ];

  plugins.which-key.settings.spec = [
    { __unkeyed-1 = "gs"; group = "surround"; mode = [ "n" "x" ]; }
  ];

  extraConfigLua = ''
    Snacks.toggle({
      name = "Auto pairs",
      get = function() return not vim.g.minipairs_disable end,
      set = function(on) vim.g.minipairs_disable = not on end,
    }):map("<leader>up")
  '';
}
