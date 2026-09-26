{ ... }:

# Debugging: nvim-dap with nvim-dap-view as the panel. Adapters are
# per language under ./lang. Keys under `Space d`, plus IntelliJ's F-keys
# (F-keys are standard function keys on this Mac, com.apple.keyboard.fnState).
let
  dap = key: action: desc: {
    mode = "n";
    inherit key;
    # Through lz.n, so dap's setup (signs, adapters, dap-view) has run.
    action.__raw = ''function() require("lz.n").trigger_load("nvim-dap"); ${action} end'';
    options = { inherit desc; silent = true; };
  };
  # Terminals send Shift/Ctrl/Alt+F-keys either as modifiers (<S-F8>) or as
  # higher F numbers (<F20>); map both, hide the second from which-key.
  alias = key: action: dap key action "which_key_ignore";
in
{
  plugins.dap = {
    enable = true;
    # Loads on the first Space d / F-key (require) or :Dap… command, and
    # brings dap-view with it so the panel opens with the first session.
    lazyLoad.settings.cmd = [
      "DapContinue"
      "DapNew"
      "DapToggleBreakpoint"
      "DapShowLog"
      "DapTerminate"
    ];
    luaConfig.post = ''require("lz.n").trigger_load("nvim-dap-view")'';
    signs = {
      dapBreakpoint = { text = "●"; texthl = "DiagnosticError"; };
      dapBreakpointCondition = { text = "◆"; texthl = "DiagnosticWarn"; };
      dapLogPoint = { text = "◆"; texthl = "DiagnosticInfo"; };
      dapBreakpointRejected = { text = "○"; texthl = "DiagnosticError"; };
      dapStopped = { text = "→"; texthl = "DiagnosticWarn"; linehl = "Visual"; };
    };
  };

  # Opens with a debug session and closes when the last one ends.
  plugins.dap-view = {
    enable = true;
    lazyLoad.settings.cmd = [
      "DapViewOpen"
      "DapViewToggle"
    ];
    settings.auto_toggle = true;
  };

  keymaps = [
    (dap "<leader>db" ''require("dap").toggle_breakpoint()'' "Toggle breakpoint")
    (dap "<leader>dB" ''require("dap").set_breakpoint(vim.fn.input("Condition: "))'' "Conditional breakpoint")
    (dap "<leader>dL" ''require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: "))'' "Log point")
    (dap "<leader>dc" ''require("dap").continue()'' "Start or continue")
    (dap "<leader>dC" ''require("dap").run_to_cursor()'' "Run to cursor")
    (dap "<leader>di" ''require("dap").step_into()'' "Step into")
    (dap "<leader>dO" ''require("dap").step_over()'' "Step over")
    (dap "<leader>do" ''require("dap").step_out()'' "Step out")
    (dap "<leader>dP" ''require("dap").pause()'' "Pause")
    (dap "<leader>dt" ''require("dap").terminate()'' "Terminate")
    (dap "<leader>dl" ''require("dap").run_last()'' "Run last")
    (dap "<leader>du" ''require("dap-view").toggle()'' "Debug panel")
    (dap "<leader>dw" ''require("dap-view").add_expr()'' "Watch expression under cursor")
    {
      mode = [ "n" "x" ];
      key = "<leader>de";
      action.__raw = ''function() require("lz.n").trigger_load("nvim-dap"); require("dap.ui.widgets").hover() end'';
      options = { desc = "Evaluate"; silent = true; };
    }

    # IntelliJ: F7 into, F8 over, Shift-F8 out, F9 resume,
    # Alt-F9 run to cursor, Ctrl-F8 breakpoint, Ctrl-F2 stop.
    (dap "<F7>" ''require("dap").step_into()'' "Step into")
    (dap "<F8>" ''require("dap").step_over()'' "Step over")
    (dap "<S-F8>" ''require("dap").step_out()'' "Step out")
    (alias "<F20>" ''require("dap").step_out()'')
    (dap "<F9>" ''require("dap").continue()'' "Start or continue")
    (dap "<M-F9>" ''require("dap").run_to_cursor()'' "Run to cursor")
    (alias "<F57>" ''require("dap").run_to_cursor()'')
    (dap "<C-F8>" ''require("dap").toggle_breakpoint()'' "Toggle breakpoint")
    (alias "<F32>" ''require("dap").toggle_breakpoint()'')
    (dap "<C-F2>" ''require("dap").terminate()'' "Terminate")
    (alias "<F26>" ''require("dap").terminate()'')
  ];
}
