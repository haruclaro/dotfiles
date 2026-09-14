#!/usr/bin/env python3
import sys
import json
import re
import os
import subprocess

CONFIG_PATH = os.path.expanduser("~/.config/hypr/hyprland.lua")

def read_config():
    with open(CONFIG_PATH, "r") as f:
        content = f.read()

    settings = {
        "gaps_in": 4, "gaps_out": 8, "border_size": 2, "rounding": 14,
        "layout": "dwindle",
        "blur_enabled": True, "shadow_enabled": False,
        "active_opacity": 1.0, "inactive_opacity": 1.0,
        "animations_enabled": True
    }

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

    m = re.search(r"blur\s*=\s*\{[^}]*enabled\s*=\s*(true|false)[^}]*\}", content)
    if m: settings["blur_enabled"] = m.group(1) == "true"

    m = re.search(r"shadow\s*=\s*\{[^}]*enabled\s*=\s*(true|false)[^}]*\}", content)
    if m: settings["shadow_enabled"] = m.group(1) == "true"

    m = re.search(r"animations\s*=\s*\{[^}]*enabled\s*=\s*(true|false)[^}]*\}", content)
    if m: settings["animations_enabled"] = m.group(1) == "true"

    return settings

def write_setting(key, value):
    with open(CONFIG_PATH, "r") as f:
        content = f.read()

    # Apply replacement
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
        
    import tempfile
    fd, temp_path = tempfile.mkstemp(dir=os.path.dirname(CONFIG_PATH))
    with os.fdopen(fd, 'w') as f:
        f.write(content)
    os.rename(temp_path, CONFIG_PATH)

    subprocess.run(["hyprctl", "reload"])

def array_modify(action, target, arg):
    with open(CONFIG_PATH, "r") as f:
        lines = f.readlines()

    new_lines = []
    
    if action == "del":
        # arg is the exact string to match to delete it
        # for exec, arg is the command. for bind, arg is the full bind line
        count = 0
        for line in lines:
            if target == "exec":
                m = re.match(r"^\s*exec-once\s*=\s*(.+)$", line)
                if m and m.group(1).strip() == arg:
                    continue # skip this line
            elif target == "bind":
                # we match the exact string
                if line.strip() == arg:
                    continue # skip this line
            new_lines.append(line)

    elif action == "add":
        # we append it after the last occurrence
        last_idx = -1
        for i, line in enumerate(lines):
            if target == "exec" and re.match(r"^\s*exec-once\s*=", line):
                last_idx = i
            elif target == "bind" and re.match(r"^\s*bind\w*\s*=", line):
                last_idx = i
        
        if last_idx != -1:
            lines.insert(last_idx + 1, f"{arg}\n")
        else:
            lines.append(f"{arg}\n")
        new_lines = lines

    import tempfile
    fd, temp_path = tempfile.mkstemp(dir=os.path.dirname(CONFIG_PATH))
    with os.fdopen(fd, 'w') as f:
        f.writelines(new_lines)
    os.rename(temp_path, CONFIG_PATH)
    
    subprocess.run(["hyprctl", "reload"])

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "get":
        print(json.dumps(read_config()))
    elif action == "set":
        write_setting(sys.argv[2], sys.argv[3])
    elif action == "del_exec":
        array_modify("del", "exec", sys.argv[2])
    elif action == "add_exec":
        array_modify("add", "exec", f"exec-once = {sys.argv[2]}")
    elif action == "del_bind":
        array_modify("del", "bind", sys.argv[2])
    elif action == "add_bind":
        array_modify("add", "bind", sys.argv[2])
