{ pkgs, ... }:

# Java and Spring: jdtls through nvim-jdtls, with Lombok, the
# java-debug and java-test bundles, and the Spring Boot language server.
#
# Two JDKs: jdtls and the Spring Boot server run on the JDK baked into the
# editor closure (nixpkgs' jdtls launcher hardcodes it); the project is
# compiled and analysed against its own JDK, which comes from the project
# shell as JAVA_HOME (docs/tools/projects.md).
let
  jdk = pkgs.jdk21; # the same Zulu 21 the jdtls launcher uses
  springBootLs = pkgs.callPackage ../pkgs/spring-boot-ls.nix { };
  lombokJar = "${pkgs.lombok}/share/java/lombok.jar";
  debugDir = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server";
  testDir = "${pkgs.callPackage ../pkgs/java-test.nix { }}/share/java-test";

in
{
  # jdtls configured directly, like every other server. NixVim's jdtls plugin
  # module is not used: it fixes `cmd` to a plain list, and Lombok plus a
  # per-project workspace need a function. nvim-jdtls hooks itself in when a
  # client named jdtls attaches (debugging, tests, jdt:// class files).
  # nixpkgs gives nvim-jdtls python3 as a runtime dependency (one helper
  # hashes a path with it). It lands at the end of Neovim's PATH, behind any
  # .venv and /usr/bin/python3, and Nix's Git already has it in the closure,
  # so it stays: a known exception to "no nixpkgs Python in the editor".
  extraPlugins = [ pkgs.vimPlugins.nvim-jdtls ];
  # nvim-jdtls and nvim-lspconfig both ship lsp/jdtls.lua; kept apart so the
  # plugin pack builds. The settings below do not depend on which one loads.
  performance.combinePlugins.standalonePlugins = [ pkgs.vimPlugins.nvim-jdtls ];

  lsp.servers.jdtls = {
    enable = true;
    config = {
      # lspconfig's default command, plus Lombok, and a workspace directory
      # per project path (not just per directory name, which can collide).
      cmd.__raw = ''
        function(dispatchers, config)
          local root = config.root_dir or vim.uv.cwd()
          local data = vim.fn.stdpath("cache") .. "/jdtls/workspace/"
            .. vim.fn.fnamemodify(root, ":t") .. "-" .. vim.fn.sha256(root):sub(1, 8)
          return vim.lsp.rpc.start({
            "jdtls", "-data", data, "--jvm-arg=-javaagent:${lombokJar}",
          }, dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env })
        end
      '';

      # Filled in when jdtls starts, not at every Neovim startup: nvim-jdtls'
      # client capabilities (jdt:// class files, progress, ...) and the
      # bundles loaded into jdtls (debugger, JUnit runner, Spring extensions).
      before_init.__raw = ''
        function(params)
          -- nvim-jdtls registers its Java debug adapter on attach; nvim-dap
          -- must be set up through lz.n by then (nixvim/lazy.nix).
          require("lz.n").trigger_load("nvim-dap")
          local bundles = { vim.fn.glob("${debugDir}/com.microsoft.java.debug.plugin-*.jar", true) }
          for _, jar in ipairs(vim.split(vim.fn.glob("${testDir}/*.jar", true), "\n")) do
            -- These two are run by the test launcher, not loaded into jdtls.
            if not jar:find("runner%-jar%-with%-dependencies") and not jar:find("jacocoagent") then
              table.insert(bundles, jar)
            end
          end
          vim.list_extend(bundles, require("spring_boot").java_extensions("${springBootLs}/share/spring-boot-ls/jars"))
          params.initializationOptions = vim.tbl_deep_extend("force", params.initializationOptions or {}, {
            bundles = bundles,
            extendedClientCapabilities = require("jdtls.capabilities"),
          })
        end
      '';

      settings.java = {
        # Browse library sources, or decompiled classes where there are none.
        eclipse.downloadSources = true;
        maven.downloadSources = true;
        contentProvider.preferred = "fernflower";
        references.includeDecompiledSources = true;
        signatureHelp.enabled = true;
        inlayHints.parameterNames.enabled = "literals"; # Space u h
        sources.organizeImports = {
          starThreshold = 9999;
          staticStarThreshold = 9999;
        };
      };

      # The project's JDK (JAVA_HOME from direnv) becomes the default runtime,
      # so code is analysed against the version the project builds with.
      on_init.__raw = ''
        function(client)
          local home = vim.env.JAVA_HOME
          if not home or home == "" then return end
          local release = io.open(home .. "/release")
          if not release then return end
          local text = release:read("*a")
          release:close()
          local version = text:match('JAVA_VERSION="([%d%.]+)"')
          if not version then return end
          local major = version:match("^1%.(%d+)") or version:match("^(%d+)")
          local name = tonumber(major) <= 8 and ("JavaSE-1." .. major) or ("JavaSE-" .. major)
          client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
            java = { configuration = { runtimes = { { name = name, path = home, default = true } } } },
          })
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end
      '';
    };
  };

  # Spring Boot language server: application.properties/yml completion and
  # validation, @Value navigation, bean and endpoint hints. Starts with Java
  # files in a Spring project.
  plugins.spring-boot = {
    enable = true;
    settings = {
      ls_path = "${springBootLs}/share/spring-boot-ls/language-server/language-server.jar";
      java_cmd = "${jdk}/bin/java";
      log_file.__raw = ''vim.fn.stdpath("state") .. "/spring-boot-ls.log"'';
    };
  };

  # Java-only keys, set when jdtls attaches. In Java buffers `Space t r`,
  # `t t` and `t d` run JUnit through jdtls (neotest has no Java adapter
  # here: neotest-java downloads a JUnit jar at runtime, and every editor
  # tool comes from Nix instead).
  autoCmd = [
    {
      desc = "Java: jdtls keys";
      event = "LspAttach";
      callback.__raw = ''
        function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client or client.name ~= "jdtls" then return end
          local jdtls = require("jdtls")
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc, silent = true })
          end
          map("n", "<leader>co", jdtls.organize_imports, "Organise imports")
          map({ "n", "x" }, "<leader>cxv", function() jdtls.extract_variable_all(vim.fn.mode() ~= "n") end, "Extract variable")
          map({ "n", "x" }, "<leader>cxc", function() jdtls.extract_constant(vim.fn.mode() ~= "n") end, "Extract constant")
          map("x", "<leader>cxm", function() jdtls.extract_method(true) end, "Extract method")
          map("n", "<leader>cs", jdtls.super_implementation, "Go to super implementation")
          map("n", "<leader>tr", function() jdtls.test_nearest_method({ config_overrides = { noDebug = true } }) end, "Run nearest test")
          map("n", "<leader>tt", function() jdtls.test_class({ config_overrides = { noDebug = true } }) end, "Run test class")
          map("n", "<leader>td", jdtls.test_nearest_method, "Debug nearest test")
          map("n", "<leader>tD", jdtls.test_class, "Debug test class")
          map("n", "<leader>tp", jdtls.pick_test, "Pick a test to run")
        end
      '';
    }
  ];

  plugins.which-key.settings.spec = [
    { __unkeyed-1 = "<leader>cx"; group = "extract"; mode = [ "n" "x" ]; }
  ];
}
