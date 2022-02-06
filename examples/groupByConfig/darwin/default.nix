{ self, inputs, ... }:

let
  inherit (inputs.digga.lib) allProfilesTest;
in

{
  imports = [ (inputs.digga.lib.importHosts ./hosts) ];

  hostDefaults = {
    channelName = "nixpkgs-darwin-stable";
  };

  hosts = {
    "Darwinia" = { };

    # TODO: should we expect these tests to work on darwin? any platform limitations?
    # Darwinia.tests = [ allProfilesTest ];
  };

  importables = rec {
    profiles = inputs.digga.lib.rakeLeaves ./profiles;
    suites = with profiles; rec {
      base = [ core ];
    };
  };
}
