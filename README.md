# custom linux distrobution: codename : TabianOS
## about this project
this project uses live-build to build a hybrid iso with a calamares install menu, the regular debian installer is also available
## how to build the iso from source (linux)
* install live-build and it's helper packages: `sudo apt install -y live-build arch-test debootstrap`
* clone this repository
* `cd` into it
* build the project from the source `sudo lb clean --purge && sudo lb config && sudo lb build`

**note** : the configured `lb config` inside *auto/config* uses a local cache proxy to reduce build time during development.

to deactivate it: remove or comment this line in *auto/config* before building: 

`--apt-http-proxy "http://localhost:3142" \`

## versions
1.0 (curernt) : 
* Architecture: Legacy MBR/BIOS only (bundled strictly with grub-pc and grub-common).
* Base: Stripped-down base configuration of Debian 13 (Trixie).
* Installer: Calamares graphical configuration wizard with built-in post-reboot localization awareness.
