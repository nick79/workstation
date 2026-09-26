{ pkgs, ... }:

# SQL: postgres-language-server only where the project has its
# postgres-language-server.jsonc (lspconfig checks); sql-formatter where the
# project has a .sql-formatter.json. vim-dadbod runs queries against
# databases; the UI keeps saved connections in Neovim's data directory,
# outside any repository, since a connection URL can hold a password.
# Completion of tables and columns comes from the open connection.
{
  lsp.servers.postgres_lsp.enable = true;

  plugins.conform-nvim.settings.formatters_by_ft.sql = [ "sql_formatter" ];
  extraPackages = [ pkgs.sql-formatter ];

  plugins.vim-dadbod.enable = true;
  plugins.vim-dadbod-completion.enable = true;
  plugins.vim-dadbod-ui.enable = true;
  # Its module has no settings option; these are its g:db_ui_* variables.
  globals = {
    db_ui_use_nerd_fonts = 1;
    db_ui_save_location.__raw = ''vim.fn.stdpath("data") .. "/db_ui"'';
    db_ui_execute_on_save = 0;
    db_ui_show_database_icon = 1;
  };

  plugins.blink-cmp.settings.sources = {
    per_filetype = {
      sql = [ "dadbod" "snippets" "buffer" ];
      mysql = [ "dadbod" "snippets" "buffer" ];
      plsql = [ "dadbod" "snippets" "buffer" ];
    };
    providers.dadbod = {
      name = "Dadbod";
      module = "vim_dadbod_completion.blink";
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>D";
      action = "<cmd>DBUIToggle<cr>";
      options = { desc = "Databases (dadbod)"; silent = true; };
    }
  ];
}
