require ["imapsieve", "environment", "variables", "copy", "vnd.dovecot.pipe", "vnd.dovecot.environment"];

if allof(
  environment :is "imap.cause" "COPY",
  environment :is "imap.mailbox" "Junk"
) {	
  pipe :copy "rspamc" [ "--deliver", "${env.vnd.dovecot.username}", "learn_spam" ];
}

