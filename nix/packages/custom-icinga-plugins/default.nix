{stdenvNoCC, coreutils, python3}: stdenvNoCC.mkDerivation {
  pname = "custom-icinga-plugins";
  version = "0.1.0";
  src = ./.;

  dontMakeSourcesWritable = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = false;

  nativeBuildInputs = [ coreutils ];
  buildInputs = [
    (python3.withPackages (ps: [ps.requests]))
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    cp -r ./bin/ $out/bin/
    cp -r ./share/ $out/share/
    
    runHook postInstall
  '';
}
