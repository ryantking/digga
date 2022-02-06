{ self, inputs, ... }:

let
  inherit (inputs.digga.lib) allProfilesTest;
in

{
  imports = [ (inputs.digga.lib.importHosts ./hosts) ];

  hostDefaults = {
    channelName = "nixos";
  };

  hosts = {
    "Morty" = {
      tests = [ allProfilesTest ];
    };
  };

  importables = rec {
    suites = rec {
      base = [ ];
    };
  };
}
