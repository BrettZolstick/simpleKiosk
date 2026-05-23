{ config, pkgs, ... }:

let
  idleWatcher = pkgs.writeShellScript "kiosk-idle-watcher" ''
    ${pkgs.python3.withPackages (p: [ p.evdev ])}/bin/python3 ${pkgs.writeText "idle-watch.py" ''
      import os, time, select, subprocess
      from evdev import InputDevice, list_devices

      IDLE_SECONDS = 10

      def inputs():
          return [InputDevice(p) for p in list_devices()]

      def screen(on):
          # Built-in panel/backlight path
          for root, dirs, files in os.walk("/sys/class/backlight"):
              if "bl_power" in files:
                  try:
                      with open(os.path.join(root, "bl_power"), "w") as f:
                          f.write("0" if on else "4")
                  except Exception:
                      pass

      def kill_chromium():
          subprocess.run(["pkill", "-TERM", "chromium"], check=False)
          time.sleep(2)
          subprocess.run(["pkill", "-KILL", "chromium"], check=False)

      devs = inputs()
      last = time.monotonic()
      asleep = False

      while True:
          r, _, _ = select.select(devs, [], [], 1)

          if r:
              for d in r:
                  try:
                      for _ in d.read():
                          pass
                  except OSError:
                      devs = inputs()

              last = time.monotonic()

              if asleep:
                  screen(True)
                  asleep = False

          if not asleep and time.monotonic() - last > IDLE_SECONDS:
              kill_chromium()
              screen(False)
              asleep = True
    ''}
  '';
in {
  systemd.services.kiosk-idle-watcher = {
    wantedBy = [ "multi-user.target" ];
    after = [ "greetd.service" ];
    serviceConfig = {
      ExecStart = "${idleWatcher}";
      Restart = "always";
      User = "root";
    };
  };
}
