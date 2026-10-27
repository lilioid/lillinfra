#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "requests>=2.34.2",
# ]
# ///
import argparse
import requests

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
    argp.add_argument(
        "--svc-state", required=True, help="Current state of the notified object"
    )
    argp.add_argument("--check-output", required=True, help="The last checks output")
    argp.add_argument(
        "--last-state-change", required=True, help="Timestamp of the last state change"
    )
    argp.add_argument(
        "--notification-author", required=False, default=None, help="Optional author of a custom notification"
    )
    argp.add_argument(
        "--notification-comment", required=False, default=None, help="Optional content of a custom notification"
    )
    args = argp.parse_args()

    if args.notification_author is not None and args.notification_comment is not None:
        # special handling for custom notifications
        print(f"Sending update/comment to {args.url}")
        resp = requests.post(
            args.url,
            data=f"New comment by {args.notification_author} on the status of {args.svc_name}:\n\n{args.notification_comment}",
            headers={
                "Authorization": f"Bearer {args.auth_token}",
                "Title": f"New comment on {args.svc_name} (currently {args.svc_state})",
                "Priority": "3",
                "Tags": "speech_balloon",
            },
        )
        resp.raise_for_status()
        print("Successfully sent notification")
        
    else:
        TITLE = {
            "OK": f"Service {args.svc_name} is OK",
            "WARNING": f"Service {args.svc_name} is WARNING",
            "CRITICAL": f"Service {args.svc_name} is CRITICAL",
            "UNKNOWN": f"State of service {args.svc_name} is UNKNOWN",
        }
        MESSAGE = {
            "OK": f"{args.svc_name} has changed its status to OK",
            "WARNING": f"{args.svc_name} has changed its status to WARNING (since {args.last_state_change})\n\n{args.check_output}",
            "CRITICAL": f"{args.svc_name} has changed its status to CRITICAL (since {args.last_state_change})\n\n{args.check_output}",
            "UNKNOWN": f"{args.svc_name} has UNKNOWN state (since {args.last_state_change})\n\n{args.check_output}",
        }
        TAGS = {
            "OK": "heavy_check_mark",
            "WARNING": "warning",
            "CRITICAL": "rotating_light",
            "UNKNOWN": "grey_question",
        }
        PRIORITY = {
            "OK": "2",
            "WARNING": "3",
            "CRITICAL": "4",
            "UNKNOWN": "3",
        }

        print(f"Sending notification to {args.url}")
        resp = requests.post(
            args.url,
            data=MESSAGE[args.svc_state],
            headers={
                "Authorization": f"Bearer {args.auth_token}",
                "Title": TITLE[args.svc_state],
                "Priority": PRIORITY[args.svc_state],
                "Tags": TAGS[args.svc_state],
            },
        )
        resp.raise_for_status()
        print("Successfully sent notification")
