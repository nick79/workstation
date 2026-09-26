{ ... }:

# Language servers: Neovim's own LSP client (vim.lsp.config/enable), with
# nvim-lspconfig supplying each server's defaults (command, file types, root
# markers). Servers are enabled per language under ./lang. Keys follow
# Neovim's built-in gr* family plus LazyVim's leader groups.
let
  bind = mode: key: action: desc: {
    inherit mode key;
    action.__raw = action;
    options = { inherit desc; silent = true; };
  };
  pick = key: source: desc: bind "n" key "function() Snacks.picker.${source}() end" desc;
in
{
  plugins.lspconfig.enable = true;

  # Built-in keys that work once a server is attached (never remapped):
  # K hover, grr references, gri implementation, grt type definition,
  # grn rename, gra code action, grx code lens, gO document symbols,
  # ]d / [d diagnostics. Insert-mode <C-s> saves here (keymaps.nix), so
  # signature help is gK; blink.cmp also shows it while typing arguments.
  lsp.keymaps = [
    { key = "gd"; action.__raw = "function() Snacks.picker.lsp_definitions() end"; options.desc = "Go to definition"; }
    { key = "gD"; lspBufAction = "declaration"; options.desc = "Go to declaration"; }
    { key = "gai"; action.__raw = "function() Snacks.picker.lsp_incoming_calls() end"; options.desc = "Incoming calls"; }
    { key = "gao"; action.__raw = "function() Snacks.picker.lsp_outgoing_calls() end"; options.desc = "Outgoing calls"; }
    { key = "gK"; lspBufAction = "signature_help"; options.desc = "Signature help"; }
    { key = "<leader>ca"; mode = [ "n" "x" ]; lspBufAction = "code_action"; options.desc = "Code action"; }
    {
      key = "<leader>cA";
      action.__raw = ''
        function()
          vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
        end
      '';
      options.desc = "Source action";
    }
    { key = "<leader>cr"; lspBufAction = "rename"; options.desc = "Rename symbol"; }
    { key = "<leader>cR"; action.__raw = "function() Snacks.rename.rename_file() end"; options.desc = "Rename file (updates imports)"; }
    { key = "<leader>cl"; action.__raw = "function() Snacks.picker.lsp_config() end"; options.desc = "Language servers"; }
    { key = "<leader>ss"; action.__raw = "function() Snacks.picker.lsp_symbols() end"; options.desc = "Symbols in file"; }
    { key = "<leader>sS"; action.__raw = "function() Snacks.picker.lsp_workspace_symbols() end"; options.desc = "Symbols in project"; }
    { key = "]]"; action.__raw = "function() Snacks.words.jump(vim.v.count1) end"; options.desc = "Next reference"; }
    { key = "[["; action.__raw = "function() Snacks.words.jump(-vim.v.count1) end"; options.desc = "Previous reference"; }
  ];

  # Highlight other uses of the symbol under the cursor; ]] / [[ jump.
  plugins.snacks.settings.words.enabled = true;

  diagnostic.settings = {
    severity_sort = true;
    underline = true;
    update_in_insert = false;
    virtual_text = {
      spacing = 4;
      source = "if_many";
      prefix = "●";
    };
    float = {
      border = "rounded";
      source = "if_many";
    };
    signs.text.__raw = ''
      {
        [vim.diagnostic.severity.ERROR] = "\u{f057} ",
        [vim.diagnostic.severity.WARN] = "\u{f071} ",
        [vim.diagnostic.severity.INFO] = "\u{f05a} ",
        [vim.diagnostic.severity.HINT] = "\u{f0335} ",
      }
    '';
  };

  keymaps = [
    (bind "n" "<leader>cd" "function() vim.diagnostic.open_float() end" "Line diagnostics")
    (bind "n" "]e" "function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end" "Next error")
    (bind "n" "[e" "function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end" "Previous error")
    (bind "n" "]w" "function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN }) end" "Next warning")
    (bind "n" "[w" "function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN }) end" "Previous warning")
    (pick "<leader>sd" "diagnostics_buffer" "Diagnostics in file")
    (pick "<leader>sD" "diagnostics" "Diagnostics in project")
    (pick "<leader>xx" "diagnostics" "Diagnostics")
  ];

  extraConfigLua = ''
    Snacks.toggle.diagnostics():map("<leader>ud")
    Snacks.toggle.inlay_hints():map("<leader>uh")
  '';
}
