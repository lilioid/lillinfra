#!/usr/bin/env python3
import argparse
import subprocess
import tempfile
import sys


def log(msg: str):
    print(msg, file=sys.stderr)


def realize_config(revision: str, flake_uri: str, config: str) -> str:
    log(f"Bulding configuration of {config} at {revision}")
    return subprocess.check_output([
        "nix",
        "--extra-experimental-features",
        "nix-command flakes",
        "build",
        "--no-link",
        "--print-out-paths",
        f"{flake_uri}?ref={revision}#nixosConfigurations.\"{config}\".config.system.build.toplevel",
    ], encoding="UTF-8").strip()


def compute_diff(closure_a: str, closure_b: str) -> str:
    return subprocess.check_output([
        "nix",
        "--extra-experimental-features",
        "nix-command",
        "store",
        "--quiet",
        "diff-closures",
        closure_a,
        closure_b,
    ], encoding="UTF-8")


def main():
    argp = argparse.ArgumentParser(description="Show diffs of Nixos configurations between current git HEAD and a previous version")
    argp.add_argument("rev_a", help="Revision A of the diff")
    argp.add_argument("rev_b", help="Revision B of the diff")
    argp.add_argument("configuration", help="Which nixosConfiguration output to compare versions of")
    argp.add_argument("--flake", required=True, help="Path to the flake which contains system definitions")
    args = argp.parse_args()

    closure_a = realize_config(args.rev_a, args.flake, args.configuration)
    closure_b = realize_config(args.rev_b, args.flake, args.configuration)
    diff = compute_diff(closure_a, closure_b)

    print(diff)


if __name__ == "__main__":
    main()

