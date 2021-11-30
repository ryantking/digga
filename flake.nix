{
  description = "DevOS environment configuriguration library.";

  nixConfig.extra-experimental-features = "nix-command flakes";
  nixConfig.extra-substituters = "https://nrdxp.cachix.org https://nix-community.cachix.org";
  nixConfig.extra-trusted-public-keys = "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";

  inputs =
    {
      nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
      latest.url = "github:nixos/nixpkgs/nixos-unstable";
      nixlib.follows = "nixpkgs"; # "github:nix-community/nixpkgs.lib";
      blank.url = "github:divnix/blank";
      deploy.url = "github:input-output-hk/deploy-rs";
      deploy.inputs.nixpkgs.follows = "nixpkgs"; # has an incompatible `fenix/nixpkgs` follows

      home-manager.url = "github:nix-community/home-manager";

      devshell.url = "github:numtide/devshell";
      treefmt.url = "github:numtide/treefmt";
      flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";

      nixos-generators.url = "github:nix-community/nixos-generators";
    };

  outputs =
    { self
    , nixlib
    , nixpkgs
    , latest
    , deploy
    , devshell
    , treefmt
    , flake-utils-plus
    , nixos-generators
    , home-manager
    , ...
    }@inputs:
    let

      tests = import ./src/tests.nix { inherit (nixpkgs) lib; };

      internal-modules = import ./src/modules.nix {
        inherit (nixpkgs) lib;
        inherit nixos-generators;
      };

      importers = import ./src/importers.nix {
        inherit (nixpkgs) lib;
      };

      generators = import ./src/generators.nix {
        inherit (nixpkgs) lib;
        inherit deploy;
      };

      mkFlake =
        let
          mkFlake' = import ./src/mkFlake {
            inherit (nixpkgs) lib;
            inherit (flake-utils-plus.inputs) flake-utils;
            inherit deploy devshell home-manager flake-utils-plus internal-modules tests;
          };
        in
        {
          __functor = _: args: (mkFlake' args).flake;
          options = args: (mkFlake' args).options;
        };

      # Unofficial Flakes Roadmap - Polyfills
      # .. see: https://demo.hedgedoc.org/s/_W6Ve03GK#
      # .. also: <repo-root>/ufr-polyfills

      # Super Stupid Flakes (ssf) / System As an Input - Style:
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
      ufrContract = import ./ufr-polyfills/ufrContract.nix;

      # Dependency Groups - Style
      checksInputs = { inherit nixpkgs; digga = self; };
      jobsInputs = { inherit nixpkgs; digga = self; };
      devShellInputs = { inherit nixpkgs devshell treefmt; };

      # .. we hope you like this style.
      # .. it's adopted by a growing number of projects.
      # Please consider adopting it if you want to help to improve flakes.

      # DEPRECATED - will be removed timely
      deprecated = import ./deprecated.nix {
        inherit (nixpkgs) lib;
      };

    in

    {
      # what you came for ...
      lib = {
        inherit (flake-utils-plus.inputs.flake-utils.lib) defaultSystems eachSystem eachDefaultSystem filterPackages;
        inherit (flake-utils-plus.lib) exportModules exportOverlays exportPackages;
        inherit mkFlake;
        inherit (tests) mkTest allProfilesTest;
        inherit (importers) flattenTree rakeLeaves importOverlays importExportableModules importHosts;
        inherit (generators) mkDeployNodes mkHomeConfigurations;

        # DEPRECATED - will be removed soon
        # inherit (deprecated)
        #   ...
        #   ;

      };

      # a little extra service ...
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules;

      # digga-local use
      jobs = ufrContract supportedSystems ./jobs jobsInputs;
      checks = ufrContract supportedSystems ./checks checksInputs;
      devShell = ufrContract supportedSystems ./shell.nix devShellInputs;
    };

}
