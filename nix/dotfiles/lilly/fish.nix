# configuration for Home-Managers programs.fish options
# https://home-manager-options.extranix.com/?query=programs.fish&release=release-25.05
{
  enable = true;
  shellAliases = {
    "sshpw" = "ssh -o \"PreferredAuthentications=password\"";
    "jwl" = "watch -c -t jj log --no-pager --color=always";
  };
  shellAbbrs = {
    "ga" = "git add";
    "gst" = "git status";
    "gsw" = "git switch";
    "gl" = "git pull";
    "gp" = "git push";
    "gc" = "git commit";
    "gb" = "git branch";
    "jst" = "jj status --no-pager";
    "kc" = "kubectl";
    "kubel" = "kubectl --context=lly-sh";
    "kubem" = "kubectl --context=mafiasi";
    "nix-shell" = "nix-shell --command fish";
  };
}
