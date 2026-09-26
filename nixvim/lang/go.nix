{ pkgs, ... }:

# Go: gopls and delve ship with the editor; the Go toolchain itself, and
# golangci-lint when the project uses it, come from the project shell.
# gopls formats with plain gofmt (gofumpt would reformat code that is already
# gofmt-clean), and go.mod turns format on save on (formatting.nix).
let
  delve.path = "${pkgs.delve}/bin/dlv";
in
{
  lsp.servers = {
    gopls = {
      enable = true;
      config.settings.gopls = {
        gofumpt = false;
        usePlaceholders = true;
        analyses = {
          unusedparams = true;
          unusedwrite = true;
          nilness = true;
          shadow = true;
        };
        # Shown with Space u h.
        hints = {
          assignVariableTypes = true;
          compositeLiteralFields = true;
          constantValues = true;
          functionTypeParameters = true;
          parameterNames = true;
          rangeVariableTypes = true;
        };
        codelenses = {
          test = true;
          tidy = true;
          upgrade_dependency = true;
          generate = true;
        };
      };
    };

    # Only where the project configures golangci-lint: lspconfig would
    # otherwise start it for every go.mod, and fail without the binary.
    golangci_lint_ls = {
      enable = true;
      config = {
        root_markers = [
          ".golangci.yml"
          ".golangci.yaml"
          ".golangci.toml"
          ".golangci.json"
        ];
        workspace_required = true;
      };
    };
  };

  # Debugging with delve from Nix; tests debug through the same adapter.
  plugins.dap-go = {
    enable = true;
    settings = { inherit delve; };
  };

  plugins.neotest.adapters.golang = {
    enable = true;
    settings = {
      runner = "go";
      # It calls dap-go's setup again with these, so delve's path goes here too.
      dap_go_opts = { inherit delve; };
    };
  };
}
