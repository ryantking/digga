{ self, inputs, ... }:
let
  lib = inputs.digga.lib;
in
{
  imports = [ (lib.importModules ./modules) ];
  nonExportedModules = [ ];
  importables = rec {
    profiles = lib.rakeLeaves ./profiles;
    suites = with profiles; {
      shell = with shell; [ direnv ];
    };
  };
  users = lib.rakeLeaves ./users;
}
