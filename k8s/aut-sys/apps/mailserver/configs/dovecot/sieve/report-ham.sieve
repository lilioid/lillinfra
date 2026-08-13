require ["imapsieve", "environment", "variables", "copy", "vnd.dovecot.pipe", "vnd.dovecot.environment"];

if allof(
  environment :is "imap.cause" "copy",
  environment :is "imap.mailbox" "INBOX"
) {	
  pipe :copy "rspamc" [ "--deliver", "${env.vnd.dovecot.username}", "learn_ham" ];
}
