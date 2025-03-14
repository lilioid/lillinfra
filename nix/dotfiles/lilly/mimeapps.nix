# Options for home-managers xdg.mimeApps
# See https://home-manager-options.extranix.com/?query=mimeApps&release=release-24.11
{
  enable = true;
  defaultApplications = {
    "application/pdf" = [ "okularApplication_pdf.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
  };
}
