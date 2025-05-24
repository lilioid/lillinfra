{
  pkgs,
  python3,
}:
python3.pkgs.buildPythonApplication {
  pname = "hetzner-ddns";
  version = "1.0.0";
  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "ftsell";
    repo = "hetzner_ddns";
    rev = "e5917b232746d70dc39ba7d4e18cf5cde9e265c5";
    hash = "sha256-jex21Hd6duxpx8NLh/u+L9/PrtQMMHxao/J959A3oNo=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    requests
    pydantic
    flit-core
  ];
}
