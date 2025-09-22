# this file is imported into the home-manager option programs.taskwarrior and programs.taskwarrior-sync
{config, pkgs, lib}: {
  taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      recurrence = lib.mkDefault 0;
      color = {
        alternate = "";
        scheduled = "on rgb345";
        calendar.weekend = "";
        uda.priority.H = "white on red";
      };
    };
    extraConfig = ''
      include ${config.sops.templates."lilly/taskrc".path}
    '';
  };
  taskwarrior-sync = {
    enable = true;
    package = pkgs.taskwarrior3;
    frequency = "*-*-* *:00,10,20,30,40,50:00"; # every 10 minutes
  };
}
