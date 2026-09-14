#!/usr/bin/env python3
import sys
import json
import re
import os
import subprocess

def get_hyprland_info():
    is_lua = False
    try:
        output = subprocess.run(["hyprctl", "version"], capture_output=True, text=True, check=True).stdout
        m = re.search(r"Tag:\s*v(\d+)\.(\d+)", output)
        if m:
            major, minor = int(m.group(1)), int(m.group(2))
            if major > 0 or minor >= 57:
                is_lua = True
    except Exception:
        pass
        
    path = "~/.config/hypr/hyprland.lua" if is_lua else "~/.config/hypr/hyprland.conf"
    return os.path.expanduser(path), is_lua

CONFIG_PATH, IS_LUA = get_hyprland_info()

def read_config():
    if not os.path.exists(CONFIG_PATH):
        return {}

    with open(CONFIG_PATH, "r") as f:
        content = f.read()

    settings = {
        "gaps_in": 4, "gaps_out": 8, "border_size": 2, "rounding": 14,
        "layout": "dwindle",
        "blur_enabled": True, "shadow_enabled": False,
        "active_opacity": 1.0, "inactive_opacity": 1.0,
        "animations_enabled": True
    }

    if IS_LUA:
        m = re.search(r"\bgaps_in\s*=\s*(\d+)", content)
        if m: settings["gaps_in"] = int(m.group(1))

        m = re.search(r"\bgaps_out\s*=\s*(\d+)", content)
        if m: settings["gaps_out"] = int(m.group(1))

        m = re.search(r"\bborder_size\s*=\s*(\d+)", content)
        if m: settings["border_size"] = int(m.group(1))

        m = re.search(r"\brounding\s*=\s*(\d+)", content)
        if m: settings["rounding"] = int(m.group(1))

        m = re.search(r'\blayout\s*=\s*"([^"]+)"', content)
        if m: settings["layout"] = m.group(1)

        m = re.search(r"\bactive_opacity\s*=\s*([\d\.]+)", content)
        if m: settings["active_opacity"] = float(m.group(1))

        m = re.search(r"\binactive_opacity\s*=\s*([\d\.]+)", content)
        if m: settings["inactive_opacity"] = float(m.group(1))

        m = re.search(r"\bblur\s*=\s*\{[^}]*enabled\s*=\s*(true|false)[^}]*\}", content)
        if m: settings["blur_enabled"] = m.group(1) == "true"

        m = re.search(r"\bshadow\s*=\s*\{[^}]*enabled\s*=\s*(true|false)[^}]*\}", content)
        if m: settings["shadow_enabled"] = m.group(1) == "true"

        m = re.search(r"\banimations\s*=\s*\{[^}]*enabled\s*=\s*(true|false)[^}]*\}", content)
        if m: settings["animations_enabled"] = m.group(1) == "true"
    else:
        m = re.search(r"^\s*gaps_in\s*=\s*(\d+)", content, re.M)
        if m: settings["gaps_in"] = int(m.group(1))

        m = re.search(r"^\s*gaps_out\s*=\s*(\d+)", content, re.M)
        if m: settings["gaps_out"] = int(m.group(1))

        m = re.search(r"^\s*border_size\s*=\s*(\d+)", content, re.M)
        if m: settings["border_size"] = int(m.group(1))

        m = re.search(r"^\s*rounding\s*=\s*(\d+)", content, re.M)
        if m: settings["rounding"] = int(m.group(1))

        m = re.search(r"^\s*layout\s*=\s*(\w+)", content, re.M)
        if m: settings["layout"] = m.group(1)

        m = re.search(r"^\s*active_opacity\s*=\s*([\d\.]+)", content, re.M)
        if m: settings["active_opacity"] = float(m.group(1))

        m = re.search(r"^\s*inactive_opacity\s*=\s*([\d\.]+)", content, re.M)
        if m: settings["inactive_opacity"] = float(m.group(1))

        m = re.search(r"blur\s*\{[^}]*enabled\s*=\s*(true|false|1|0)[^}]*\}", content, re.S)
        if m: settings["blur_enabled"] = m.group(1).lower() in ["true", "1"]

        m = re.search(r"shadow\s*\{[^}]*enabled\s*=\s*(true|false|1|0)[^}]*\}", content, re.S)
        if m: settings["shadow_enabled"] = m.group(1).lower() in ["true", "1"]

        m = re.search(r"animations\s*\{[^}]*enabled\s*=\s*(yes|no|true|false|1|0)[^}]*\}", content, re.S)
        if m: settings["animations_enabled"] = m.group(1).lower() in ["yes", "true", "1"]

    return settings

def write_setting(key, value):
    if not os.path.exists(CONFIG_PATH):
        return

    with open(CONFIG_PATH, "r") as f:
        content = f.read()

    if IS_LUA:
        if key in ["gaps_in", "gaps_out", "border_size", "rounding", "active_opacity", "inactive_opacity"]:
            pattern = rf"(\b{key}\s*=\s*)[\d\.]+"
            replacement = rf"\g<1>{value}"
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                
        elif key == "layout":
            pattern = rf'(\blayout\s*=\s*)"[^"]+"'
            replacement = rf'\g<1>"{value}"'
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
                
        elif key in ["blur_enabled", "shadow_enabled", "animations_enabled"]:
            block = key.split('_')[0]
            v_str = "true" if str(value).lower() in ["true", "1"] else "false"
            
            pattern = rf"(\b{block}\s*=\s*\{{[^}}]*?\benabled\s*=\s*)(true|false)"
            replacement = rf"\g<1>{v_str}"
            if re.search(pattern, content):
                content = re.sub(pattern, replacement, content)
    else:
        if key in ["gaps_in", "gaps_out", "border_size", "rounding", "layout", "active_opacity", "inactive_opacity"]:
            pattern = rf"^( *{key} *= *).*$"
            replacement = rf"\g<1>{value}"
            if re.search(pattern, content, re.M):
                content = re.sub(pattern, replacement, content, flags=re.M)
                
        elif key in ["blur_enabled", "shadow_enabled", "animations_enabled"]:
            block = key.split('_')[0]
            v_str = "true" if str(value).lower() in ["true", "1"] else "false"
            if block == "animations": v_str = "yes" if v_str == "true" else "no"
            
            pattern = rf"({block}\s*\{{[^}}]*?)^\s*enabled\s*=.*$"
            replacement = rf"\1    enabled = {v_str}"
            if re.search(pattern, content, re.M):
                content = re.sub(pattern, replacement, content, flags=re.M)

    import tempfile
    fd, temp_path = tempfile.mkstemp(dir=os.path.dirname(CONFIG_PATH))
    with os.fdopen(fd, 'w') as f:
        f.write(content)
    os.rename(temp_path, CONFIG_PATH)

    subprocess.run(["hyprctl", "reload"])

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "get":
        print(json.dumps(read_config()))
    elif action == "set":
        write_setting(sys.argv[2], sys.argv[3])
