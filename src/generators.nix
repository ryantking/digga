{ lib, deploy }:
{
  mkDeployNodes = nixosConfigurations: extraConfig:
    /**
      Synopsis: mkDeployNodes _nixosConfigurations_ _extraConfig_

      Generate the `nodes` attribute expected by deploy-rs
      where _nixosConfigurations_ are `nodes`.
      **/
    let
      op = _: host:
        let
          activate = deploy.lib.${host.config.nixpkgs.system}.activate;
          hm-profiles = (n: v: {
            user = n;
            profilePath = "/nix/var/nix/profiles/per-user/${n}/home-manager";
            path = activate.home-manager v.home;
          });
        in
        {
          hostname = host.config.networking.hostName;
          profiles =
            {
              system = {
                user = "root";
                path = activate.nixos host;
              };
            }
            //
            (
              builtins.mapAttrs
                hm-profiles
                host.config.home-manager.users
            )
          ;
        }
      ;
    in
    lib.recursiveUpdate (lib.mapAttrs op nixosConfigurations) extraConfig
  ;

  mkHomeConfigurations = nixosConfigurations:
    /**
      Synopsis: mkHomeConfigurations _nixosConfigurations_

      Generate the `homeConfigurations` attribute expected by
      `home-manager` cli from _nixosConfigurations_ in the form
      _user@hostname_.
      **/
    let
      op = attrs: host:
        attrs
        //
        (
          let
            net = host.config.networking;
            fqdn =
              if net.domain != null
              then "${net.hostName}.${net.domain}"
              else net.hostName;
          in
          lib.mapAttrs'
            (user: v: {
              name = "${user}@${fqdn}";
              value = v.home;
            })
            host.config.home-manager.users
        )
      ;
      mkHmConfigs = lib.foldl op { };
    in
    mkHmConfigs (builtins.attrValues nixosConfigurations);

}
