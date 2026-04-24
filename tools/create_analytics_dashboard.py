"""One-shot script to create the "App Activity" Insights dashboard in Directus.

Idempotent-ish: if a dashboard with the same name already exists it is
deleted (with all its panels) and re-created, so repeated runs converge to
the configuration declared here.

Usage:
    python tools/create_analytics_dashboard.py                  # default: connected
    python tools/create_analytics_dashboard.py --target cioafrica
    python tools/create_analytics_dashboard.py --target all

Run once per environment after phase 3 ships.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

TARGETS = {
    "connected": {
        "base_url": "https://admin.connected.go.ke",
        "token": "Xjm1QumX897xml1vV4zwLj6xyWVhTVO_",
    },
    "cioafrica": {
        "base_url": "https://subscriptions.cioafrica.co",
        "token": "oEgjgIbG1oyqMKscjSsQLfPznOaOUzW7",
    },
}

DASHBOARD_NAME = "App Activity - Mobile App"

BASE_URL = ""
TOKEN = ""


def _request(method: str, path: str, body: dict | list | None = None) -> dict:
    url = f"{BASE_URL}{path}"
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, method=method, data=data)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            if not raw:
                return {}
            return json.loads(raw)
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {path} -> {e.code}: {body_text}") from e


def find_existing_dashboard(name: str) -> str | None:
    q = urllib.parse.urlencode({"filter[name][_eq]": name, "fields": "id,panels"})
    resp = _request("GET", f"/dashboards?{q}")
    hits = resp.get("data", [])
    return hits[0]["id"] if hits else None


def delete_dashboard_and_panels(dashboard_id: str) -> None:
    resp = _request("GET", f"/panels?filter[dashboard][_eq]={dashboard_id}&fields=id&limit=-1")
    panel_ids = [p["id"] for p in resp.get("data", [])]
    if panel_ids:
        _request("DELETE", "/panels", panel_ids)
    _request("DELETE", f"/dashboards/{dashboard_id}")


def create_dashboard() -> str:
    resp = _request(
        "POST",
        "/dashboards",
        {
            "name": DASHBOARD_NAME,
            "icon": "insights",
            "color": "#44A0D3",
            "note": "Rolling view of mobile-app engagement. Data flows in from the app's ActivityLogger.",
        },
    )
    return resp["data"]["id"]


def panel(
    dashboard_id: str,
    *,
    name: str,
    type_: str,
    x: int,
    y: int,
    w: int,
    h: int,
    options: dict,
    icon: str | None = None,
    color: str | None = None,
    note: str | None = None,
) -> dict:
    body = {
        "dashboard": dashboard_id,
        "name": name,
        "type": type_,
        "position_x": x,
        "position_y": y,
        "width": w,
        "height": h,
        "options": options,
        "show_header": True,
    }
    if icon:
        body["icon"] = icon
    if color:
        body["color"] = color
    if note:
        body["note"] = note
    return body


def run_for_target(name: str, config: dict) -> int:
    global BASE_URL, TOKEN
    BASE_URL = config["base_url"]
    TOKEN = config["token"]
    print(f"\n=== Target: {name} ({BASE_URL}) ===")

    existing = find_existing_dashboard(DASHBOARD_NAME)
    if existing:
        print(f"Found existing dashboard {existing}; replacing.")
        delete_dashboard_and_panels(existing)

    dashboard_id = create_dashboard()
    print(f"Created dashboard {dashboard_id}")

    COLLECTION = "app_activity_logs"
    LAST_7D = {"occurred_at": {"_gte": "$NOW(-7 days)"}}
    LAST_30D = {"occurred_at": {"_gte": "$NOW(-30 days)"}}

    panels = [
        # Row 0 - header label
        panel(
            dashboard_id,
            name="Header",
            type_="label",
            x=0, y=0, w=24, h=2,
            options={
                "text": "App Activity - Mobile App",
                "color": "#44A0D3",
            },
        ),
        # Row 1 - 4 metric tiles (last 7 days)
        panel(
            dashboard_id,
            name="Events - Last 7 Days",
            type_="metric",
            icon="event_note",
            color="#44A0D3",
            x=0, y=2, w=6, h=6,
            options={
                "collection": COLLECTION,
                "field": "id",
                "function": "count",
                "filter": LAST_7D,
            },
        ),
        panel(
            dashboard_id,
            name="Unique Users - Last 7 Days",
            type_="metric",
            icon="group",
            color="#4C9B46",
            x=6, y=2, w=6, h=6,
            options={
                "collection": COLLECTION,
                "field": "user_id",
                "function": "countDistinct",
                "filter": {
                    "_and": [
                        {"occurred_at": {"_gte": "$NOW(-7 days)"}},
                        {"user_id": {"_nnull": True}},
                    ],
                },
            },
        ),
        panel(
            dashboard_id,
            name="OTP Logins - Last 7 Days",
            type_="metric",
            icon="login",
            color="#F79016",
            x=12, y=2, w=6, h=6,
            options={
                "collection": COLLECTION,
                "field": "id",
                "function": "count",
                "filter": {
                    "_and": [
                        {"action": {"_eq": "otp_login"}},
                        {"occurred_at": {"_gte": "$NOW(-7 days)"}},
                    ],
                },
            },
        ),
        panel(
            dashboard_id,
            name="Meeting Requests - Last 7 Days",
            type_="metric",
            icon="handshake",
            color="#8f3b9d",
            x=18, y=2, w=6, h=6,
            options={
                "collection": COLLECTION,
                "field": "id",
                "function": "count",
                "filter": {
                    "_and": [
                        {"action": {"_eq": "meeting_request_sent"}},
                        {"occurred_at": {"_gte": "$NOW(-7 days)"}},
                    ],
                },
            },
        ),
        # Row 2 - distribution charts (last 30 days)
        panel(
            dashboard_id,
            name="Events by Action - Last 30 Days",
            type_="pie-chart",
            x=0, y=8, w=12, h=12,
            options={
                "collection": COLLECTION,
                "column": "action",
                "field": "id",
                "fn": "count",
                "filter": LAST_30D,
                "showLabels": True,
                "legend": "right",
                "donut": True,
            },
        ),
        panel(
            dashboard_id,
            name="Events by Platform - Last 30 Days",
            type_="pie-chart",
            x=12, y=8, w=12, h=12,
            options={
                "collection": COLLECTION,
                "column": "platform",
                "field": "id",
                "fn": "count",
                "filter": LAST_30D,
                "showLabels": True,
                "legend": "right",
            },
        ),
        # Row 3 - meeting funnel
        panel(
            dashboard_id,
            name="Meeting Funnel - Last 30 Days",
            type_="bar-chart",
            x=0, y=20, w=24, h=10,
            options={
                "collection": COLLECTION,
                "xAxis": "action",
                "yAxis": "id",
                "function": "count",
                "horizontal": True,
                "decimals": 0,
                "filter": {
                    "_and": [
                        {
                            "action": {
                                "_in": [
                                    "meeting_request_sent",
                                    "meeting_accepted",
                                    "meeting_declined",
                                    "meeting_cancelled",
                                ],
                            },
                        },
                        {"occurred_at": {"_gte": "$NOW(-30 days)"}},
                    ],
                },
            },
        ),
    ]

    for p in panels:
        created = _request("POST", "/panels", p)
        pid = created["data"]["id"]
        print(f"  + {p['name']:<40s} ({p['type']:<10s}) -> {pid}")

    print(f"Done. Open: {BASE_URL}/admin/insights/{dashboard_id}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--target",
        default="connected",
        choices=[*TARGETS.keys(), "all"],
        help="Which Directus instance to target (default: connected)",
    )
    args = parser.parse_args()

    targets = TARGETS.items() if args.target == "all" else [(args.target, TARGETS[args.target])]
    for name, config in targets:
        run_for_target(name, config)
    return 0


if __name__ == "__main__":
    sys.exit(main())
