{ dockerTools, harmonia }: dockerTools.buildLayeredImage {
  name = "git.lly.sh/lilly/harmonia";
  tag = "latest";
  config = {
    Entrypoint = [ "${harmonia.packages.x86_64-linux.harmonia}/bin/harmonia" ];
  };
}

