{ ... }:

# PHP: phpactor (free) from the editor. Formatters come from the project's
# vendor/bin: pint (Laravel) if installed, else php-cs-fixer. pint.json or a
# .php-cs-fixer config turns format on save on (formatting.nix).
{
  lsp.servers.phpactor.enable = true;

  plugins.conform-nvim.settings.formatters_by_ft.php.__raw =
    ''{ "pint", "php_cs_fixer", stop_after_first = true }'';
}
