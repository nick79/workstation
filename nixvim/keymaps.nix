{ ... }:

# A few keys on top of Neovim's defaults. Neovim's built-in maps (gc, [b ]b,
# <C-w>s / <C-w>v splits, ...) are never remapped.
let
  bind = mode: key: action: desc: {
    inherit mode key action;
    options = { inherit desc; silent = true; };
  };
in
{
  keymaps = [
    (bind [ "n" "i" "x" "s" ] "<C-s>" "<cmd>write<cr><esc>" "Save file")
    (bind [ "n" "i" "s" ] "<Esc>" "<cmd>nohlsearch<cr><esc>" "Clear search highlight")
    (bind "n" "<leader>qq" "<cmd>qa<cr>" "Quit all")

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

    (bind "n" "<C-h>" "<C-w>h" "Window left")
    (bind "n" "<C-j>" "<C-w>j" "Window below")
    (bind "n" "<C-k>" "<C-w>k" "Window above")
    (bind "n" "<C-l>" "<C-w>l" "Window right")

    # Shift-H/L shadow the rarely used H and L motions.
    (bind "n" "<S-h>" "<cmd>bprevious<cr>" "Previous buffer")
    (bind "n" "<S-l>" "<cmd>bnext<cr>" "Next buffer")
  ];
}
