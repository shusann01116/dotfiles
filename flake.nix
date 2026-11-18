{
  description = "shusann's dotfiles (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
    };
  };

  outputs =
    { nixpkgs, nix-darwin, home-manager, ... } @ inputs:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      allSystems = [ darwinSystem ] ++ linuxSystems;

      mkHome = system: extraModules: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./modules/home ] ++ extraModules;
      };
    in
    {
      formatter = nixpkgs.lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      darwinConfigurations."shusann-mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/shusann-mac
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.shusann.imports = [
              ./modules/home
              ./modules/home/darwin.nix
            ];
          }
        ];
      };

      homeConfigurations = {
        # No-sudo fallback for this Mac.
        "shusann" = mkHome darwinSystem [ ./modules/home/darwin.nix ];
      }
      # Linux / WSL (standalone home-manager): "shusann@x86_64-linux", "shusann@aarch64-linux".
      // builtins.listToAttrs (map
        (system: nixpkgs.lib.nameValuePair "shusann@${system}" (mkHome system [ ./modules/home/linux.nix ]))
        linuxSystems);
    };
}
