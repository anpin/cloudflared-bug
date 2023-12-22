{
  description = "A very basic flake";

  outputs = inputs@{ self, nixpkgs, ... }:
    let 
    # uuid = "2c21658f-ef58-4f45-b954-d04bag9df5a8";
    uuid = "tun";
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system ; };
    inherit (inputs.nixpkgs) lib; 
    in {
    apps.${system}.check-config = {
        type = "app";
        program = toString (pkgs.writers.writeBash "check-config" ''
            echo "value of originRequest : ${builtins.toJSON self.nixosConfigurations.repro.config.services.cloudflared.tunnels.${uuid}.originRequest}"
            SERVICE="${self.nixosConfigurations.repro.config.systemd.services."cloudflared-tunnel-${uuid}".serviceConfig.ExecStart}"
            echo "systemd ExecStart: $SERVICE"
            CFG=$(echo $SERVICE | sed -n 's/.*--config=\([^ ]*\).*/\1/p')
            echo "Effective config @ $CFG : $(cat $CFG)"
        '');
     };
     nixosConfigurations.repro = with lib; nixosSystem {
              inherit system;
              modules = [
                ({config, pkgs,  ... }: {
                      system.stateVersion= " 24.05";
                      networking = {
                          hostName = "host";
                          domain = "example.com";
                      };
                      services.cloudflared = {
                          enable = true;
                          tunnels."${uuid}" = {
                            ingress = {
                              "${config.networking.domain}" = "https://localhost:443";
                              "*.${config.networking.domain}" = "https://localhost:443";
                            };
                            originRequest = {
                                originServerName = "*.${config.networking.domain}";
                                noTLSVerify = true;
                            };
                            default = "http_status:404";
                            credentialsFile = "${ ./file}";
                          };
                      };
                  }
                  )
              ];
          };
  };
}
