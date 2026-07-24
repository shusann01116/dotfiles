{ ... }:

{
  # Nix itself (daemon, /etc/nix/nix.conf, GC) is owned by Determinate Nix.
  # nix-darwin must not touch it, or the first switch fails on the existing install.
  nix.enable = false;

  system.stateVersion = 6;
}
