{ lib, pkgs, ... }:

# Claude Code user configuration (docs/tools/claude-code.md).
#
# Shared through this repository:
#   ~/.claude/rules/file-deletion.md   read-only link; loaded for every project
#   ~/.claude/statusline-command.sh    read-only link
#   ~/.claude/skills/personal-writing-style/SKILL.md
#                                      read-only link; the prose style skill
#   ~/.claude/settings.json            only the keys in settings.shared.json,
#                                      merged into the existing file (below)
# Per machine, never touched here: the rest of settings.json (model, theme…),
# ~/.claude/CLAUDE.md (private instructions) and auto memory.
#
# Claude Code itself stays a Homebrew cask (it updates itself). Home Manager's
# programs.claude-code module is not used: it makes settings.json and
# CLAUDE.md read-only, which breaks /model, /config and `#` memories, and it
# installs a second copy of Claude Code.
let
  sharedSettings = ./settings.shared.json;
  jq = lib.getExe pkgs.jq;
in
{
  home.file.".claude/rules/file-deletion.md".source = ./file-deletion.md;

  home.file.".claude/skills/personal-writing-style/SKILL.md".source =
    ./skills/personal-writing-style/SKILL.md;

  home.file.".claude/statusline-command.sh" = {
    source = ./statusline-command.sh;
    executable = true;
  };

  # Merge the shared keys into settings.json without touching anything else:
  # - statusLine is set to the repository's value;
  # - permissions.ask and permissions.deny gain the repository's rules, keeping
  #   the machine's own (the same way Claude Code combines permission lists
  #   across files). deny blocks the commands that print Keychain secrets.
  # An unreadable file is left alone with a warning. Writes go through a
  # temporary file and are skipped when nothing would change.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeSettings="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"

    if [[ ! -e "$claudeSettings" ]]; then
      noteEcho "Creating $claudeSettings with the shared Claude Code settings"
      run install -m 644 ${sharedSettings} "$claudeSettings"
    elif ! ${jq} empty "$claudeSettings" 2>/dev/null; then
      warnEcho "$claudeSettings is not valid JSON; shared Claude Code settings were not merged"
    else
      claudeMerged="$(${jq} --slurpfile shared ${sharedSettings} '
        ($shared[0]) as $s
        | .statusLine = $s.statusLine
        | (.permissions.ask // []) as $ask
        | .permissions.ask = $ask + ($s.permissions.ask - $ask)
        | (.permissions.deny // []) as $deny
        | .permissions.deny = $deny + ($s.permissions.deny - $deny)
      ' "$claudeSettings")"

      if [[ "$(${jq} -S . "$claudeSettings")" == "$(printf '%s' "$claudeMerged" | ${jq} -S .)" ]]; then
        verboseEcho "$claudeSettings already contains the shared settings"
      elif [[ -v DRY_RUN ]]; then
        noteEcho "Would merge shared settings into $claudeSettings"
      else
        noteEcho "Merging shared settings into $claudeSettings"
        claudeTmp="$(mktemp "$claudeSettings.XXXXXX")"
        printf '%s\n' "$claudeMerged" > "$claudeTmp"
        chmod 644 "$claudeTmp"
        run mv "$claudeTmp" "$claudeSettings"
      fi
    fi
  '';
}
