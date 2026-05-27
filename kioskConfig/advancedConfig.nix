{ pkgs, lib, ... }:
let
  basicConfig = import ./basicConfig.nix {inherit lib;}; 
  
  startKiosk = pkgs.writeShellScript "start-kiosk" ''
    while true; do
      ${pkgs.chromium}/bin/chromium \
      --ozone-platform=wayland \
      --no-first-run \
      --disable-infobars \
      --disable-session-crashed-bubble \
      --disable-features=Translate \
      --start-fullscreen \
      --incognito \
      --kiosk \
      --app=${basicConfig.homepage}
    done
  '';

  swayConfig = pkgs.writeText "sway-kiosk-config" ''
    output * bg #000000 solid_color
    default_border none
    default_floating_border none
    seat * hide_cursor 3000
    exec ${startKiosk}
    exec swayidle -w timeout ${basicConfig.idleTimeout} 'swaymsg "output * power off"' resume 'pkill chromium; swaymsg "output * power on"'
  '';



in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.timeout = 0;
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
  boot.kernelParams = [
    "quiet"
    "splash"
  ];
  boot.plymouth = {
    enable = true;
    theme = "solar";
    logo = basicConfig.startupSplashLogo; # must be a png
  };
  boot.consoleLogLevel = 0;
  boot.initrd.systemd.enable = true;
  boot.initrd.verbose = false;
  
  services.automatic-timezoned.enable = true;

  networking.hostName = "kiosk";
  networking.networkmanager.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "kiosk";
        command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --config ${swayConfig}";
      };
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Set Chrome URL Whitelist
  environment.etc."chromium/policies/managed/kiosk-policy.json".text = builtins.toJSON {
    URLBlocklist = basicConfig.urlBlacklist;
    URLAllowlist = basicConfig.urlWhitelist;
  };
  
  users.users.kiosk = {
    isNormalUser = true;
  };

  users.users.root.initialPassword = ""; # enables passwordless root
  # ^ before production, change this to a hashed password that we can safely store in the public repo
  #   then we can distribute the un-hashed password to the facilities as needed

  environment.systemPackages = with pkgs; [
    tree
    btop
    fastfetch
    helix
    micro
    git
    yazi
    bat
    swayidle
  ];




  environment.shellAliases = {
    kiosk-update = "nixos-rebuild switch --flake github:${basicConfig.githubRepo}#kiosk --impure --refresh";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = "25.11";
}
