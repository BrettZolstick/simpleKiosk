{
  # Repo to pull the config from ("<username>/<repo>/<branch (optional)>")
  githubRepo = "BrettZolstick/simpleKiosk";


  # Time in seconds before the kiosk resets itself when idle
  idleTimeout = "30";


  # Path to the logo to show on reboot
  startupSplashLogo =  ./resources/logo.png; # path no quotes


  # Root Password
  # 
  # You can make a hashed password with the following command:
  #   'nix shell nixpkgs#whois -c mkpasswd -m yescrypt <password>'
  enableRootLogin = true;
  enablePasswordlessRoot = true; 
  rootHashedPassword = "$y$j9T$N0kLucrcTRCarwxMUadL51$ZeYxU/1PqPX.nPcLO/1da6Qgv4mEYlIGAXBFPrejewC";


  # Homepage URL
  homepage = "nixos.org"; 


  # You can block/allow sites here
  #
  # Values must be in quotes and are separated by new lines,
  # You can use * as a wildcard
  #
  # Read more on the filter format here: https://support.google.com/chrome/a/answer/9942583
  urlBlacklist = [
    "*"
  ];
  urlWhitelist = [
    "*"
  ];

}  
              
