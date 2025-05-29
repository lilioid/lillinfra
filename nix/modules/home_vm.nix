{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # boot config
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
  };

  # general os config
  services.qemuGuest.enable = true;
  documentation.nixos.enable = false;

  # configure systemd-networkd to listen for DHCP and router advertisements on all ethernet interfaces by default
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."99-default-ether" = {
      matchConfig = {
        Type = "ether";
        Kind = "!veth";
      };
      DHCP = "yes";
      networkConfig.IPv6AcceptRA = lib.mkDefault true;
    };
  };

  # ssh server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
