{ pkgs, ... }:

# Containers: Colima, Lima, the Docker CLI and its Compose and Buildx
# plugins, installed only. Provisioning creates no VM, passes no sizing flags
# and starts nothing: a project that needs more than Colima's defaults starts
# its own named profile. VM state stays in ~/.colima, outside Nix.
let
  # nixpkgs wraps both Lima and Colima with QEMU (2.3 GiB) and Colima with a
  # Lima carrying every guest agent. VMs here use Apple's vz, which needs
  # neither; `--vm-type qemu` and non-native architectures are not supported
  # by this build. An empty stand-in keeps the wrappers' PATH entries valid.
  noQemu = pkgs.runCommand "no-qemu" { } "mkdir -p $out/bin";
  lima = pkgs.lima.override { qemu = noQemu; };
  colima = pkgs.colima.override {
    lima-full = lima;
    qemu = noQemu;
  };
in
{
  home.packages = [
    colima
    lima
    pkgs.docker-client
    pkgs.docker-compose
    pkgs.docker-buildx
  ];

  # `docker compose` and `docker buildx` find their plugins here.
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";
}
