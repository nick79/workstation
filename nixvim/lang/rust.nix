{ ... }:

# Rust: rustaceanvim drives rust-analyzer, which comes from the project's
# toolchain together with rustfmt, clippy and cargo: its version must
# match the compiler, so the editor ships none. Apple's lldb-dap debugs
# (lang/c.nix).
# Cargo.toml turns format on save on (formatting.nix); rustfmt runs through
# rust-analyzer.
{
  plugins.rustaceanvim = {
    enable = true;
    settings = {
      # rustaceanvim adds the project's debuggables to nvim-dap right after
      # this, and its test commands call neotest: both must be set up
      # through lz.n first, or NixVim's dap setup later replaces
      # dap.configurations and drops the Rust entries.
      server.on_attach.__raw = ''
        function()
          require("lz.n").trigger_load("nvim-dap")
          require("lz.n").trigger_load("neotest")
        end
      '';
      server.default_settings.rust-analyzer = {
        check.command = "clippy";
        cargo.allFeatures = true;
        procMacro.enable = true;
      };
      tools.test_executor = "neotest";
      # Apple's lldb-dap, as for C (lang/c.nix explains why not codelldb).
      # Raw: NixVim types `args` as a string.
      dap.adapter.__raw = ''{ type = "executable", command = "xcrun", args = { "lldb-dap" }, name = "lldb" }'';
      # rustaceanvim defaults lldb-dap to an integrated terminal, whose
      # launcher timed out; program output goes to dap-view's console.
      dap.configuration.__raw = ''
        { name = "Rust debug client", type = "lldb", request = "launch", stopOnEntry = false, console = "internalConsole" }
      '';
    };
  };

  # rust-analyzer from the project shell, not the editor closure.
  dependencies.rust-analyzer.enable = false;

  # Tests run through rustaceanvim's own neotest adapter (cargo test,
  # or cargo-nextest when the project has it).
  plugins.neotest.settings.adapters = [ "require('rustaceanvim.neotest')" ];

  # Cargo.toml: versions, features and updates inline; completion and
  # actions through its in-process language server. It asks crates.io.
  plugins.crates = {
    enable = true;
    lazyLoad.settings.event = "BufRead Cargo.toml";
    settings = {
      lsp = {
        enabled = true;
        actions = true;
        completion = true;
        hover = true;
      };
      completion.crates.enabled = true;
    };
  };
}
