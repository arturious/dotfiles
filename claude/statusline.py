#!/usr/bin/env python3
"""Claude Code statusLine: model | directory | context % | 5h / 7d usage."""

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def color(hex_rgb, text):
    r, g, b = (int(hex_rgb[i:i + 2], 16) for i in (0, 2, 4))
    return f"\033[38;2;{r};{g};{b}m{text}\033[0m"


def resets_in(epoch_seconds):
    try:
        left = int(epoch_seconds - datetime.now().timestamp())
    except (TypeError, ValueError):
        return None
    if left <= 0:
        return None
    days, rem = divmod(left, 86400)
    hours, rem = divmod(rem, 3600)
    minutes = rem // 60
    if days:
        return f"{days}d{hours}h"
    if hours:
        return f"{hours}h{minutes:02d}m"
    return f"{minutes}m"


try:
    payload = json.load(sys.stdin)
    if not isinstance(payload, dict):
        payload = {}
except Exception:
    payload = {}

model = (payload.get("model") or {}).get("display_name") or "Claude Code"

cwd = payload.get("cwd") or ""

# Claude's working directory, for tmux: the process itself stays in the dir
# claude was started from, so pane_current_path doesn't follow it. Stored as
# a pane option (@claude_cwd), read by prefix+g in tmux/settings.conf.
pane = os.environ.get("TMUX_PANE")
if pane and cwd:
    try:
        subprocess.run(["tmux", "set-option", "-p", "-t", pane, "@claude_cwd", cwd],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1)
    except Exception:
        pass
home = str(Path.home())
if cwd == home:
    cwd_display = "~"
elif cwd.startswith(home + os.sep):
    cwd_display = "~" + cwd[len(home):]
else:
    cwd_display = cwd

ctx = (payload.get("context_window") or {}).get("used_percentage")
rate_limits = payload.get("rate_limits") or {}

# Line 1: model | directory. Line 2: context % | 5h | 7d.
top = [color("D77757", model)]
if cwd_display:
    top.append(color("2AA298", cwd_display))

parts = []
if ctx is not None:
    parts.append(color("859900", f"{ctx:g}%"))

for label, key in (("5h", "five_hour"), ("7d", "seven_day")):
    limit = rate_limits.get(key) or {}
    used = limit.get("used_percentage")
    if used is None:
        continue
    text = f"{label}: {used:g}%"
    when = resets_in(limit.get("resets_at"))
    if when:
        text += f" (resets in {when})"
    parts.append(color("B28500", text))

print(" | ".join(top))
if parts:
    print(" | ".join(parts))
