{
  lib,
  pkgs,
  config,
}:
{
  enable = true;
  defaultEditor = true;
  extraPackages = lib.mkIf config.custom.devEnv.enable (
    with pkgs;
    [
      yaml-language-server
      nil
      marksman
      python312Packages.python-lsp-server
      python312Packages.python-lsp-ruff
      rust-analyzer
    ]
  );
  settings = {
    theme = "base16_default_light";
    editor = {
      bufferline = "always";
    };
  };
}
