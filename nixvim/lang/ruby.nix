{ ... }:

# Ruby (Rails, Sinatra, Padrino): ruby-lsp, with rubocop or standard as its
# linter and formatter. All of them must run under the project's Ruby and
# bundle, so they come from the project's Gemfile (docs/tools/projects.md),
# not from the editor. A .rubocop.yml or .standard.yml turns format on
# save on (formatting.nix).
{
  lsp.servers.ruby_lsp = {
    enable = true;
    package = null;
    config.init_options = {
      formatter = "auto";
      linters = [ "rubocop" ];
    };
  };
}
