{ ... }:

# Tests: neotest. Adapters are per language under ./lang; the test
# tools themselves (pytest, ...) come from the project.
let
  test = key: action: desc: {
    mode = "n";
    inherit key;
    action.__raw = ''function() require("lz.n").trigger_load("neotest"); ${action} end'';
    options = { inherit desc; silent = true; };
  };
in
{
  plugins.neotest = {
    enable = true;
    # Loads on the first Space t key (require) or :Neotest.
    lazyLoad.settings.cmd = "Neotest";
    # "Debug nearest test" needs nvim-dap set up (adapters), not just found.
    luaConfig.pre = ''require("lz.n").trigger_load("nvim-dap")'';
    settings = {
      status.virtual_text = true;
      output.open_on_run = false;
      quickfix.open = false;
    };
  };

  keymaps = [
    (test "<leader>tr" ''require("neotest").run.run()'' "Run nearest test")
    (test "<leader>tt" ''require("neotest").run.run(vim.fn.expand("%"))'' "Run file")
    (test "<leader>tT" ''require("neotest").run.run(vim.uv.cwd())'' "Run all tests")
    (test "<leader>tl" ''require("neotest").run.run_last()'' "Run last")
    (test "<leader>td" ''require("neotest").run.run({ strategy = "dap" })'' "Debug nearest test")
    (test "<leader>ts" ''require("neotest").summary.toggle()'' "Test summary")
    (test "<leader>to" ''require("neotest").output.open({ enter = true, auto_close = true })'' "Test output")
    (test "<leader>tO" ''require("neotest").output_panel.toggle()'' "Output panel")
    (test "<leader>tS" ''require("neotest").run.stop()'' "Stop")
    (test "<leader>tw" ''require("neotest").watch.toggle(vim.fn.expand("%"))'' "Watch file")
  ];
}
