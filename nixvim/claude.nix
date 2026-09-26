{ ... }:

# claudecode.nvim: lets Claude Code, running in its own Ghostty split, talk to
# this Neovim over the IDE protocol (`/ide` in Claude Code). It sees the open
# file and selection, can open files, and shows proposed edits as diffs here.
# Not a new AI tool and no completion in the editor.
let
  cmd = mode: key: command: desc: {
    inherit mode key;
    action = "<cmd>${command}<cr>";
    options = { inherit desc; silent = true; };
  };
in
{
  plugins.claudecode = {
    enable = true;
    # Straight after the first screen is drawn: its server must be up for
    # /ide, but not before Neovim shows the file.
    lazyLoad.settings.event = "DeferredUIEnter";
    settings = {
      # Never start `claude` inside Neovim; it runs in a separate split.
      terminal.provider = "none";
      diff_opts.open_in_new_tab = false;
      log_level = "warn"; # no "integration stopped" line on every exit
    };
  };

  # NixVim would add nixpkgs' claude-code to the editor; Claude Code is the
  # self-updating Homebrew cask, run outside Neovim.
  dependencies.claude-code.enable = false;

  keymaps = [
    (cmd "v" "<leader>as" "ClaudeCodeSend" "Send selection to Claude")
    {
      mode = "n";
      key = "<leader>ab";
      action.__raw = ''function() vim.cmd.ClaudeCodeAdd(vim.fn.expand("%:p")) end'';
      options = { desc = "Add this file to Claude's context"; silent = true; };
    }
    (cmd "n" "<leader>aa" "ClaudeCodeDiffAccept" "Accept Claude's change")
    (cmd "n" "<leader>ad" "ClaudeCodeDiffDeny" "Reject Claude's change")
    (cmd "n" "<leader>aS" "ClaudeCodeStatus" "Connection status")
  ];

  plugins.which-key.settings.spec = [
    { __unkeyed-1 = "<leader>a"; group = "claude"; mode = [ "n" "v" ]; }
  ];
}
