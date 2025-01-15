{ lib, config, ... }:
let
  cfg = config.custom.mailRelay;
in
{
  options = {
    custom.mailRelay = {
      enable = lib.options.mkEnableOption "mail relay via noreply.lly.sh";
    };
  };

  config = lib.mkIf cfg.enable {
    services.opensmtpd = {
      enable = true;
      serverConfiguration = ''
        listen on lo hostname ${config.networking.fqdnOrHostName}
        listen on socket

        table secrets file:/run/secrets/smtpd_secrets
        table aliases {
          root = admin@lly.sh
        }

        action "local" forward-only \
          alias <aliases>

        action "outbound" relay \
          host smtp+tls://noreply@mail.lly.sh:587 \
          mail-from ${config.networking.fqdnOrHostName}@noreply.lly.sh \
          auth <secrets>

        match from local for local action "local"
        match for domain "lly.sh" action "outbound"
      '';
    };

    sops.secrets."smtpd_secrets" = {
      sopsFile = ../data/secrets/mail_relay.yml;
      owner = "smtpd";
      restartUnits = [ "opensmtpd.service" ];
    };
  };
}
