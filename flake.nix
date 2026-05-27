{
  description = "NixOS kiosk installer";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
  let
    basicConfig = import ./kioskConfig/basicConfig.nix {lib = nixpkgs.lib;};
  in
  {
   
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./installerConfig/installer.nix
        {
          boot.kernelParams = [ "nomodeset" ];
          isoImage.contents = [
            {
              source = ./.;
              target = "/${basicConfig.projectName}";
            }
          ];
        }

      ];
    };

    nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./kioskConfig/advancedConfig.nix
        ];
        
    };

    packages.x86_64-linux.default = self.nixosConfigurations.installer.config.system.build.isoImage;
    
  };
}
  
