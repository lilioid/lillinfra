# Configuration for Home-Managers programs.fish options
{
  enable = true;
  shellAliases = {
    "sshpw" = "ssh -o \"PreferredAuthentications=password\"";
  };
  shellAbbrs = {
    "ga" = "git add";
    "gst" = "git status";
    "gsw" = "git switch";
    "gl" = "git pull";
    "gp" = "git push";
    "gc" = "git commit";
    "gb" = "git branch";
    "kc" = "kubectl";
    "kubel" = "kubectl --context=lly-sh";
    "kubem" = "kubectl --context=mafiasi";
    "nix-shell" = "nix-shell --command fish";
  };
}
