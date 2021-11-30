{ lib, deploy }:
let
  getFqdn = c:
    let
      net = c.config.networking;
      fqdn =
        if net.domain != null
        then "${net.hostName}.${net.domain}"
        else net.hostName;
    in
    fqdn;

in
{
  mkHomeConfigurations = nixosConfigurations:
    /**
      Synopsis: mkHomeConfigurations _nixosConfigurations_

      Generate the `homeConfigurations` attribute expected by
      `home-manager` cli from _nixosConfigurations_ in the form
      _user@hostname_.
      **/
    let
      op = attrs: c:
        attrs
        //
        (
          lib.mapAttrs'
            (user: v: {
              name = "${user}@${getFqdn c}";
              value = v.home;
            })
            c.config.home-manager.users
        )
      ;
      mkHmConfigs = lib.foldl op { };
    in
    mkHmConfigs (builtins.attrValues nixosConfigurations);

  mkDeployNodes = hosts: homes: extraConfig:
    /**
      Synopsis: mkDeployNodes _nixosConfigurations_ _homeConfigurationsPortable_ _extraConfig_

      Generate the `nodes` attribute expected by deploy-rs
      where _nixosConfigurations_ are `nodes` and _homeConfigurationsPortable_ are system
      spaced home configurations.
      **/
    lib.recursiveUpdate
      (lib.mapAttrs
        (_: c:
          {
            hostname = getFqdn c;
            profiles = {
              system = {
                user = "root";
                path = deploy.lib.${c.config.nixpkgs.system}.activate.nixos c;
              };
            } // (lib.mapAttrs (k: v: {
              user = k;
              path = deploy.lib.${c.config.nixpkgs.system}.activate.home-manager v;
            }) homes.${c.config.nixpkgs.system});
          }
        )
        hosts)
      extraConfig;
}
