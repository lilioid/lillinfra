{ dockerTools, openssh }:
dockerTools.buildLayeredImage {
  name = "git.lly.sh/lilly/openssh";
  tag = "latest";
  config = {
    Cmd = [ "${openssh}/bin/sshd" ];
    ExposedPorts = {
      "22/tcp" = { };
    };
  };
}
