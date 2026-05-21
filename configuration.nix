{ config, pkgs, ... }:
let
  homeURL = "https://museum.lingscars.com"; # the page the kiosk load
  idleSeconds = 15; # idle time in seconds before the kiosk resets
  
  startKiosk = pkgs.writeShellScript "start-kiosk" ''
    exec ${pkgs.chromium}/bin/chromium \
    --ozone-platform=wayland \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=Translate \
    --start-fullscreen \
    --load-extension=/etc/kiosk-extension \
    ${homeURL}
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
      "*"
    ];
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
    weston
    git
    yazi
    bat
  ];


  # Make a chrome extenion to handle idle behavior
  environment.etc."kiosk-extension/manifest.json".text = ''
    {
      "manifest_version": 3,
      "name": "Kiosk Idle Handler",
      "version": "1.0",
      "incognito": "split",
      "permissions": ["idle","tabs","browsingData"],
      "content_scripts": [
        {
          "matches": ["<all_urls>"],
          "js": ["activity.js"],
          "run_at": "document_start",
          "all_frames": true
        }
      ],
      "background":{
        "service_worker":"background.js"
      }
    }    
  '';
  environment.etc."kiosk-extension/background.js".text = ''
    
    let timer = null; 

    function resetTimer() {
      clearTimeout(timer);

      timer = setTimeout(async () => {
        await chrome.browsingData.remove({
          since: 0
        }, {
          cookies: true,
          cache: true,
          localStorage: true,
          indexedDB: true,
          serviceWorkers: true
        });

        const tabs = await chrome.tabs.query({});
        const mainTab = tabs[0];

        for (const tab of tabs.slice(1)) {
          chrome.tabs.remove(tab.id);
        }

        chrome.tabs.update(mainTab.id, { url: ${homeURL}});
      }, ${idleSeconds} * 1000);
    }

    chrome.runtime.onMessage.addListener((message) => {
      if (message.type === "activity") {
        resetTimer();
      }
    });

    resetTimer();
  '';
  


  environment.shellAliases = {
    kiosk-update = "nixos-rebuild switch --flake github:BrettZolstick/simpleKiosk#kiosk --impure --refresh";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = "25.11";
}
