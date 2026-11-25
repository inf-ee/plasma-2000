#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
"""Switches VS Code to KDE's (Windows 2000) title bar, and back. VS Code's own menu bar
stays under it, grey from the theme. These are application settings: VS Code doesn't let
an extension change their defaults, so they go into the user's settings.json.

    python3 -I settings.py apply  SETTINGS.json STATE.json
    python3 -I settings.py revert SETTINGS.json STATE.json

apply notes the values it replaces in STATE.json (only the first time); revert puts
them back and deletes STATE.json. A settings file with comments is left untouched
(rewriting it would drop them): the snippet is printed for adding by hand.
"""
import json
import os
import sys

TOP = {
    "window.titleBarStyle": "native",
    "window.menuStyle": "custom",
}


def snippet():
    return json.dumps(TOP, indent=4)


def load(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if not text.strip():
        return {}
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        sys.exit(f"{path} has comments or isn't plain JSON; left as is. Add this by hand:\n{snippet()}")
    if not isinstance(data, dict):
        sys.exit(f"{path}: unexpected content; left as is.")
    return data


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".p2k"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


def apply(path, state_path):
    data = load(path)
    if not os.path.exists(state_path):
        def was(d, k):
            return {"set": True, "value": d[k]} if k in d else {"set": False}
        state = {k: was(data, k) for k in TOP}
        os.makedirs(os.path.dirname(state_path), exist_ok=True)
        with open(state_path, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=4)
    data.update(TOP)
    save(path, data)


def revert(path, state_path):
    if not os.path.exists(state_path):
        return
    with open(state_path, encoding="utf-8") as f:
        state = json.load(f)
    data = load(path)
    for k in TOP:
        if state[k]["set"]:
            data[k] = state[k]["value"]
        else:
            data.pop(k, None)
    save(path, data)
    os.remove(state_path)


if __name__ == "__main__":
    {"apply": apply, "revert": revert}[sys.argv[1]](sys.argv[2], sys.argv[3])
