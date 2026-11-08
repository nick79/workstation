{ ... }:

# Editor options and autocommands.
{
  globals = {
    mapleader = " ";
    maplocalleader = "\\";
  };

  opts = {
    number = true;
    relativenumber = true;
    signcolumn = "yes";
    cursorline = true;
    mouse = "a";
    termguicolors = true;
    confirm = true; # ask to save instead of refusing :q
    scrolloff = 8;
    sidescrolloff = 8;
    smoothscroll = true;
    splitright = true;
    splitbelow = true;
    virtualedit = "block";
    fillchars = "eob: ";

    ignorecase = true;
    smartcase = true;
    inccommand = "nosplit";
    grepprg = "rg --vimgrep";
    grepformat = "%f:%l:%c:%m";

    # Four-space indents. Project settings and .editorconfig (read by Neovim
    # itself) override this per file.
    expandtab = true;
    shiftwidth = 4;
    tabstop = 4;
    shiftround = true;
    smartindent = true;

    # Soft wrap only, and only where it helps (see the autocommand below).
    wrap = false;
    linebreak = true;

    # Persistent undo; no swap or backup files. writebackup stays on:
    # its copy exists only while a write is in progress.
    undofile = true;
    undolevels = 10000;
    swapfile = false;
    backup = false;

    # Picks up files changed outside Neovim; the checktime autocommand below
    # makes it happen on focus instead of only on the next command.
    autoread = true;

    clipboard = "unnamedplus"; # macOS pbcopy/pbpaste

    # English ships with Neovim; no other spell file is installed.
    spelllang = "en";
    spelloptions = "camel";
  };

  # Words added with `zg` go to a personal list outside the Nix-managed
  # ~/.config/nvim, so they survive rebuilds. Not tracked in the repository.
  extraConfigLua = ''
    do
      local dir = vim.fn.stdpath("data") .. "/spell"
      vim.fn.mkdir(dir, "p")
      vim.opt.spellfile = dir .. "/en.utf-8.add"
    end
  '';

  autoGroups.workstation.clear = true;

  autoCmd = [
    {
      desc = "Reload files changed outside Neovim";
      group = "workstation";
      event = [ "FocusGained" "TermClose" "TermLeave" ];
      callback.__raw = ''
        function()
          if vim.o.buftype ~= "nofile" then vim.cmd.checktime() end
        end
      '';
    }
    {
      desc = "Highlight yanked text";
      group = "workstation";
      event = "TextYankPost";
      callback.__raw = "function() vim.hl.on_yank() end";
    }
    {
      desc = "Return to the last cursor position";
      group = "workstation";
      event = "BufReadPost";
      callback.__raw = ''
        function(ev)
          if vim.bo[ev.buf].filetype == "gitcommit" then return end
          local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
          if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end
      '';
    }
    {
      desc = "Soft wrap and spell check prose";
      group = "workstation";
      event = "FileType";
      pattern = [ "markdown" "text" "gitcommit" ];
      callback.__raw = ''
        function()
          vim.opt_local.wrap = true
          vim.opt_local.spell = true
        end
      '';
    }
  ];

  # No python3, Ruby, Node or Perl host providers. No plugin here needs one;
  # :checkhealth reports them as disabled, not broken.
  withPython3 = false;
  withRuby = false;
  withNodeJs = false;
  withPerl = false;
}
