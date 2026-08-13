#!/bin/sh
. /etc/dovecot/rspamc.env
exec rspamc --verbose --connect="${RSPAMD_HOST}" --password="${RSPAMD_PASSWORD}" $@
