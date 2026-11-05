#!/usr/bin/env python3
import argparse
import subprocess


def main():
    argp = argparse.ArgumentParser(
        prog="Switch to a Nixos System that is a raw store path"
    )
    argp.add_argument(
        "action",
        choices=["switch", "boot", "test", "dry-activate", "check"],
        help="Switch action to perform",
    )
    argp.add_argument("system_closure", help="nix store path of the system closure")
    argp.add_argument(
        "--profile",
        nargs=1,
        default="system",
        help="The name of the nix profile to use for generation tracking",
    )
    args = argp.parse_args()

    realize_closure(args.system_closure)

    match args.action:
        case "test" | "dry-activate" | "check":
            activate_system(args.system_closure, args.action)
        case "switch" | "boot":
            update_profile(args.profile, args.system_closure)
            activate_system(args.system_closure, args.action)


def realize_closure(system_closure: str):
    print("Realizing system closure on local system")
    subprocess.run(
        ["nix-store", "--realize", system_closure],
        check=True,
    )


def update_profile(profile: str, system_closure: str):
    print(
        "Updating nix profile to point current generation at specified system closure"
    )
    subprocess.run(
        [
            "nix-env",
            "--profile",
            f"/nix/var/nix/profiles/{profile}",
            "--set",
            system_closure,
        ],
        check=True
    )


def activate_system(system_closure: str, action: str):
    print(f"Performing activation action {action} on specified system closure")
    subprocess.run(
        [f"{system_closure}/bin/switch-to-configuration", action],
        check=True,
    )


if __name__ == "__main__":
    main()
