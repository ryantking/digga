# constructor dependencies
{ lib, self, inputs, deploy, devshell, home-manager, flake-utils-plus, tests, ... }:
config: channels:
let

  pkgs = channels.${config.nixos.hostDefaults.channelName};
  system = pkgs.system;

  mkPortableHomeManagerConfiguration =
    { username
    , configuration
    , pkgs
    , system ? pkgs.system
    }:
    let
      homeDirectoryPrefix =
        if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home";
      homeDirectory = "${homeDirectoryPrefix}/${username}";
    in
    home-manager.lib.homeManagerConfiguration {
      inherit username homeDirectory pkgs system;

      extraModules = config.home.modules ++ config.home.exportedModules;
      extraSpecialArgs = config.home.importables // { inherit self inputs; };

      configuration = {
        imports = [ configuration ];
      } // (
        if pkgs.stdenv.hostPlatform.isLinux
        then { targets.genericLinux.enable = true; }
        else { }
      );
    };

  homeConfigurationsPortable =
    builtins.mapAttrs
      (n: v: mkPortableHomeManagerConfiguration {
        username = n;
        configuration = v;
        inherit pkgs system;
      })
      config.home.users;

in
{

  inherit homeConfigurationsPortable;

  packages = flake-utils-plus.lib.exportPackages self.overlays channels;

  devShell =
    let
      eval = import "${devshell}/modules" pkgs;
      configuration = {
        name = lib.mkDefault config.nixos.hostDefaults.channelName;
        imports = config.devshell.modules ++ config.devshell.exportedModules;
      };
    in
    (eval {
      inherit configuration;
      extraSpecialArgs = { inherit self inputs; };
    }).shell;

  checks =
    (
      # for self.homeConfigurations if present & non empty
      if (
        (builtins.hasAttr "homeConfigurations" self) &&
        (self.homeConfigurations != { })
      ) then
        let
          seive = _: v: v.system == system; # only test for the appropriate system
          collectActivationPackages = n: v: { name = "user-" + n; value = v.activationPackage; };
        in
        lib.filterAttrs seive (lib.mapAttrs' collectActivationPackages self.homeConfigurations)
      else { }
    )
    //
    (
      # for portableHomeConfigurations if present & non empty
      if (
        (homeConfigurationsPortable != { })
      ) then
        let
          collectActivationPackages = n: v: { name = "user-" + n; value = v.activationPackage; };
        in
        lib.mapAttrs' collectActivationPackages homeConfigurationsPortable
      else { }
    )
    //
    (
      # for self.deploy if present & non-empty
      if (
        (builtins.hasAttr "deploy" self) &&
        (self.deploy != { })
      ) then
        let
          deployChecks = deploy.lib.${system}.deployChecks self.deploy;
          renameOp = n: v: { name = "deploy-" + n; value = deployChecks.${n}; };
        in
        lib.mapAttrs' renameOp deployChecks
      else { }
    )
    //
    (
      # for self.nixosConfigurations if present & non-empty
      if (
        (builtins.hasAttr "nixosConfigurations" self) &&
        (self.nixosConfigurations != { })
      ) then
        let
          systemSieve = _: host: host.config.nixpkgs.system == system;
          hostConfigsOnThisSystem = lib.filterAttrs systemSieve self.nixosConfigurations;

          createCustomTestOp = n: host: test:
            lib.warnIf (!(test ? name)) ''
              '${n}' has a test without a name. To distinguish tests in the flake output
              all nixos tests must have names.
            ''
              {
                name = "customTestFor-${n}-${test.name}";
                value = tests.mkTest host test;
              };

          createCustomTestsOp = n: host:
            let
              op = createCustomTestOp n host;
            in
            builtins.listToAttrs (map op config.nixos.hosts.${n}.tests);

          customTests =
            if (hostConfigsOnThisSystem != [ ])
            then lib.foldl (a: b: a // b) { } (lib.attrValues (lib.mapAttrs createCustomTestsOp hostConfigsOnThisSystem))
            else { };

        in
        customTests
      else { }
    )
    //
    (
      # for config.self.darwinConfigurations if present & non-empty
      if (
        (builtins.hasAttr "darwinConfigurations" config.self) &&
        (config.self.darwinConfigurations != { })
      ) then
        let
          systemSieve = _: host: host.config.nixpkgs.system == system;
          hostConfigsOnThisSystem = lib.filterAttrs systemSieve config.self.darwinConfigurations;

          createCustomTestOp = n: host: test:
            lib.warnIf (!(test ? name)) ''
              '${n}' has a test without a name. To distinguish tests in the flake output
              all darwin tests must have names.
            ''
              {
                name = "customTestFor-${n}-${test.name}";
                value = tests.mkTest host test;
              };

          createCustomTestsOp = n: host:
            let
              op = createCustomTestOp n host;
            in
            builtins.listToAttrs (map op config.darwin.hosts.${n}.tests);

          customTests =
            if (hostConfigsOnThisSystem != [ ])
            then
              lib.foldl (a: b: a // b) { }
                (lib.attrValues
                  (lib.mapAttrs createCustomTestsOp hostConfigsOnThisSystem))
            else { };

        in
        customTests
      else { }
    )
  ;

}
