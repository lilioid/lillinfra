{ lib, pkgs, writeShellApplication }: writeShellApplication {
  name = "ci-update-flake";
  runtimeInputs = with pkgs; [
    nix
    git
    curl
  ];
  text = builtins.readFile ./ci-update-flake.sh;
}