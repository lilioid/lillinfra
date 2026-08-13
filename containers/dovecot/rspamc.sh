#!/bin/sh
set -x
exec rspamc --verbose --connect="${RSPAMD_HOST}" --password="${RSPAMD_PASSWORD}" $@
