{ pkgs, lib, config, ... }: {
  custom.preset = "aut-sys-vm";

  # mount shared filesystem for large file uploads
  environment.systemPackages = with pkgs; [ ceph-client ];
  environment.etc."ceph/ceph.conf".text = ''
    [global]
          fsid = 13342310-b28f-4d7b-a893-af2984583a92
          mon_host = [v2:[2a07:c481:2:2::101]:3300/0,v1:[2a07:c481:2:2::101]:6789/0] [v2:[2a07:c481:2:2::102]:3300/0,v1:[2a07:c481:2:2::102]:6789/0] [v2:[2a07:c481:2:2::103]:3300/0,v1:[2a07:c481:2:2::103]:6789/0]
          keyfile=${config.sops.secrets."aut-sys-ceph/large-file-share/secret".path}
  '';
  fileSystems."ceph-large-file-shares" = {
    # mount from ceph with user "large-file-share", cephfs named "data", and subvolume "large-file-share"
    device = "large-file-share@.data=/volumes/_nogroup/large-file-share/e5fb1393-626e-41a0-8e61-630b16b3efb0";
    mountPoint = "/srv/large-file-share";
    fsType = "ceph";
    options = [
      "rw"
      "noatime"
      "acl"
      "read_from_replica=localize"
    ];
    neededForBoot = false;
    noCheck = true;
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "li@lly.sh";

  custom.webhosting = {
    enable = true;
    users.skye = {
      domains = [ "lihesys.de" ];
      sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2vP9rQP6f6o61VUssBFvgY+O2sZ7T4OGaNkJTAk8G2 skye";
    };
    users.lilly = {
      shell = pkgs.fish;
      sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzGnNKyn6jmVxig4SRnTBfpi6okPU2aOHPwFnAPTxJm ftsell@ftsell.de";
    };
  };

  custom.backup = {
    enable = true;
    backupDirectories = lib.map
      (i: "/home/${i}")
      (lib.attrNames config.custom.webhosting.users);
    destinations."rsync.net".path = "ssh://zh4525@zh4525.rsync.net/./backups/borg-repo";
  };

  sops.secrets."aut-sys-ceph/large-file-share/secret" = {};

  # DO NOT CHANGE
  # this defines the first version of NixOS that was installed on the machine so that programs with non-migratable data files are kept compatible
  home-manager.users.lilly.home.stateVersion = "26.05";
  system.stateVersion = "26.05";
}
