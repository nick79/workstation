{ config, ... }:

# The Mac's one user, named by the host file (system.primaryUser). Every home
# path derives from that name, so hosts with different accounts share this.
let
  user = config.system.primaryUser;
  home = "/Users/${user}";
in
{
  users.users.${user}.home = home;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Existing unmanaged regular files are renamed to *.before-nix instead of
  # blocking activation. Symlinks are not: a link Home Manager does not own
  # must be moved aside by hand first.
  home-manager.backupFileExtension = "before-nix";

  home-manager.users.${user} = {
    imports = [ ../home ];
    home.username = user;
    home.homeDirectory = home;
  };
}
