{
  description = "Home Manager configuration of shusann";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... } @ inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      homeConfigurations."shusann" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./package/nix/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
}
