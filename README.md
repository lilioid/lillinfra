# lillinfra

My personal infrastructure *configuration-as-code* repository.
Its goal is to contain all necessary configuration for my different servers and workstations to allow easier and documented setups.

This repository contains the following things:

- [./docs](./docs): Some documentation about various kinks. Also contains some notes e.g. certain annotations I use on some kubernetes objects which I can never remember.
- [./nix](./nix): NixOS definitons for most of my systems. *#AnsibleNeinDanke*.
- [./k8s](./k8s): Most applications I'm running defined as Kubernetes manifests.
- [./containers](./containers): Custom container image definitions that are automatically built by CI.


### How to get the public age key of a host

```shell
ssh-keyscan | nix-shell -p ssh-to-age --command "ssh-to-age"
```
