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
    in
    {
      formatter.${darwinSystem} = nixpkgs.legacyPackages.${darwinSystem}.nixpkgs-fmt;

      darwinConfigurations."shusann-mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/shusann-mac
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.shusann.imports = [
              ./modules/home
              ./modules/home/darwin.nix
            ];
          }
        ];
      };

      # No-sudo fallback for this Mac. A WSL variant (x86_64-linux +
      # modules/home/linux.nix) is added when a WSL host exists.
      homeConfigurations."shusann" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${darwinSystem};
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./modules/home
          ./modules/home/darwin.nix
        ];
      };
    };
}
