# Nix Documentation

Some common nix related tasks are documented here.


## Generate an installer ISO

```bash
nix build --no-link --print-out-paths ".#installer"
```


### How to install a system

1. In the installer, create and mount filesystems.
2. Enter filesystem config into this repository for that server and commit changes.

   ```nix
    fileSystems = {
        "/boot" = {
            device = "/dev/disk/by-uuid/…";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
        };
        "/" = {
            device = "/dev/disk/by-uuid/…";
            fsType = "bcachefs";
        };
    };
   ```
3. Run nixos-install like this:

   ```shell
   sudo nixos-install --no-channel-copy --no-root-passwd --root /mnt --flake 'github:ftsell/finnfrastructure?ref=nix-config#…'
   ```
4. Reboot the system


