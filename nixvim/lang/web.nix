{ pkgs, ... }:

# Web: TypeScript/JavaScript (and React), Vue, HTML, CSS, Tailwind, Docker.
# Every server ships with the editor. Where the project has its own
# copy in node_modules/.bin (eslint's, biome's, tailwind's, the vscode-*
# servers), lspconfig starts that one instead; the language itself —
# TypeScript, eslint, prettier, biome's rules — is always the project's.
let
  vue = pkgs.vue-language-server;

  # Hybrid mode: vue_ls handles templates and styles and forwards script
  # requests to vtsls, which needs Vue's TypeScript plugin to understand
  # .vue files. NixVim only wires this for the legacy plugins.lsp module.
  vuePlugin = {
    name = "@vue/typescript-plugin";
    location = "${vue}/lib/language-tools/packages/language-server";
    languages = [ "vue" ];
    configNamespace = "typescript";
    enableForWorkspaceTypeScriptVersions = true;
  };

  jsLike = [ "javascript" "javascriptreact" "typescript" "typescriptreact" "vue" ];
in
{
  lsp.servers = {
    vtsls = {
      enable = true;
      config = {
        filetypes = jsLike;
        settings = {
          vtsls = {
            # The project's node_modules/typescript when it has one, else
            # the TypeScript bundled with vtsls.
            autoUseWorkspaceTsdk = true;
            tsserver.globalPlugins = [ vuePlugin ];
          };
          typescript = {
            inlayHints = {
              parameterNames.enabled = "literals";
              parameterTypes.enabled = true;
              variableTypes.enabled = false;
              propertyDeclarationTypes.enabled = true;
              functionLikeReturnTypes.enabled = true;
              enumMemberValues.enabled = true;
            };
          };
        };
      };
    };
    vue_ls = {
      enable = true;
      package = vue;
    };

    # Both attach only where the project has their configuration file
    # (lspconfig checks); the eslint library itself is the project's.
    eslint.enable = true;
    biome.enable = true;

    html.enable = true;
    cssls.enable = true;
    emmet_language_server.enable = true;

    # lspconfig falls back to any Git repository (for Tailwind 4, which
    # needs no config file), which would start the server for every
    # Markdown, HTML and TypeScript file anywhere. Only start it where the
    # project depends on tailwindcss or has a Tailwind config.
    tailwindcss = {
      enable = true;
      config.root_dir.__raw = ''
        function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local config = vim.fs.find({
            "tailwind.config.js", "tailwind.config.cjs",
            "tailwind.config.mjs", "tailwind.config.ts",
          }, { path = fname, upward = true })[1]
          if config then return on_dir(vim.fs.dirname(config)) end
          local pkg = vim.fs.find("package.json", { path = fname, upward = true })[1]
          if not pkg then return end
          local ok, text = pcall(vim.fn.readblob, pkg)
          if ok and text:find('"tailwindcss"', 1, true) then on_dir(vim.fs.dirname(pkg)) end
        end
      '';
    };

    # Dockerfile, Compose and Bake; replaces dockerls and the compose server.
    docker_language_server.enable = true;
  };

  # Compose files need their own file type for docker-language-server;
  # yamlls and SchemaStore still handle them (yamlls lists this file type).
  filetype.pattern = {
    "compose%.ya?ml" = "yaml.docker-compose";
    "docker%-compose%.ya?ml" = "yaml.docker-compose";
    "compose%..+%.ya?ml" = "yaml.docker-compose";
    "docker%-compose%..+%.ya?ml" = "yaml.docker-compose";
  };
  extraConfigLua = ''
    vim.treesitter.language.register("yaml", "yaml.docker-compose")
  '';

  # biome where the project configures it, else prettierd where it
  # configures prettier, else the language server (formatting.nix).
  plugins.conform-nvim.settings = {
    formatters.biome.require_cwd = true;
    formatters_by_ft =
      let
        web.__raw = ''{ "biome", "prettierd", stop_after_first = true }'';
      in
      {
        javascript = web;
        javascriptreact = web;
        typescript = web;
        typescriptreact = web;
        vue = web;
        css = web;
        scss = [ "prettierd" ];
        less = [ "prettierd" ];
        html = web;
        graphql = web;
      };
  };
}
