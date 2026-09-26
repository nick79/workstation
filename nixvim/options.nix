{ ... }:

# Editor options, autocommands and startup performance.
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
    showmode = false; # lualine shows the mode
    laststatus = 3; # one statusline for all windows
    confirm = true; # ask to save instead of refusing :q
    scrolloff = 8;
    sidescrolloff = 8;
    smoothscroll = true;
    splitright = true;
    splitbelow = true;
    splitkeep = "screen";
    pumheight = 10;
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

    updatetime = 200;
    timeoutlen = 300; # which-key opens after this

    spelllang = "en,sr-latin";
    spelloptions = "camel";
  };

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
      desc = "Keep splits equal when the terminal is resized";
      group = "workstation";
      event = "VimResized";
      command = "tabdo wincmd =";
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
    {
      desc = "Close helper windows with q";
      group = "workstation";
      event = "FileType";
      pattern = [ "help" "qf" "checkhealth" ];
      callback.__raw = ''
        function(ev)
          vim.bo[ev.buf].buflisted = false
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true, desc = "Close window" })
        end
      '';
    }
  ];

  # No python3, Ruby, Node or Perl host providers. None of the plugins needs
  # one; :checkhealth reports them as disabled, not broken.
  # (nvim-jdtls still brings a python3 executable onto PATH; see java.nix.)
  withPython3 = false;
  withRuby = false;
  withNodeJs = false;
  withPerl = false;

  # Startup without a plugin manager (every plugin comes from Nix):
  # byte-compiled Lua, all plugins merged into one pack directory, and
  # Neovim's module cache. lz.n lazy-loads the heavier plugins (lazy.nix), so
  # startup stays under about 100 ms.
  luaLoader.enable = true;
  performance = {
    byteCompileLua = {
      enable = true;
      nvimRuntime = true;
      plugins = true;
    };
    combinePlugins.enable = true;
  };
}
