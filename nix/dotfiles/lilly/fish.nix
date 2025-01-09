# Configuration for Home-Managers programs.fish options
{
  enable = true;
  shellAbbrs = {
    "ga" = "git add";
    "gst" = "git status";
    "gsw" = "git switch";
    "gl" = "git pull";
    "gp" = "git push";
    "gc" = "git commit";
    "gb" = "git branch";
    "kc" = "kubectl";
    "kubef" = "kubectl --context=ftsell-de";
    "kubem" = "kubectl --context=mafiasi";
    "nix-shell" = "nix-shell --command fish";
  };
}
