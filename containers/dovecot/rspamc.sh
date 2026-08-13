#!/bin/sh
set -x
exec rspamc --connect="${RSPAMD_HOST}" --password="${RSPAMD_PASSWORD}" $@
