{
  lib,
  pkgs,
  python3,
}:
python3.pkgs.buildPythonApplication {
  pname = "show-nixos-diff";
  version = "1.0.5";
  src = ./.;
  pyproject = false;
  buildInputs = with pkgs; [
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
    maintainers = [ lib.maintainers.lilioid ];
    platforms = python3.meta.platforms;
  };
}
