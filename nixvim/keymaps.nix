{ ... }:

# Core keys that need no plugin beyond snacks. LazyVim's layout; plugin keys
# live next to their plugin. Neovim's built-in maps (gc, gr*, [b ]b, [q ]q,
# ...) are never remapped.
let
  bind = mode: key: action: desc: {
    inherit mode key action;
    options = { inherit desc; silent = true; };
  };
  lua = code: { __raw = code; };
in
{
  keymaps = [
    # Save in every mode. Replaces insert-mode <C-s> signature help, which
    # is `gK` instead (lsp.nix); blink.cmp also shows it while typing.
    (bind [ "n" "i" "x" "s" ] "<C-s>" "<cmd>write<cr><esc>" "Save file")
    (bind [ "n" "i" "s" ] "<Esc>" "<cmd>nohlsearch<cr><esc>" "Clear search highlight")
    (bind "n" "<leader>qq" "<cmd>qa<cr>" "Quit all")
    (bind "n" "<leader>fn" "<cmd>enew<cr>" "New file")

    # Move by screen line in wrapped text unless a count is given.
    {
      mode = [ "n" "x" ];
      key = "j";
      action = "v:count == 0 ? 'gj' : 'j'";
      options = { expr = true; silent = true; desc = "Down"; };
    }
    {
      mode = [ "n" "x" ];
      key = "k";
      action = "v:count == 0 ? 'gk' : 'k'";
      options = { expr = true; silent = true; desc = "Up"; };
    }

    # Keep the selection when indenting.
    (bind "x" "<" "<gv" "Indent left")
    (bind "x" ">" ">gv" "Indent right")

    # Undo break points inside a long insert.
    (bind "i" "," ",<c-g>u" "Comma with undo point")
    (bind "i" "." ".<c-g>u" "Period with undo point")
    (bind "i" ";" ";<c-g>u" "Semicolon with undo point")

    # Windows. <leader>w opens the <C-w> menu through which-key (ui.nix).
    (bind "n" "<C-h>" "<C-w>h" "Window left")
    (bind "n" "<C-j>" "<C-w>j" "Window below")
    (bind "n" "<C-k>" "<C-w>k" "Window above")
    (bind "n" "<C-l>" "<C-w>l" "Window right")
    (bind "n" "<C-Up>" "<cmd>resize +2<cr>" "Taller window")
    (bind "n" "<C-Down>" "<cmd>resize -2<cr>" "Shorter window")
    (bind "n" "<C-Left>" "<cmd>vertical resize -2<cr>" "Narrower window")
    (bind "n" "<C-Right>" "<cmd>vertical resize +2<cr>" "Wider window")
    (bind "n" "<leader>-" "<C-w>s" "Split below")
    (bind "n" "<leader>|" "<C-w>v" "Split right")
    (bind "n" "<leader>wd" "<C-w>c" "Close window")

    # Buffers. Shift-H/L shadow the rarely used H and L motions.
    (bind "n" "<S-h>" "<cmd>BufferLineCyclePrev<cr>" "Previous buffer")
    (bind "n" "<S-l>" "<cmd>BufferLineCycleNext<cr>" "Next buffer")
    (bind "n" "<leader>bb" "<cmd>e #<cr>" "Other buffer")
    (bind "n" "<leader>bd" (lua "function() Snacks.bufdelete() end") "Delete buffer")
    (bind "n" "<leader>bo" (lua "function() Snacks.bufdelete.other() end") "Delete other buffers")

    # Tabs.
    (bind "n" "<leader><tab><tab>" "<cmd>tabnew<cr>" "New tab")
    (bind "n" "<leader><tab>d" "<cmd>tabclose<cr>" "Close tab")
    (bind "n" "<leader><tab>o" "<cmd>tabonly<cr>" "Close other tabs")
    (bind "n" "<leader><tab>]" "<cmd>tabnext<cr>" "Next tab")
    (bind "n" "<leader><tab>[" "<cmd>tabprevious<cr>" "Previous tab")

    # Quickfix and location lists.
    (bind "n" "<leader>xq" (lua ''
      function()
        local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
        if not ok and err then vim.notify(err, vim.log.levels.ERROR) end
      end
    '') "Quickfix list")
    (bind "n" "<leader>xl" (lua ''
      function()
        local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
        if not ok and err then vim.notify(err, vim.log.levels.ERROR) end
      end
    '') "Location list")
  ];
}
