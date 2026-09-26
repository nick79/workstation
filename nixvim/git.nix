{ ... }:

# Git inside the editor: change signs and hunk actions (gitsigns), lazygit in
# a float, Git pickers, and links to the forge (snacks). Diff review and
# conflict resolution stay with lazygit and ec (docs/tools/git.md).
let
  bind = mode: key: action: desc: {
    inherit mode key;
    action.__raw = action;
    options = { inherit desc; silent = true; };
  };
in
{
  plugins.gitsigns = {
    enable = true;
    settings = {
      signs = {
        add.text = "▎";
        change.text = "▎";
        delete.text = "▁"; # a line under where lines were removed
        topdelete.text = "▔";
        changedelete.text = "▎";
        untracked.text = "▎";
      };
      signs_staged = {
        add.text = "▎";
        change.text = "▎";
        delete.text = "▁";
        topdelete.text = "▔";
        changedelete.text = "▎";
      };
      # Hunk keys only in buffers gitsigns tracks.
      on_attach.__raw = ''
        function(buf)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = buf, desc = desc, silent = true })
          end
          -- In diff mode ]h / [h fall back to the built-in change motions.
          map("n", "]h", function()
            if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
          end, "Next hunk")
          map("n", "[h", function()
            if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
          end, "Previous hunk")
          map("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
          map("n", "[H", function() gs.nav_hunk("first") end, "First hunk")
          -- Staging a staged hunk again unstages it.
          map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<cr>", "Stage or unstage hunk")
          map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<cr>", "Reset hunk")
          map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
          map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")
          map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk inline")
          map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
          map("n", "<leader>ghB", gs.blame, "Blame buffer")
          map("n", "<leader>ghd", gs.diffthis, "Diff against index")
          map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff against last commit")
          map({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
        end
      '';
    };
  };

  keymaps = [
    (bind "n" "<leader>gg" "function() Snacks.lazygit() end" "Lazygit")
    (bind "n" "<leader>gs" "function() Snacks.picker.git_status() end" "Status")
    (bind "n" "<leader>gd" "function() Snacks.picker.git_diff() end" "Changed hunks")
    (bind "n" "<leader>gl" "function() Snacks.picker.git_log() end" "Log")
    (bind "n" "<leader>gf" "function() Snacks.picker.git_log_file() end" "File history")
    (bind "n" "<leader>gb" "function() Snacks.picker.git_log_line() end" "Commits touching this line")
    (bind [ "n" "x" ] "<leader>gB" "function() Snacks.gitbrowse() end" "Open on the forge")
    (bind [ "n" "x" ] "<leader>gY" ''
      function()
        Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
        Snacks.notify("Copied the forge link", { title = "Git" })
      end
    '' "Copy forge link")
  ];

  extraConfigLua = ''
    Snacks.toggle({
      name = "Git signs",
      get = function() return require("gitsigns.config").config.signcolumn end,
      set = function(on) require("gitsigns").toggle_signs(on) end,
    }):map("<leader>uG")
  '';
}
