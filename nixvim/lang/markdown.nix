{ pkgs, ... }:

# Markdown: marksman for links and headings, rumdl for lint and
# format (line-length rule off by default, ../default.nix), rendered
# headings, lists, tables and code blocks in normal mode, inline images in
# Ghostty. Mermaid is not rendered in Neovim; `Space c p` opens the file in
# Typora for that.
{
  lsp.servers = {
    marksman.enable = true;
    rumdl.enable = true;
  };

  plugins.conform-nvim.settings.formatters_by_ft.markdown = [ "rumdl" ];

  # Rendered while reading; the raw text returns in insert mode and on the
  # cursor line. `Space u m` toggles it.
  plugins.render-markdown = {
    enable = true;
    lazyLoad.settings.ft = "markdown";
    settings = {
      file_types = [ "markdown" ];
      completions.lsp.enabled = true;
      code.sign = false;
      heading.sign = false;
    };
  };

  # Images in Markdown and image files, drawn by Ghostty (kitty graphics).
  # ImageMagick converts anything that is not PNG. No LaTeX, PDF or Mermaid
  # rendering: those tools are large and not wanted in the editor.
  plugins.snacks.settings.image.enabled = true;
  extraPackages = [ pkgs.imagemagick ];

  autoCmd = [
    {
      desc = "Markdown: open in Typora";
      event = "FileType";
      pattern = "markdown";
      callback.__raw = ''
        function(ev)
          vim.keymap.set("n", "<leader>cp", function()
            if vim.fn.isdirectory("/Applications/Typora.app") == 0 then
              Snacks.notify.warn("Typora is not installed (a cask in modules/darwin/homebrew.nix)", { title = "Markdown" })
              return
            end
            vim.system({ "open", "-a", "Typora", vim.api.nvim_buf_get_name(ev.buf) })
          end, { buffer = ev.buf, desc = "Open in Typora" })
        end
      '';
    }
  ];

  extraConfigLua = ''
    Snacks.toggle({
      name = "Rendered Markdown",
      -- render-markdown loads with the first Markdown file (nixvim/lazy.nix).
      get = function()
        return package.loaded["render-markdown"] ~= nil and require("render-markdown.state").enabled
      end,
      set = function(on)
        require("lz.n").trigger_load("render-markdown.nvim")
        require("render-markdown")[on and "enable" or "disable"]()
      end,
    }):map("<leader>um")
  '';
}
