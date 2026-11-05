{ lib, python3, nix }:
python3.pkgs.buildPythonApplication {
  pname = "switch-nixos-raw";
  version = "v0.0.1";
  pyproject = false;
  src = ./.;

  buildInputs = [ nix ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ./switch-nixos-raw.py $out/bin/switch-nixos-raw

    runHook postInstall
  '';

  meta = {
    mainProgra = "switch-nixos-raw";
    maintainers = with lib.maintainers; [ lilioid ];
    platforms = python3.meta.platforms;
  };
}
