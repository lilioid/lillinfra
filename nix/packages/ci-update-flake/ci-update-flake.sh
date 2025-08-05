#!/usr/bin/env bash

cd "${CI_WORKSPACE}"

echo "Updating flake inputs"
nix --extra-experimental-features "nix-command flakes" --accept-flake-config flake update

echo "Commiting changes"
git config --local user.name "Woodpecker CI"
git config --local user.email "woodpecker-ci@noreply.lly.sh"
git switch -c "update-flake-inputs"
git commit flake.nix "./flake.lock" -m "update flake inputs"

echo "Pushing changes"
git push --force-with-lease origin update-flake-inputs

echo "Creating Forgejo PR"
curl --request POST \
  --header "Content-Type: application/json" \
  --data "{\"assignee\": \"${CI_REPO_OWNER}\", \"base\": \"update-flake-inputs\", \"head\": \"${CI_REPO_DEFAULT_BRANCH}\", \"title\": \"Update flake inputs\", \"body\": \"Automatic Ci update of flake inputs.\nSee generated comments below for the effects this has on derivation outputs\"}" \
  "${CI_FORGE_URL}/repos/${CI_REPO_OWNER}/${CI_REPO_NAME}"
