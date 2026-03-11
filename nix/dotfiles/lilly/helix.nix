{
  lib,
  pkgs,
  config,
}:
{
  enable = true;
  defaultEditor = false;
  extraPackages = lib.mkIf config.custom.devEnv.enable (
    with pkgs;
    [
      yaml-language-server
      nil
      marksman
      python312Packages.python-lsp-server
      python312Packages.python-lsp-ruff
      ruff
      beam27Packages.elixir-ls
      rust-analyzer
    ]
  );
  settings = {
    theme = "rose_pine";
    editor = {
      bufferline = "always";
    };
  };
}
