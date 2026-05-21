{pkgs, lib, ...}: {

  # Enable auto login as root
  services.getty.autologinUser = lib.mkForce "root";
  users.users.root.shell = pkgs.bashInteractive;

  # Make a package thats just a NixOS install script
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "install-kiosk" ''

      set -e

      # List drives
      lsblk -d -o NAME,SIZE,MODEL
      echo ""

      # Ask the user to select a disk
      read -p "Enter target disk: " DISK
      DISK="/dev/$DISK"
      echo "WARNING: This will erase $DISK. Press enter to continue, or Ctrl+C to abort"
      read

      # Partition Disk
      echo "Partitioning Disk"
      wipefs -a "$DISK" || true
      parted -s "$DISK" mklabel msdos
      parted -s "$DISK" mkpart primary ext4 1MiB 100%
      partprobe "$DISK"
      udevadm settle
      sleep 2
      if [[ "$DISK" = *"nvme"* ]]; then
        ROOT="''${DISK}p1"
      else
        ROOT="''${DISK}1"
      fi
      mkfs.ext4 -F -L nixos "$ROOT"
      mount "$ROOT" /mnt
      

      # Install Nixos 
      mkdir -p /mnt/etc/nixos 
      cp -r /iso/simpleKiosk /mnt/etc/nixos/simpleKiosk # make a local copy of the entire flake on the target machine
      nixos-generate-config --root /mnt --dir /mnt/etc/nixos # generate the dan gum hardware-configuration.nix on the target machine
      cp /mnt/etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix # copy the hardware configuration to the installer's /etc/nixos/ too so nix-install can buld.
      nixos-install --flake github:BrettZolstick/simpleKiosk#kiosk --no-root-passwd --impure # install from the local flake

      # Reboot
      echo ""
      echo "Done! Remove the USB and press Enter to reboot"
      read
      reboot
    
    ''
    )
  ];

  # Call the install script on login
  programs.bash.loginShellInit = "install-kiosk";

 
}
