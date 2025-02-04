#!/usr/bin/env sh
set -eu

TOKEN=$(kubectl --context=lly-sh -n kubernetes-dashboard create token dashboard-user)
wl-copy "$TOKEN"

echo "Url:        :  http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo ""
echo "Access Token (copied to clipboard):  $TOKEN"

kubectl --context=lly-sh proxy > /dev/null
