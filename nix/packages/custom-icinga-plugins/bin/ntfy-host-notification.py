#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "requests>=2.34.2",
# ]
# ///
import argparse
import requests
from datetime import datetime, UTC


def send(args, title, msg="", tags: list[str] = [], priority: int = 3):
    print(f"Sending notification '{title}' to {args.url}")
    resp = requests.post(
        args.url,
        data=msg,
        headers={
            "Authorization": f"Bearer {args.auth_token}",
            "Title": title,
            "Priority": str(priority),
            "Tags": ",".join(tags),
        },
    )
    resp.raise_for_status()
    print("Successfully sent notification")


if __name__ == "__main__":
    argp = argparse.ArgumentParser(
        prog="send-gotify-notification.py",
        description="Send a notification via the gotify API",
    )
    argp.add_argument("--url", required=True, help="NTFY server URL + topic")
    argp.add_argument(
        "--auth-token", required=True, help="Application authentication token"
    )
    argp.add_argument(
        "--host-name",
        required=True,
        help="Name of the host that is being notified about",
    )
    argp.add_argument("--check-output", required=True, help="The last checks output")
    argp.add_argument(
        "--last-state-change", required=True, help="Timestamp of the last state change"
    )
    argp.add_argument(
        "--notification-type", required=True, help="Icinga notification type"
    )
    argp.add_argument(
        "--notification-state", required=True, help="Icinga notification state"
    )
    argp.add_argument(
        "--notification-author",
        required=False,
        default=None,
        help="Optional author of a custom notification",
    )
    argp.add_argument(
        "--notification-comment",
        required=False,
        default=None,
        help="Optional content of a custom notification",
    )
    args = argp.parse_args()

    last_state_change = datetime.fromtimestamp(
        int(args.last_state_change), UTC
    ).isoformat(" ", "minutes")

    match args.notification_type:
        case "DOWNTIMESTART":
            send(
                args,
                title=f"Scheduled downtime for {args.host_name} just started",
                msg=f"Scheduled Downtime for host {args.host_name} (currently {args.notification_state}) just went into effect.\n\n{args.notification_comment}",
                tags=["stopwatch"],
                priority=2,
            )
        case "DOWNTIMEEND":
            send(
                args,
                title=f"Scheduled downtime for {args.host_name} ended",
                msg=f"Scheduled Downtime of host {args.host_name} just ended. Host is currently {args.notification_state}",
                tags=["stopwatch"],
                priority="2",
            )
        case "DONWTIMEREMOVED":
            send(
                args,
                title=f"Scheduled downtime for {args.host_name} has been deleted",
                tags=["stopwatch"],
                priority=1,
            )
        case "CUSTOM":
            send(
                args,
                title=f"Notification for {args.host_name}",
                msg=f"New comment or custom notification by {args.notification_author} on the status of {args.host_name} (currently {args.notification_state})\n\n{args.notification_comment}",
                tags=["speech_balloon"],
            )
        case "ACKNOWLEDGEMENT":
            send(
                args,
                title=f"Host problem for {args.host_name} was acknowledged",
                msg=f"{args.notification_author} has acknowledged the ongoing problem of {args.host_name} currently in {args.notification_state} state\n\n{args.notification_comment}",
                tags=["speech_balloon"],
                priority=2,
            )
        case "PROBLEM":
            match args.notification_state:
                case "DOWN":
                    send(
                        args,
                        title=f"Host {args.host_name} is DOWN",
                        msg=f"{args.host_name} has gone DOWN (since {last_state_change})\n\n{args.check_output}",
                        tags=["rotating_light"],
                        priority=4,
                    )
                case _:
                    raise ValueError(
                        f"A problem notification with current state {args.notification_state} does not make sense"
                    )
        case "RECOVERY":
            match args.notification_state:
                case "UP":
                    send(
                        args,
                        title=f"Host {args.host_name} has recovered",
                        msg=f"{args.host_name} back UP\n\n{args.check_output}",
                        tags=["heavy_check_mark"],
                        priority=2,
                    )
                case _:
                    raise ValueError(
                        f"A recovery notification with current state {args.notification_state} does not make sense"
                    )
        case _:
            raise ValueError(
                f"Unhandlable notification type and state {args.notification_type}, {args.notification_state}"
            )
