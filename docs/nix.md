# Nix Documentation

Some common nix related tasks are documented here.

## Custom Modules

| Name                                                      | Options                     | Description                                                                                                                                                                    |
|-----------------------------------------------------------|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [base_system](../nix/modules/base_system.nix)             | *none*                      | Basic configuration for **all** systems                                                                                                                                        |
| [presets](../nix/modules/presets.nix)                     | `custom.preset`             | Toggle between presets of different hosting environment the system is operating in                                                                                             |
| [auto_upgrade](../nix/modules/auto_upgrade.nix)           | `custom.autoUpgrade.`       | Enables configuration of auto-upgrades based on the flake source git                                                                                                           |
| [backup](../nix/modules/backup.nix)                       | `custom.backup`             | Automatic backups to rsync.net                                                                                                                                                 |
| [gnome](../nix/modules/gnome.nix)                         | `custom.gnomeDesktop`       | Setup of my desktop environment. Automatically enables common desktop apps                                                                                                     |
| [desktop_apps](../nix/modules/desktop_apps.nix)           | `custom.desktopApps`        | Installation of common desktop apps.                                                                                                                                           |
| [syncthing](../nix/modules/syncthing.nix)                 | `custom.user-syncthing`     | Configures a syncthing instance running as a system daemon as my user                                                                                                          |
| [dynamic_wireguard](../nix/modules/dynamic_wireguard.nix) | `custom.wg`                 | Custom WireGuard VPN module that renders into NetworkManager, systemd-networkd or wg-quick options                                                                             |
| [mail_relay](../nix/modules/mail_relay.nix)               | `custom.mailRelay`          | Preconfiguration for sending mails from the host via my private mailserver                                                                                                     |
| [user_lilly](../nix/modules/user_lilly.nix)               | `custom.user`               | Configures my personal user account as well as home-manger. This pulls in relevant parts from [dotfiles](./nix/dotfiles) and adapts based on the `custom.devEnv.enable` option |
| [dev_env](../nix/modules/dev_env.nix)                     | `custom.devEnv`             | Installs additional software packages and system configurations only relevant when the system is one I'm doing development on                                                  |
| [sane_extra_config](../nix/modules/sane_extra_config.nix) | `hardware.sane.extraConfig` | Helper module to inject additional lines into the SANE config file                                                                                                             |


## Generate an installer ISO

```bash
nix build --no-link --print-out-paths ".#installer"
```

## Generate an LXC template

The `--image-variant` flag can be left out to get a list of valid image formats.

```bash
nixos-rebuild-ng build-image --flake '.#proxmox-lxc' --image-variant proxmox-lxc
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


