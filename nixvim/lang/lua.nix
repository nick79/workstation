{ pkgs, ... }:

# Lua: lua-language-server, stylua.
{
  lsp.servers.lua_ls = {
    enable = true;
    config.settings.Lua = {
      workspace.checkThirdParty = false;
      telemetry.enable = false;
      hint.enable = true; # shown with Space u h
      completion.callSnippet = "Replace";
    };
  };

  plugins.conform-nvim.settings.formatters_by_ft.lua = [ "stylua" ];
  extraPackages = [ pkgs.stylua ];
}
