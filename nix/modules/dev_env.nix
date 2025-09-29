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
    };

    environment.systemPackages = with pkgs; [
      nixos-rebuild-ng
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
      nix-output-monitor
      jetbrains.pycharm-professional
      jetbrains.rust-rover
      jetbrains.webstorm
    ];

    programs.fish.shellInit = ''
      fish_add_path $HOME/.krew/bin
    '';
  };
}
