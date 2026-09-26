{ pkgs, ... }:

# ws: workstation maintenance command (docs/tools/ws.md).
# writeShellApplication runs shellcheck on the script at build time.
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "ws";
      runtimeInputs = [ pkgs.nvd pkgs.jq pkgs.git ];
      text = builtins.readFile ./ws.sh;
    })
  ];

  programs.zsh.initContent = ''
    _ws() {
      _arguments '1:command:(help status list check build switch update rollback brew tools remove upgrade gc)'
    }
    compdef _ws ws
  '';
}
