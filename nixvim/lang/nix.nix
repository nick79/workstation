{ pkgs, ... }:

# Nix: nixd (completion, go-to-definition and option docs from this flake),
# nixfmt.
{
  lsp.servers.nixd = {
    enable = true;
    config = {
      # Filled in when the server starts, so the checkout location
      # (WORKSTATION_DIR, as for ws) and configuration name are this
      # machine's: /etc/workstation-host, else the host name.
      on_init.__raw = ''
        function(client)
          local dir = vim.env.WORKSTATION_DIR or vim.fn.expand("~/github/workstation")
          local marker = io.open("/etc/workstation-host", "r")
          local host
          if marker then
            host = vim.trim(marker:read("*a"))
            marker:close()
          else
            host = vim.trim(vim.fn.system({ "scutil", "--get", "LocalHostName" }))
          end
          local flake = ('(builtins.getFlake "%s")'):format(dir)
          local darwin = ("%s.darwinConfigurations.%q"):format(flake, host)
          client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
            nixd = {
              nixpkgs = { expr = ("import %s.inputs.nixpkgs { }"):format(flake) },
              options = {
                nix_darwin = { expr = darwin .. ".options" },
                home_manager = {
                  expr = darwin .. ".options.home-manager.users.type.getSubOptions [ ]",
                },
              },
            },
          })
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end
      '';
    };
  };

  plugins.conform-nvim.settings.formatters_by_ft.nix = [ "nixfmt" ];
  extraPackages = [ pkgs.nixfmt ];
}
