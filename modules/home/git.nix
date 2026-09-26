{ config, lib, pkgs, ... }:

# Git, lazygit, ec, delta and the gitleaks pre-commit scan; see
# docs/tools/git.md.
let
  # ec 0.4.2 hardcodes chroma's "github-dark" syntax style, whose plain
  # identifiers are near-white and unreadable on the light Ghostty theme. A
  # local build switches it to the light "github" style, which leaves plain
  # identifiers in the terminal's own text colour. Only this configuration
  # uses the patched build; nixpkgs is untouched. --replace-fail makes the
  # build fail loudly if an ec update changes that line.
  ec = pkgs.ec.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace internal/tui/diff_syntax.go \
        --replace-fail 'styles.Get("github-dark")' 'styles.Get("github")'
    '';
    # These upstream tests pin github-dark's exact colours, so they fail by
    # design with the light style. The rest of ec's test suite still runs.
    checkFlags = (old.checkFlags or [ ]) ++ [
      "-skip=^(TestConflictSyntaxRenderingPreservesDecisionUndoRedoAndSaveBytes|TestConflictSyntaxRefreshesAfterEditorReloadWithoutLosingUndoHistory|TestConflictViewHighlightsAllPanes|TestConflictSyntaxSeparatesDeletedBaseAndSkipsUIRows|TestConflictResultTextHasNoUnderlineOrDimming|TestConflictSyntaxCacheKeepsCurrentChangeStyle|TestHighlightDiffCodePreservesLinesAndDiffBackgrounds)$"
    ];
  });

  # ec's interface colours, from Ghostty's "Monokai Pro Light Sun" palette.
  # ec's own defaults are all dark.
  ecTheme =
    let
      fg = "#2c232e";
      muted = "#72696d";
      grey = "#a59c9c";
      panel = "#ebe1d8";
      red = "#ce4770";
      green = "#218871";
      yellow = "#b16803";
      orange = "#d4572b";
      purple = "#6851a2";
      blue = "#2473b6";
    in
    {
      default = "monokai-pro-light-sun";
      themes.monokai-pro-light-sun = {
        title_fg = fg;
        pane_border = grey;
        selected_pane_border = blue;
        side_pane_border = grey;
        selected_side_border = blue;
        header_bg = panel;
        header_fg = fg;
        footer_bg = panel;
        footer_fg = muted;
        line_number = grey;
        ours_highlight_bg = "#d9e6f2";
        ours_highlight_fg = fg;
        theirs_highlight_bg = "#e6dff0";
        theirs_highlight_fg = fg;
        result_fg = fg;
        result_highlight_bg = "#efe3c8";
        result_highlight_fg = fg;
        modified_bg = "#d9e6f2";
        modified_fg = fg;
        added_bg = "#d7ece3";
        added_fg = green;
        removed_bg = "#f4dbe2";
        removed_fg = red;
        diff_hunk_bg = "#e3ebf3";
        diff_hunk_fg = blue;
        conflicted_bg = "#f4dbe2";
        conflicted_fg = fg;
        insert_marker_fg = red;
        selected_hunk_marker_fg = blue;
        selected_hunk_marker_bg = panel;
        selected_hunk_bg = "#e6ddd3";
        status_resolved_fg = green;
        status_unresolved_fg = yellow;
        result_resolved_marker_fg = green;
        result_resolved_border = grey;
        result_unresolved_border = grey;
        toast_bg = green;
        toast_fg = "#f8efe7";
        selector_resolved_fg = green;
        selector_unresolved_fg = red;
        file_status_modified_fg = yellow;
        file_status_untracked_fg = purple;
        file_status_added_fg = green;
        file_status_deleted_fg = red;
        file_status_renamed_fg = blue;
        file_status_conflicted_fg = orange;
        dim_foreground_muted = grey;
      };
    };

  # Per-machine identity, never in this public repository. Each machine
  # fills it in once:  git config --file ~/.config/git/local user.email <address>
  localConfig = "${config.xdg.configHome}/git/local";

  # Shared gitleaks rules for every repository without its own .gitleaks.toml:
  # gitleaks' default rules, plus any exception that should hold
  # everywhere. None is needed yet; repository-specific exceptions belong in
  # that repository (.gitleaks.toml, .gitleaksignore or a gitleaks:allow
  # comment on the line).
  gitleaksConfig = pkgs.writeText "gitleaks-workstation.toml" ''
    title = "Workstation defaults"

    [extend]
    useDefault = true
  '';

  # Pre-commit secret scan for every repository. Registered as a
  # config-based hook (Git 2.54+), so it runs in addition to a repository's
  # own pre-commit hook, also where core.hooksPath points elsewhere. Only the
  # staged changes are scanned, redacted; it is silent when nothing is found.
  gitleaksHook = pkgs.writeShellApplication {
    name = "gitleaks-pre-commit";
    runtimeInputs = [ pkgs.gitleaks pkgs.git ];
    text = ''
      if [[ ",''${SKIP:-}," == *,gitleaks,* ]]; then
        echo "gitleaks: skipped for this commit (SKIP=gitleaks)" >&2
        exit 0
      fi

      top="$(git rev-parse --show-toplevel)"
      config=()
      # A repository's own .gitleaks.toml (or GITLEAKS_CONFIG) takes precedence.
      if [[ ! -f "$top/.gitleaks.toml" && -z "''${GITLEAKS_CONFIG:-}''${GITLEAKS_CONFIG_TOML:-}" ]]; then
        config=(--config ${gitleaksConfig})
      fi

      status=0
      gitleaks git --pre-commit --staged --redact --no-banner --verbose \
        --log-level warn "''${config[@]}" "$top" || status=$?

      if (( status != 0 )); then
        cat >&2 <<'EOF'

      gitleaks stopped this commit: the staged changes look like they contain
      a secret (shown redacted above). Remove it and commit again. If it is a
      false positive:
        - add  gitleaks:allow  in a comment on that line, or
        - add the Fingerprint above to .gitleaksignore in the repository, or
        - skip once:  SKIP=gitleaks git commit ...
      EOF
      fi
      exit "$status"
    '';
  };
in
{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Milan Nikic";
      # With no email configured, refuse to commit instead of guessing one
      # from the host name.
      user.useConfigOnly = true;

      init.defaultBranch = "main";

      # Conflict markers also show the common ancestor, which makes most
      # conflicts readable in lazygit's own view.
      merge.conflictStyle = "zdiff3";

      # `git mergetool` (and lazygit's M > "Open external merge tool") opens ec.
      merge.tool = "ec";
      mergetool = {
        ec.cmd = ''ec "$BASE" "$LOCAL" "$REMOTE" "$MERGED"'';
        ec.trustExitCode = true;
        # Do not leave *.orig copies behind after a resolved merge.
        keepBackup = false;
      };

      # Secret scan before every commit. Turn it off for one
      # repository with:  git config hook.gitleaks.enabled false
      hook.gitleaks = {
        event = "pre-commit";
        command = lib.getExe gitleaksHook;
      };
    };

    includes = [ { path = localConfig; } ];

    ignores = [
      # macOS metadata
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"
      # Machine-local Claude configuration
      "**/.claude/settings.local.json"
      # direnv / nix-direnv per-project cache
      ".direnv/"
    ];
  };

  # delta renders `git diff`, `git show`, `git log -p` and `git blame`.
  # Light terminal theme, so the light variant and bat's matching theme.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      light = true;
      syntax-theme = "Monokai Extended Light";
      line-numbers = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      os.editPreset = "nvim";
      # delta for diffs inside lazygit; --paging=never is required there.
      git.diffRenderers = [
        { command = "delta --light --paging=never"; }
      ];
    };
  };

  # gitleaks itself too, for the full-history scans in docs/tools/git.md.
  home.packages = [ ec pkgs.gitleaks ];

  # ec reads its theme from os.UserConfigDir(), i.e. ~/Library/Application Support.
  home.file."Library/Application Support/ec/themes.json".text = builtins.toJSON ecTheme;
}
