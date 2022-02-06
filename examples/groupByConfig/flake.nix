{
  description = "A DevOS example. And also a digga test bed.";

  inputs =
    {
      nixos.url = "github:NixOS/nixpkgs/release-21.11";
      nixpkgs-darwin-stable.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";

      digga = {
        url = "github:montchr/digga?ref=feature/darwin-hosts-support";
        inputs.nixpkgs.follows = "nixos";
      };

      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";
    };

  outputs = inputs @ { self, nixos, nixpkgs-darwin-stable, digga, home }:
    digga.lib.mkFlake {

      inherit self inputs;

      channels = {
        nixos = { };
        nixpkgs-darwin-stable = { };
      };

      nixos = ./nixos;
      darwin = ./darwin;
      home = ./home;
      devshell = ./devshell;

    };
}
