{ ... }:

# YAML, JSON and TOML. Schemas come from SchemaStore (bundled, not fetched
# per file), so package.json, GitHub workflows, docker-compose files and the
# like get completion and validation. Formatting: biome or prettierd where the
# project configures one, otherwise the language server (formatting.nix).
{
  lsp.servers = {
    jsonls.enable = true;
    yamlls.enable = true;
    tombi.enable = true;
  };

  plugins.schemastore = {
    enable = true;
    json.enable = true;
    yaml.enable = true;
  };

  plugins.conform-nvim.settings.formatters_by_ft = {
    # biome first where the project configures it (lang/web.nix).
    json.__raw = ''{ "biome", "prettierd", stop_after_first = true }'';
    jsonc.__raw = ''{ "biome", "prettierd", stop_after_first = true }'';
    yaml = [ "prettierd" ];
  };
}
