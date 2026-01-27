import * as core from "@actions/core"
import { spawnSync } from "node:child-process";

inputs = {
  ref1: core.getInput("ref1"),
  ref2: core.getInput("ref2"),
  prNumber: core.getInput("pr-number"),
  nixSystems: core.getInput("nix-systems"),
};
procEnv = {
  NIX_CONFIG: `
    store = local?root=/shared-nix-store
  `,
};

core.info("Installing nvd for fancy diffs")
spawnSync("nix", [ "profile", "add", "nixpkgs#nvd" ], { env: procEnv });

