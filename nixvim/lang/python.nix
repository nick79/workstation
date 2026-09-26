{ config, ... }:

# Python: ty for types and navigation, ruff for lint, fixes, import sorting
# and formatting (all-in on Astral). Both ship with the editor and find the
# project's uv `.venv` themselves. pytest and debugpy are project
# dependencies: Python comes from uv, and nothing here puts a Python
# interpreter in the editor.
# The one exception is java.nix: nvim-jdtls appends nixpkgs python3 to the
# end of Neovim's PATH, so a project .venv and /usr/bin/python3 still win.
{
  lsp.servers = {
    ty.enable = true;
    ruff.enable = true;
  };

  # ty answers hover (K); ruff's hover only explains lint codes.
  lsp.luaConfig.content = ''
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("workstation_ruff_hover", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "ruff" then client.server_capabilities.hoverProvider = false end
      end,
    })
  '';

  plugins.conform-nvim.settings.formatters_by_ft.python = [
    "ruff_organize_imports"
    "ruff_format"
  ];

  # Debugging runs `uv run --with debugpy python -m debugpy.adapter`: the
  # project's own interpreter and environment, with debugpy added for the
  # session if the project does not list it. Programs and tests run with the
  # project's .venv python.
  plugins.dap-python = {
    enable = true;
    adapterPythonPath = "uv";
  };

  # Outside the combined plugin pack: the adapter runs neotest.py from its
  # plugin root, which combinePlugins does not link, so every test would be
  # reported as skipped.
  performance.combinePlugins.standalonePlugins = [
    config.plugins.neotest.adapters.python.package
  ];

  plugins.neotest.adapters.python = {
    enable = true;
    settings = {
      runner = "pytest";
      dap.justMyCode = false;
    };
  };
}
