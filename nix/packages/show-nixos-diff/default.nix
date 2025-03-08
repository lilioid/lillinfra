{
  lib,
  pkgs,
  python3,
}:
python3.pkgs.buildPythonApplication {
  name = "show-nixos-diff";
  version = "1.0.2";
  src = ./.;
  pyproject = false;
  propagatedBuildInputs = with pkgs; [
    nix
    nixos-rebuild
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ./show-nixos-diff.py $out/bin/,show-nixos-diff

    runHook postInstall
  '';

  meta = {
    mainProgram = ",show-nixos-diff";
    matinaners = [ lib.maintainers.lilioid ];
    platforms = python3.meta.platforms;
  };
}
