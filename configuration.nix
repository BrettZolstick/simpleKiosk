{ config, pkgs, ... }:
let

  startKiosk = pkgs.writeShellScript "start-kiosk" ''
    ${pkgs.wayidle}/bin/wayidle timeout 10 'pkill chromium' &
    
    ${pkgs.chromium}/bin/chromium \
    --ozone-platform=wayland \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=Translate \
    --start-fullscreen \
    --incognito \
    --app=https://museum.lingscars.com
  '';

in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.timeout = 0;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = false;
    timeoutStyle = "hidden";
  };
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;

  time.timeZone = "America/New_York";

  networking.hostName = "kiosk";
  networking.networkmanager.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "kiosk";
        command = "${pkgs.weston}/bin/weston --shell=kiosk-shell.so -- ${startKiosk}";
      };
    };
  };

  # Set Chrome URL Whitelist
  environment.etc."chromium/policies/managed/kiosk-policy.json".text = builtins.toJSON {
    URLBlocklist = [ "*" ];
    URLAllowlist = [
      "lingscars.com"
    ];
  };
  
  users.users.kiosk = {
    isNormalUser = true;
  };

  users.users.root.initialPassword = ""; # enables passwordless root

  environment.systemPackages = with pkgs; [
    tree
    btop
    fastfetch
    helix
    micro
    weston
    git
    yazi
    bat
    wayidle
  ];

  environment.shellAliases = {
    kiosk-update = "nixos-rebuild switch --flake github:BrettZolstick/simpleKiosk#kiosk --impure --refresh";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = "25.11";
}
