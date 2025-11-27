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
      beam27Packages.elixir-ls
      rust-analyzer
    ]
  );
  settings = {
    theme = "base16_custom";
    editor = {
      bufferline = "always";
    };
  };
  themes = {
    base16_custom = {
      inherits = "base16_default";
      "ui.cursor" = {
        modifiers = [ "reversed" ];
      };
    };
  };
}
