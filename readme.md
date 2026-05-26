# SimpleKiosk

Turn any x86 device into a simple web kiosk

## Description

This project uses Nix to build an ISO that will install NixOS onto any x86 device. The ISO installs NixOS with whatever config you put in ./configuration.nix. In this case, its building a barebones kiosk that will just sit on a wall, load a webpage, and reset itself after a certain period of inactivity.

## Getting Started

You can build your own ISO on any system with Nix installed.

### How do I install nix?
* Windows
  * I recommend [NixOS-WSL](https://github.com/nix-community/NixOS-WSL)
* macOS
  * [Nix Package Manager for macOS](https://nixos.org/download/#nix-install-macos)
* Linux
  * [Nix Package Manager for Linux](https://nixos.org/download/#nix-install-linux)

### I have Nix installed. How do I build the ISO?

In your terminal, clone the repository
``` 
git clone https://github.com/BrettZolstick/simpleKiosk.git 
cd simpleKiosk
```
then build with Nix. (This will take a few minutes)
```
nix build
```
The ISO will be created here:
```
 ./simplekiosk
  └── Result
    └── iso
      └── nixos-minimal-*-x86_64-linux.iso
```
**Please Note:** The result is a symlink to the nix store, which cannot be navigated in windows explorer. If you're on windows and plan on using a tool like [rufus](https://rufus.ie/en/) to burn the image to a usb, copy it to a normal location like this.
```
cp ./result/iso/nixos-minimal-*-x86_64-linux.iso  /mnt/c/Users/<Your Username Here>/Downloads/NixOS-Kiosk.iso

```
### I have the ISO, how do I burn it to a USB?
 * Use the dd command (use with caution)
```
# find your usb device name first 
lsblk

# make sure not to wipe the wrong drive 
dd if=./result/iso/nixos-minimal-*-x86_64-linux.iso of=/dev/<Drive Name> bs=4M status=progress 
```
(or)

* Use [Rufus](https://rufus.ie/en/) in dd mode

## Changing the configuration

* Most of the changes that you'll want to make are probably in **./kioskConfig/basicConfig.nix**. Please refer to the comments in this file for instruction. It should be pretty self explanitory.

* Because the installer pulls directly from the selected github repo, If you want to make changes to your own config, please [fork this repo.](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) You will need to point the config at your own repo by changing the value in ./kioskConfig/basicConfig.nix

* For more advanced changes to the kiosk, see ./kioskConfig/advancedConfig.nix. If you're familar with NixOS already, then you can make whatever changes you want here. Otherwise I reccomend the following learning resources.
    * [NixOS Options Search](https://search.nixos.org/options)
    * [NixOS Package Search](https://search.nixos.org/packages)
    * [NixOS Wiki](https://wiki.nixos.org/wiki/NixOS_Wiki)
    * [NixOS and Flakes guide](https://nixos-and-flakes.thiscute.world/)
    * [Vimjoyer's github](https://github.com/vimjoyer) and [Youtube Channel](https://www.youtube.com/@vimjoyer)
    * [Tony's github](https://github.com/tonybanters) and [Youtube Channel](https://www.youtube.com/@tony-btw)
    * [The Unofficial NixOS Discord](https://discord.com/invite/RbvHtGa)
    * Good old ChatGPT

    Also feel free to raise an [issue](https://github.com/BrettZolstick/simpleKiosk/issues) or make a post in [discussions](https://github.com/BrettZolstick/simpleKiosk/discussions) and I'll help out where I can.




## Acknowledgments

* [Linux](https://github.com/torvalds/linux)
* [NixOS](https://github.com/NixOS)
* [Sway](https://github.com/swaywm/sway)
* [Plymouth](https://gitlab.freedesktop.org/plymouth/plymouth)
