#!/usr/bin/env python3
import sys
from pathlib import Path
import argparse
import subprocess
import json
from pprint import pprint


def log(msg):
    print(msg, file=sys.stderr)


def load_data(lillinfra_path: Path):
    data_path = lillinfra_path / "nix" / "data" / "wg_vpn.nix"
    log(f"Loading data from {data_path}")
    data = subprocess.check_output([
       "nix",
       "eval",
       "--json",
       "--impure",
       "--expr",
       f"import {data_path}",
    ])
    return json.loads(data)


def load_privkey(lillinfra_path: Path, peer: str) -> str:
    data_path = lillinfra_path / "nix" / "data" / "secrets" / f"{peer}.yml"
    log(f"Loading privkey from {data_path}")
    data = subprocess.check_output([
        "sops",
        "--decrypt",
        "--extract",
        '["wg_vpn"]["privkey"]',
        data_path
    ])
    return data.decode("UTF-8")
    

def render_config(local_data: dict, privkey: str, known_servers: dict, network_data: dict) -> str:
    log(f"Rendering configuration")
    # local interface conf
    conf = (
        f"[Interface]\n"
        f"PrivateKey = {privkey}\n"
        f"DNS={','.join(network_data['dns'])}\n"
    )
    for i_addr in local_data["allowedIPs"]:
        conf += f"Address={i_addr}\n"

    # peer conf
    for i_server_name, i_server_data in known_servers.items():
        conf += (
            f"\n"
            f"[Peer]\n"
            f"# {i_server_name}\n"
            f"PublicKey={i_server_data['pubKey']}\n"
            f"AllowedIPs={','.join(i_server_data['allowedIPs'])}\n"
            f"Endpoint={i_server_data['endpoint']}\n"
            f"PersistentKeepalive={'25' if local_data['keepalive'] else '0'}\n"
        )

    return conf


def main():
    argp = argparse.ArgumentParser()
    mode = argp.add_mutually_exclusive_group(required=True)
    mode.add_argument("--qrcode", action="store_const", const="qrcode", dest="mode", help="Render the config as QR-Code")
    mode.add_argument("--text", action="store_const", const="text", dest="mode", help="Display the config as text")
    argp.add_argument("peer", help="Which peers config should be shown")
    argp.add_argument("--lillinfra", type=Path, default=Path("/home/lilly/Projects/lillinfra/"), help="Path to the lillinfra repository")
    args = argp.parse_args()

    all_data = load_data(args.lillinfra)
    local_data = all_data["knownClients"][args.peer]
    server_data = all_data["knownServers"]
    network_data = all_data["network"]
    privkey = load_privkey(args.lillinfra, args.peer)

    config = render_config(local_data, privkey, server_data, network_data)

    match args.mode:
        case "text":
            print(config)
        case "qrcode":
            subprocess.check_call([
                "qrencode",
                "--type=ansiutf8",
                "--output=/dev/stdout",
                config
            ])


if __name__ == "__main__":
    main()

