{ ... }:

# Lazy loading, for plugins heavy enough to push startup past about 100 ms.
# lz.n loads a plugin marked `lazyLoad` on its trigger (a command, file type
# or event, declared next to the plugin) and then runs its setup.
#
# Keys and code that use a lazy plugin must load it through lz.n first:
#   require("lz.n").trigger_load("nvim-dap")
# A bare require("dap") would still work, because Neovim finds Lua modules in
# optional plugins, but it skips the plugin's setup (signs, adapters, panel).
# That is also why lzn-auto-require is not used: it only acts when a plain
# require fails, which never happens here.
#
# Lazy: nvim-dap, nvim-dap-view, neotest, claudecode, bufferline,
# render-markdown, crates.nvim. Everything else loads at startup; see
# "How the editor is built" in docs/tools/neovim.md.
{
  plugins.lz-n.enable = true;
}
