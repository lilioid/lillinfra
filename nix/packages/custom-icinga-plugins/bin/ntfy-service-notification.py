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
        "--svc-name",
        required=True,
        help="Name of the object that is being notified about",
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
                title=f"Scheduled downtime for {args.svc_name} just started",
                msg=f"Scheduled Downtime for service {args.svc_name} (currently {args.notification_state}) just went into effect.\n\n{args.notification_comment}",
                tags=["stopwatch"],
                priority=2,
            )
        case "DOWNTIMEEND":
            send(
                args,
                title=f"Scheduled downtime for {args.svc_name} ended",
                msg=f"Scheduled Downtime of service {args.svc_name} just ended. Service is currently {args.notification_state}",
                tags=["stopwatch"],
                priority="2",
            )
        case "DONWTIMEREMOVED":
            send(
                args,
                title=f"Scheduled downtime for {args.svc_name} has been deleted",
                tags=["stopwatch"],
                priority=1,
            )
        case "CUSTOM":
            send(
                args,
                title=f"Notification for {args.svc_name}",
                msg=f"New comment or custom notification by {args.notification_author} on the status of {args.svc_name} (currently {args.notification_state})\n\n{args.notification_comment}",
                tags=["speech_balloon"],
            )
        case "ACKNOWLEDGEMENT":
            send(
                args,
                title=f"Service problem for {args.svc_name} was acknowledged",
                msg=f"{args.notification_author} has acknowledged the ongoing problem of {args.svc_name} currently in {args.notification_state} state\n\n{args.notification_comment}",
                tags=["speech_balloon"],
                priority=2,
            )
        case "PROBLEM":
            match args.notification_state:
                case "WARNING":
                    send(
                        args,
                        title=f"Service {args.svc_name} is WARNING",
                        msg=f"{args.svc_name} is in state {args.notification_state} (since {last_state_change})\n\n{args.check_output}",
                        tags=["warning"],
                    )
                case "CRITICAL":
                    send(
                        args,
                        title=f"Service {args.svc_name} is CRITICAL",
                        msg=f"{args.svc_name} has changed its status to CRITICAL (since {last_state_change})\n\n{args.check_output}",
                        tags=["rotating_light"],
                        priority=4,
                    )
                case "UNKNOWN":
                    send(
                        args,
                        title=f"State of service {args.svc_name} is UNKNOWN",
                        msg=f"{args.service_name} has UNKNOWN state since {last_state_change}\n\n{args.check_output}",
                        tags=["grey_question"],
                    )
                case "OK":
                    raise ValueError(
                        "A problem notification with current state OK does not make sense"
                    )
        case "RECOVERY":
            match args.notification_state:
                case "OK":
                    send(
                        args,
                        title=f"Service {args.svc_name} has recovered",
                        msg=f"{args.svc_name} has changed its status back to OK\n\n{args.check_output}",
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
