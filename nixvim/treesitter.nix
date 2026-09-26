{ ... }:

# Treesitter: syntax highlighting, indentation and folding from real syntax
# trees, every grammar built by Nix (nothing compiled at runtime), plus
# syntax-aware text objects and motions.
let
  # ]f / [f etc. for the textobjects plugin (main branch: keymaps are ours).
  move = key: fn: query: desc: {
    mode = [ "n" "x" "o" ];
    inherit key;
    action.__raw = ''
      function()
        -- In diff mode ]c / [c keep their built-in meaning (next change).
        if vim.wo.diff and ("${key}"):find("[cC]") then
          return vim.cmd.normal({ "${key}", bang = true })
        end
        require("nvim-treesitter-textobjects.move").${fn}("${query}", "textobjects")
      end
    '';
    options = { inherit desc; silent = true; };
  };
in
{
  plugins.treesitter = {
    enable = true;
    # grammarPackages defaults to all grammars nixpkgs builds for this
    # nvim-treesitter (about 320), so any file type highlights without setup.
    highlight.enable = true;
    indent.enable = true;
    folding.enable = true;
  };

  # Folds come from Treesitter but start open; zc / zo / za / zR / zM as usual.
  opts = {
    foldlevel = 99;
    foldtext = ""; # show the folded line itself, highlighted
  };

  plugins.treesitter-textobjects.enable = true;

  # The function, class or parameter the cursor is in, pinned at the top of
  # the window while scrolling through it.
  plugins.treesitter-context = {
    enable = true;
    settings = {
      max_lines = 3;
      multiline_threshold = 1;
    };
  };

  # Text objects: mini.ai extends a/i with Treesitter-aware and extra targets
  # (docs/tools/neovim.md lists them); built-ins like aw, ip, a" keep working.
  plugins.mini-ai = {
    enable = true;
    settings = {
      n_lines = 500;
      custom_textobjects = {
        f.__raw = ''require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })'';
        c.__raw = ''require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })'';
        o.__raw = ''
          require("mini.ai").gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          })
        '';
        t = [ "<([%p%w]-)%f[^<%w][^<]->.-</%1>" "^<.->().*()</[^/]->$" ]; # HTML/XML tag
        d = [ "%f[%d]%d+" ]; # digits
        u.__raw = ''require("mini.ai").gen_spec.function_call()'';
        U.__raw = ''require("mini.ai").gen_spec.function_call({ name_pattern = "[%w_]" })'';
        # g = the whole buffer (ag), without leading/trailing blank lines (ig).
        g.__raw = ''
          function(ai_type)
            local start_line, end_line = 1, vim.fn.line("$")
            if ai_type == "i" then
              local first = vim.fn.nextnonblank(start_line)
              local last = vim.fn.prevnonblank(end_line)
              if first == 0 or last == 0 then return { from = { line = start_line, col = 1 } } end
              start_line, end_line = first, last
            end
            local to_col = math.max(vim.fn.getline(end_line):len(), 1)
            return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
          end
        '';
      };
    };
  };

  # No ]a / [a for parameters: those are Neovim's argument-list keys.
  keymaps = [
    (move "]f" "goto_next_start" "@function.outer" "Next function start")
    (move "]F" "goto_next_end" "@function.outer" "Next function end")
    (move "[f" "goto_previous_start" "@function.outer" "Previous function start")
    (move "[F" "goto_previous_end" "@function.outer" "Previous function end")
    (move "]c" "goto_next_start" "@class.outer" "Next class start")
    (move "]C" "goto_next_end" "@class.outer" "Next class end")
    (move "[c" "goto_previous_start" "@class.outer" "Previous class start")
    (move "[C" "goto_previous_end" "@class.outer" "Previous class end")
  ];

  extraConfigLua = ''
    Snacks.toggle({
      name = "Sticky context",
      get = function() return require("treesitter-context").enabled() end,
      set = function(on) require("treesitter-context")[on and "enable" or "disable"]() end,
    }):map("<leader>ut")
  '';
}
