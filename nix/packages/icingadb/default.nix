{ buildGoModule, fetchFromGitHub, lib }:
buildGoModule (finalAttrs: {
  pname = "icingadb";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "icinga";
    repo = "icingadb";
    rev = "v${finalAttrs.version}";
    hash = "sha256-QxVBJU1lLWW8o838r+pcT2Hn5TXlz0m0yUKtoIjZMdU=";
  };

  vendorHash = "sha256-nnCq7if28O+5yjHS7vAXRMtdKnr4/ARKPCyIfGCdra0=";
  subPackages = [
    "cmd/icingadb/main.go"
  ];

  postInstall = ''
    # give the binary a better name
    mv $out/bin/main $out/bin/icingadb

    # ship database schemas (they are required at runtime)
    mkdir -p $out/share/
    cp -r ./schema $out/share/
  '';

  meta = {
    description = "Icinga configuration and state database supporting multiple environments";
    homepage = "https://icinga.com/docs/icinga-db/latest/doc/";
    sourceProvenance = lib.sourceTypes.fromSource;
    maintainers = with lib.maintainers; [ lilioid ];
    mainProgram = "icingadb";
    licenses = with lib.licenses; [ gpl2 ];
  };
})
