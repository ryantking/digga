# input: patches
let
  nixpkgsGitRev = "246502ae2d5ca9def252abe0ce6363a0f08382a7";
  nixpkgsSrc = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgsGitRev}.tar.gz";
    sha256 = "sha256-cuCj8CfBrVlEYQM2jfD3psh2jV/sR5HACYkC74WR9KE=";
  };
in
  system: let
    pkgs = import "${nixpkgsSrc}/pkgs/top-level" { localSystem = system; };
  in
    input: let
      src = input.outPath;
    in
      patches:
        builtins.getFlake (builtins.toString (derivation {
          inherit patches src system;
          builder = ./patcher.sh;
          buildInputs = [
            pkgs.coreutils
            pkgs.patch
          ];
          name = "patched-source";
        }).outPath)
    
