{ ... }:

# C and C++: clangd (with clang-format and clang-tidy built in) from Nix.
# Projects are usually built with Apple's clang; --query-driver lets clangd
# ask that compiler for its SDK include paths. A compile_commands.json
# (CMake: -DCMAKE_EXPORT_COMPILE_COMMANDS=ON; Make: bear) tells clangd the
# flags. Formatting follows the project's .clang-format, which also turns
# format on save on (formatting.nix).
#
# Debugging for C, C++ and Rust: Apple's lldb-dap from the Command Line
# Tools, through xcrun. nixpkgs' LLDB 21, and codelldb built on it, crash
# with SIGBUS on macOS 27 as soon as they load a program's debug info;
# Apple's LLDB works.
{
  lsp.servers.clangd = {
    enable = true;
    config = {
      cmd = [
        "clangd"
        "--background-index"
        "--clang-tidy"
        "--header-insertion=iwyu"
        "--completion-style=detailed"
        "--function-arg-placeholders"
        "--fallback-style=llvm"
        "--query-driver=/usr/bin/clang,/usr/bin/clang++,/usr/bin/cc,/usr/bin/c++,/Library/Developer/CommandLineTools/usr/bin/*,/Applications/Xcode*.app/Contents/Developer/Toolchains/*/usr/bin/*,/nix/store/*/bin/*"
      ];
      init_options = {
        usePlaceholders = true;
        completeUnimported = true;
        clangdFileStatus = true;
      };
    };
  };

  plugins.dap = {
    adapters.executables.lldb = {
      command = "xcrun";
      args = [ "lldb-dap" ];
    };
    configurations =
      let
        launch = [
          {
            name = "Launch";
            type = "lldb";
            request = "launch";
            program.__raw = ''
              function()
                return vim.fn.input("Program: ", vim.fn.getcwd() .. "/", "file")
              end
            '';
            args.__raw = ''
              function()
                return vim.split(vim.fn.input("Arguments: "), " ", { trimempty = true })
              end
            '';
            cwd = "\${workspaceFolder}";
            stopOnEntry = false;
          }
          {
            name = "Attach to process";
            type = "lldb";
            request = "attach";
            pid.__raw = ''require("dap.utils").pick_process'';
            cwd = "\${workspaceFolder}";
          }
        ];
      in
      {
        c = launch;
        cpp = launch;
      };
  };

  # Only in buffers clangd is attached to.
  lsp.luaConfig.content = ''
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("workstation_clangd_keys", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "clangd" then
          vim.keymap.set("n", "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>",
            { buffer = ev.buf, desc = "Switch source/header" })
        end
      end,
    })
  '';
}
