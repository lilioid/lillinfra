#!/bin/sh
exec rspamc --connect="${RSPAMD_HOST}" --password="${RSPAMD_PASSWORD}" $@
