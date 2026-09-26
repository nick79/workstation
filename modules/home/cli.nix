{ pkgs, ... }:

# Core CLI tools (docs/tools/cli.md).
{
  home.packages = [
    pkgs.bat
    pkgs.eza
    pkgs.fd
    pkgs.ripgrep
    pkgs.jq
    pkgs.wget

    pkgs.typst
    pkgs.yq-go # mikefarah's yq; nixpkgs `yq` is a different (Python) tool
    pkgs.lazydocker
    pkgs.lazysql

    # GitHub CLI. A plain package rather than programs.gh: gh writes its own
    # ~/.config/gh/config.yml on login and `gh config set`, and keeps the
    # token in the macOS Keychain.
    pkgs.gh

    # Python's one global tool. uv installs the interpreters, virtual
    # environments and packages; its tools and Pythons live in
    # ~/.local, independent of this binary.
    pkgs.uv
  ];

  # Ctrl-R history, Ctrl-T files, **<Tab> completion (runs `fzf --zsh`).
  programs.fzf.enable = true;

  # Per-project environments: entering a directory with an .envrc loads that
  # project's Nix dev shell. nix-direnv caches the shell and keeps it from
  # being garbage-collected. See docs/tools/direnv.md.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Keep "direnv: loading", drop the long list of exported variables.
    config.global.hide_env_diff = true;
  };
}
