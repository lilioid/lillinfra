{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.devEnv;
in
{
  options = {
    custom.devEnv = {
      enable = lib.options.mkEnableOption "installation of development utilities";
    };
  };

  config = lib.mkIf cfg.enable {
    # add aarch64-linux as supported binary format if this is an x64 system
    # this is needed to support nixos-rebuild for systems in aarch64 format
    boot.binfmt.emulatedSystems = lib.mkIf (config.nixpkgs.hostPlatform.system == "x86_64-linux") [
      "aarch64-linux"
    ];
  
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
      daemon.settings = {
        "default-address-pools" = [ { base = "10.206.209.0/24"; size = 24; } ];
      };
    };

    environment.systemPackages = with pkgs; [
      nixpkgs-fmt
      nixos-rebuild-ng
      sops
      git-crypt
      gnupg
      glab
      helmfile
      jq
      watchexec
      ansible
      ansible-lint
      direnv
      dig
      nodejs
      nodePackages.pnpm
      bun
      python3
      uv
      kubectl
      krew
      kubernetes-helm
      k9s
      pass
      sshuttle
      rustup
      pre-commit
      openssl
      gleam
      erlang
      terraform
      ietf-cli
      sequoia-sq
      subnetcalc
      attic-client
      nil
      reuse
      tig
      go
      nix-output-monitor
      distrobox
      jetbrains.pycharm-professional
      jetbrains.rust-rover
      jetbrains.webstorm
      jetbrains.goland
    ];

    programs.fish.shellInit = ''
      fish_add_path $HOME/.krew/bin
    '';
  };
}
