{
  description = "macOS workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nix-darwin, home-manager, nixvim, ... }:
    let
      # One configuration per Mac, from hosts/<name>. The name is only a label
      # and need not be the Mac's host name (the work Mac is `work`).
      # Activation records it in /etc/workstation-host, where ws, Neovim and
      # later bootstrap runs look it up.
      mkHost = name: nix-darwin.lib.darwinSystem {
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          # Makes `programs.nixvim` available to every Home Manager user.
          # NixVim builds from the global pkgs (useGlobalPkgs), so `source` is
          # unused; setting it to our nixpkgs only silences NixVim's warning
          # about `inputs.nixvim.inputs.nixpkgs.follows`.
          {
            home-manager.sharedModules = [
              nixvim.homeModules.nixvim
              { programs.nixvim.nixpkgs.source = nixpkgs; }
            ];
          }
          { environment.etc."workstation-host".text = "${name}\n"; }
          ./hosts/${name}
        ];
      };
    in
    {
      packages.aarch64-darwin.darwin-rebuild = nix-darwin.packages.aarch64-darwin.darwin-rebuild;

      darwinConfigurations.personal = mkHost "personal";
    };
}
