{
  lib,
  pkgs,
  python3,
}:
python3.pkgs.buildPythonApplication {
  pname = ",show-wg-conf";
  version = "1.0.0";
  src = ./.;
  pyproject = false;
  buildInputs = with pkgs; [ qrencode ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ./show-wg-conf.py $out/bin/,show-wg-conf

    runHook postInstall
  '';

  meta = {
    mainProgram = ",show-wg-conf";
    matinaners = [ lib.maintainers.lilioid ];
    platforms = python3.meta.platforms;
  };
}
