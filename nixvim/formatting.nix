{ pkgs, ... }:

# Formatting with conform.nvim. Formatters per file type are declared in
# ./lang; files types without one fall back to the language server.
#
# Format on save is opt-in per project: reformatting existing code on the
# first save produces diffs nobody asked for. It runs when, in order of
# precedence,
#   1. `Space u F` set it for this buffer (vim.b.autoformat), or
#   2. `Space u f`, or a trusted project .nvim.lua, set vim.g.autoformat, or
#   3. the project has a formatter configuration file (list below), or a
#      [tool.ruff] or [tool.rumdl] section in pyproject.toml, or the file is
#      Go or Rust in a project with a go.mod or Cargo.toml, or Terraform.
# `Space c f` formats by hand at any time.
{
  # Project-local .nvim.lua / .nvimrc / .exrc. Neovim asks once per file and
  # remembers the answer (:help 'exrc', :trust).
  opts.exrc = true;

  plugins.conform-nvim = {
    enable = true;
    settings = {
      default_format_opts.lsp_format = "fallback";
      notify_no_formatters = true;
      format_on_save.__raw = ''
        function(buf)
          if not _G.workstation_autoformat(buf) then return end
          return { timeout_ms = 1000 }
        end
      '';
      # prettierd only where the project configures prettier.
      formatters.prettierd.condition.__raw = ''
        function(_, ctx)
          return vim.fs.root(ctx.dirname, {
            ".prettierrc", ".prettierrc.json", ".prettierrc.yaml", ".prettierrc.yml",
            ".prettierrc.json5", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs",
            ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs",
            "prettier.config.mjs", "prettier.config.ts",
          }) ~= nil
        end
      '';
    };
  };

  extraPackages = [ pkgs.prettierd ];

  # Defined before plugins load so format_on_save can call it.
  extraConfigLuaPre = ''
    -- Files whose presence means the project wants its code formatted.
    local format_markers = {
      "stylua.toml", ".stylua.toml",
      ".prettierrc", ".prettierrc.json", ".prettierrc.yaml", ".prettierrc.yml",
      ".prettierrc.json5", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs",
      ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs",
      "prettier.config.mjs", "prettier.config.ts",
      "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc",
      "ruff.toml", ".ruff.toml",
      "rustfmt.toml", ".rustfmt.toml",
      ".clang-format",
      "treefmt.toml", ".treefmt.toml",
      "rumdl.toml", ".rumdl.toml",
      "tombi.toml",
      ".rubocop.yml", ".standard.yml",
      "pint.json", ".php-cs-fixer.php", ".php-cs-fixer.dist.php",
      ".formatter.exs",
      ".sql-formatter.json",
    }

    -- gofmt and rustfmt are near-universal, so the project file counts, but
    -- only for that language's own files: a README or script in a Go or Rust
    -- repository is left alone.
    local language_markers = {
      go = { "go.mod" }, gomod = { "go.mod" }, gowork = { "go.mod", "go.work" },
      rust = { "Cargo.toml" },
    }
    -- Terraform: `terraform fmt` has no config file, so .tf files always count.
    local always_format = { terraform = true, ["terraform-vars"] = true }

    -- Tool sections in pyproject.toml count too: Python projects keep all
    -- their configuration there.
    local pyproject_sections = { "^%[tool%.ruff[%].]", "^%[tool%.rumdl[%].]" }

    local function pyproject_opts_in(name)
      local root = vim.fs.root(name, "pyproject.toml")
      if not root then return false end
      for line in io.lines(root .. "/pyproject.toml") do
        for _, pattern in ipairs(pyproject_sections) do
          if line:find(pattern) then return true end
        end
      end
      return false
    end

    function _G.workstation_autoformat(buf)
      buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
      if vim.b[buf].autoformat ~= nil then return vim.b[buf].autoformat end
      if vim.g.autoformat ~= nil then return vim.g.autoformat end
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then return false end
      if always_format[vim.bo[buf].filetype] then return true end
      local own = language_markers[vim.bo[buf].filetype]
      if own and vim.fs.root(name, own) then return true end
      return vim.fs.root(name, format_markers) ~= nil or pyproject_opts_in(name)
    end
  '';

  keymaps = [
    {
      mode = [ "n" "x" ];
      key = "<leader>cf";
      action.__raw = ''function() require("conform").format({ async = true }) end'';
      options = { desc = "Format"; silent = true; };
    }
  ];

  extraConfigLua = ''
    Snacks.toggle({
      name = "Format on save (all buffers)",
      get = function()
        local saved = vim.b.autoformat
        vim.b.autoformat = nil
        local on = _G.workstation_autoformat(0)
        vim.b.autoformat = saved
        return on
      end,
      set = function(on) vim.g.autoformat = on end,
    }):map("<leader>uf")
    Snacks.toggle({
      name = "Format on save (this buffer)",
      get = function() return _G.workstation_autoformat(0) end,
      set = function(on) vim.b.autoformat = on end,
    }):map("<leader>uF")
  '';
}
