{ ... }:

{
  imports = [ ../../modules/darwin ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "shusann";
  users.users.shusann.home = "/Users/shusann";
}
