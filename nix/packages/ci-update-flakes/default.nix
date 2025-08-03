{ lib, pkgs, writeShellApplication }: writeShellApplication {
  name = "ci-update-flakes";
  runtimeInputs = with pkgs; [
    nix
    git
    curl
  ];
  text = builtins.readFile ./ci-update-flakes.sh;
}