# this file is imported into the home-manager option programs.taskwarrior and programs.taskwarrior-sync
{pkgs}: {
  taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      sync.local.server_dir = "~/Sync/.tasks";
      color = {
        alternate = "";
        scheduled = "on rgb345";
        calendar.weekend = "";
        uda.priority.H = "white on red";
      };
    };
  };
  taskwarrior-sync = {
    enable = true;
    package = pkgs.taskwarrior3;
    frequency = "minutely";
  };
}
