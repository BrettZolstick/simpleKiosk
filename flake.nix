{
  description = "NixOS kiosk installer";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: {
    
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./installer.nix
        {
          isoImage.contents = [
            {
              source = ./.;
              target = "/simpleKiosk";
            }
          ];
        }

      ];
    };

    nixosConfigurations.kiosk = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        
    };

    packages.x86_64-linux.default = self.nixosConfigurations.installer.config.system.build.isoImage;
    
  };
}
  
