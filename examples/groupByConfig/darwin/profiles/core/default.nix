{ config, lib, pkgs, ... }:

{
  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;
  services.nix-daemon.enable = true;
  users.nix.configureBuildUsers = true;

  environment.systemPackages = with pkgs; [
    coreutils
    curl
    direnv
    git
    gnupg
    gnused
    gnutar
    mas
    wget
  ];

  # Because sometimes we must
  homebrew = {
    enable = true;
    autoUpdate = true;
    global.noLock = true;
  };
}
