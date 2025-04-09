#!/usr/bin/env fish

read -l -P "Registry: " SERVER
read -l -P "Username: " USERNAME
read -ls -P "Password: " PW

kubectl create secret docker-registry --docker-server=$SERVER --docker-username=$USERNAME --docker-password=$PW --dry-run=client test -o json | jq '.data.".dockerconfigjson"' -r | base64 -d | jq
