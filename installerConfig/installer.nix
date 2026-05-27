{pkgs, lib, ...}:
let
  basicConfig = import ../kioskConfig/basicConfig.nix {inherit lib;};
  
  KioskInstallScript = pkgs.writeText "pwshInstallKiosk.ps1" ''
    function SelectDisk {
      Clear-Host
      Write-Host "Select Disk" -ForegroundColor Blue
      Write-Host "-----------------------------------------------" -ForegroundColor DarkGray
      $allDisks = lsblk -O --json | ConvertFrom-Json
      $validDisks = $allDisks.blockdevices | Where-Object Tran -NotLike usb | Where-Object RM -ne $true | Where-Object RO -ne True | Select-Object Name, Size, Vendor, Model | Sort-Object Name
      $validDisks | Format-Table | Out-Host
      Write-Host "-----------------------------------------------" -ForegroundColor DarkGray
      Write-Host "Input target drive name (i.e. 'sda'): " -ForegroundColor Yellow -NoNewline
      $requestedDisk = Read-Host

      if ($requestedDisk -notIn $validDisks.name){
          Write-Host "Disk name '$requestedDisk' not found, press enter to try again" -ForegroundColor Red -NoNewline
          Read-Host
          SelectDisk
      }

      $selectedDisk = $validDisks | Where-Object name -Like $requestedDisk

      return $selectedDisk
  }

  function PartitionDisk {
      param(
          [psobject]$disk
      )

      Clear-Host
      Write-Host "Partitioning Disks" -ForegroundColor Blue
      Write-Host "-----------------------------------------------" -ForegroundColor DarkGray
      Write-Host "Selected Disk:" -ForegroundColor Cyan
      $disk | Format-Table | Out-Host
      Write-Host "-----------------------------------------------" -ForegroundColor DarkGray

      Write-Host "Wiping File System" -ForegroundColor Cyan
      wipefs -a "/dev/$($disk.name)"

      Write-Host "Making GPT Partition Table" -ForegroundColor Cyan
      parted -s "/dev/$($disk.name)" mklabel gpt

      Write-Host "Making EFI System Partition" -ForegroundColor Cyan
      parted -s "/dev/$($disk.name)" mkpart ESP fat32 1MiB 513MiB
      parted -s "/dev/$($disk.name)" set 1 esp on

      Write-Host "Making Root Partition" -ForegroundColor Cyan
      parted -s "/dev/$($disk.name)" mkpart primary ext4 513MiB 100%

      Write-Host "Re-scanning Disks" -ForegroundColor Cyan
      partprobe "/dev/$($disk.name)"
      udevadm settle
      Start-Sleep -Seconds 2

      if ($disk.name -notLike "sd*") {
          $esp = "/dev/$($disk.name)p1"
          $root = "/dev/$($disk.name)p2"
      } else {
          $esp = "/dev/$($disk.name)1"
          $root = "/dev/$($disk.name)2"
      }

      Write-Host "Creating EFI Filesystem" -ForegroundColor Cyan
      mkfs.fat -F 32 -n EFI $esp

      Write-Host "Creating Root Filesystem" -ForegroundColor Cyan
      mkfs.ext4 -F -L nixos $root

      Write-Host "Mounting Root Partition" -ForegroundColor Cyan
      mount $root /mnt

      Write-Host "Mounting EFI System Partition" -ForegroundColor Cyan
      New-Item -ItemType Directory -Path "/mnt/boot"
      mount $esp /mnt/boot 
  }

  function InstallNixOS {
      Clear-Host
      Write-Host "Installing NixOS" -ForegroundColor Blue
      Write-Host "-----------------------------------------------" -ForegroundColor DarkGray

      Write-Host "Creating /etc/nixos directory" -ForegroundColor Cyan
      New-Item -ItemType Directory -Path "/mnt/etc/nixos"

      Write-Host "Making a local copy of the simpleKiosk repo" -ForegroundColor Cyan
      Copy-Item -Path "/iso/${basicConfig.projectName}" -Destination "/mnt/etc/nixos/${basicConfig.projectName}" -Recurse -Force

      Write-Host "Generating hardware-configuration.nix" -ForegroundColor Cyan
      nixos-generate-config --root /mnt --dir /mnt/etc/nixos
      Copy-Item -Path "/mnt/etc/nixos/hardware-configuration.nix" -Destination "/etc/nixos/hardware-configuration.nix" -Recurse -Force 
      # ^^ (the currently booted environment needs a hardware-configuration.nix to run nixos-install)
  
      Write-Host "Installing NixOS" -ForegroundColor Cyan
      nixos-install --flake github:${basicConfig.githubRepo}#kiosk --impure --no-root-password 
  }

  function PromptReboot {
      Clear-Host
      Write-Host "Installation Complete" -ForegroundColor Blue
      Write-Host "-----------------------------------------------" -ForegroundColor DarkGray
      Write-Host "NixOS has been sucessfully installed" -ForegroundColor Cyan
      Write-Host "Press Enter to reboot, then unplug the USB." -ForegroundColor Yellow -NoNewline
      Read-Host
      reboot
  }


  # ----------------------------------------------------------------------
  
  PartitionDisk -disk (SelectDisk)
  InstallNixOS
  PromptReboot

  
  '';


  InstallKiosk = pkgs.writeShellScriptBin "install-kiosk" ''
    exec ${pkgs.powershell}/bin/pwsh -File ${KioskInstallScript}   
  '';
  
in
{

  # Enable auto login as root
  services.getty.autologinUser = lib.mkForce "root";
  users.users.root.shell = pkgs.bashInteractive;

  environment.systemPackages = [ InstallKiosk dosfstools ];
  
  programs.bash.loginShellInit = "install-kiosk";
 
}
