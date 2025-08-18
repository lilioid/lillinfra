# this file is imported into the home-manager option programs.taskwarrior and programs.taskwarrior-sync
{pkgs}: {
  taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    config = {
      sync.local.server_dir = "~/Sync/.tasks";
    };
  };
  taskwarrior-sync = {
    enable = true;
    frequency = "minutely";
  };
}