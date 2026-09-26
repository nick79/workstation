{ config, lib, pkgs, ... }:

# zsh, prompt, plugins, aliases and functions; see docs/tools/shell.md.
let
  # bat as the man pager. An executable rather than the usual `sh -c` string,
  # which the bat README says breaks with mandoc-based man.
  manPager = pkgs.writeShellScript "bat-man-pager" ''
    ${pkgs.gawk}/bin/awk '{ gsub(/\x1B\[[0-9;]*m/, "", $0); gsub(/.\x08/, "", $0); print }' \
      | ${pkgs.bat}/bin/bat --plain --language=man
  '';
in
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BAT_THEME = "Monokai Extended Light";
    MANPAGER = "${manPager}";
  };

  # uv installs its tools here.
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  programs.zsh = {
    enable = true;

    # Homebrew holds only the declared casks, but `brew` itself must be on
    # PATH (for `ws remove` and activation). Nix is moved back ahead of it by
    # the nix-darwin interactiveShellInit reorder, which runs later, so a
    # command both provide resolves to the Nix copy.
    profileExtra = ''
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv zsh)"
      fi
    '';

    defaultKeymap = "viins";
    autocd = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 100000;
      save = 100000;
      extended = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      findNoDups = true;
      share = true;
    };

    setOptions = [
      "HIST_REDUCE_BLANKS"
      "INTERACTIVE_COMMENTS"
    ];

    autosuggestion.enable = true;

    shellAliases = {
      vim = "nvim";
      reload = "exec zsh";
      path = "print -rl -- $path";
      ports = "lsof -nP -iTCP -sTCP:LISTEN";
      ls = "eza --icons=auto --classify=auto --group-directories-first";
      ll = "eza --all --long --header --git --group --icons=auto --classify=auto --group-directories-first --time-style=long-iso --color-scale=all";
      lt = "eza --tree --level=2 --icons=auto --classify=auto --group-directories-first";
      lg = "lazygit";
    };

    syntaxHighlighting = {
      enable = true;
      styles = {
        path = "none";
        path_prefix = "none";
      };
    };

    initContent = lib.mkMerge [
      # Before compinit (570), so Homebrew's completions are found.
      (lib.mkOrder 560 ''
        KEYTIMEOUT=10

        # Non-login interactive shells (for example opened by an editor)
        # skip .zprofile, so set up Homebrew here too. That runs after the
        # Nix-first reorder in /etc/zshrc, so repeat the reorder.
        if [[ -z "''${HOMEBREW_PREFIX:-}" && -x /opt/homebrew/bin/brew ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv zsh)"
          typeset -U path
          path=( ''${^''${(s: :)NIX_PROFILES}}/bin $path )
        fi
        typeset -g BREW_PREFIX="''${HOMEBREW_PREFIX:-/opt/homebrew}"

        if [[ -d "$BREW_PREFIX/share/zsh/site-functions" ]]; then
          fpath=("$BREW_PREFIX/share/zsh/site-functions" $fpath)
        fi
      '')

      ''
        # No global language version managers: Node, Java and the rest come
        # from each project's dev shell.

        # Make a directory (with parents) and enter it.
        mkcd() {
          mkdir -p -- "$1" && cd -- "$1"
        }
      ''
    ];
  };

  # z <part of a path> jumps to a frequently used directory; zi picks with fzf.
  programs.zoxide.enable = true;

  programs.starship.enable = true;
  # The prompt configuration as a plain file (it contains Nerd Font glyphs).
  xdg.configFile."starship.toml".source = ./starship.toml;
}
