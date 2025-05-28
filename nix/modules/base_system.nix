{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  # settings for nix and nixos
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;
  nix.channel.enable = false;
  nix.nixPath = [ "nixpkgs=${lib.cleanSource pkgs.path}" ];
  nix.settings = {
    tarball-ttl = 60;
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://babe-do-you-need-anything-from-the-nix.store/lillinfra"
    ];
    trusted-public-keys = [
      "lillinfra:2tw1d8pQ4EmiFJ/mEiTUJYFP65txNUpyIBNdnZeqRjY="
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # link flake source into /etc/nixos
  environment.etc."nixos".source = ../../.;

  # locale settings
  time.timeZone = lib.mkDefault "Europe/Berlin";
  i18n = {
    # https://man.archlinux.org/man/locale.7
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    extraLocaleSettings = lib.genAttrs [
      "LC_CTYPE"
      "LC_NUMERIC"
      "LC_TIME"
      "LC_COLLATE"
      "LC_MONETARY"
      "LC_PAPER"
      "LC_NAME"
      "LC_ADDRESS"
      "LC_TELEPHONE"
      "LC_MEASUREMENT"
      "LC_IDENTIFICATION"
    ] (key: "de_DE.UTF-8");
  };
  services.xserver.xkb.layout = lib.mkDefault "de";

  # vconsole
  console = {
    font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u16n.psf.gz";
    packages = lib.mkDefault [ pkgs.terminus_font ];
    keyMap = lib.mkDefault "de";
    useXkbConfig = lib.mkDefault true;
  };

  # software settings
  home-manager.useGlobalPkgs = lib.mkDefault true;
  documentation.man.generateCaches = false;
  documentation.nixos.includeAllModules = true;
  documentation.nixos.options.warningsAreErrors = false;
  programs.command-not-found.enable = false;

  # derive sops key from ssh key if ssh is enable and configure host sepcific secrets
  sops.age.sshKeyPaths = lib.mkIf config.services.openssh.enable [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.defaultSopsFile = ../data/host-secrets + "/${config.networking.fqdnOrHostName}.yml";

  # additional apps
  programs.mtr.enable = true;
  programs.git.enable = true;
  programs.htop = {
    enable = true;
    settings = {
        hide_kernel_threads = true;
        hide_userland_threads = true;
        highlight_base_name = true;
    };
  };
  environment.systemPackages = with pkgs; [
    helix
    emacs
    tig
    age
  ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  environment.localBinInPath = true;
}
