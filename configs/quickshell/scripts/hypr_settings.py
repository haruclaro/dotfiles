#!/usr/bin/env python3
import sys
import json
import re
import os
import subprocess

CONFIG_PATH = os.path.expanduser("~/.config/hypr/hyprland.conf")

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

    # Simple regex matches
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

    # For block scoped settings like blur { enabled = true } we use simpler global matches assuming standard format
    m = re.search(r"blur\s*\{[^}]*enabled\s*=\s*(true|false|1|0)[^}]*\}", content, re.S)
    if m: settings["blur_enabled"] = m.group(1).lower() in ["true", "1"]

    m = re.search(r"shadow\s*\{[^}]*enabled\s*=\s*(true|false|1|0)[^}]*\}", content, re.S)
    if m: settings["shadow_enabled"] = m.group(1).lower() in ["true", "1"]

    m = re.search(r"animations\s*\{[^}]*enabled\s*=\s*(yes|no|true|false|1|0)[^}]*\}", content, re.S)
    if m: settings["animations_enabled"] = m.group(1).lower() in ["yes", "true", "1"]

    # Read exec-once
    settings["execs"] = re.findall(r"^\s*exec-once\s*=\s*(.+)$", content, re.M)
    
    # Read binds
    settings["binds"] = []
    binds_matches = re.finditer(r"^\s*bind\w*\s*=\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*(.+)$", content, re.M)
    for match in binds_matches:
        settings["binds"].append({
            "mods": match.group(1).strip(),
            "key": match.group(2).strip(),
            "action": match.group(3).strip(),
            "command": match.group(4).strip(),
            "raw": match.group(0).strip()
        })

    return settings

def write_setting(key, value):
    with open(CONFIG_PATH, "r") as f:
        content = f.read()

    # Apply replacement
    if key in ["gaps_in", "gaps_out", "border_size", "rounding", "layout", "active_opacity", "inactive_opacity"]:
        pattern = rf"^( *{key} *= *).*$"
        replacement = rf"\g<1>{value}"
        if re.search(pattern, content, re.M):
            content = re.sub(pattern, replacement, content, flags=re.M)
            
    elif key in ["blur_enabled", "shadow_enabled", "animations_enabled"]:
        block = key.split('_')[0]
        v_str = "true" if str(value).lower() in ["true", "1"] else "false"
        if block == "animations": v_str = "yes" if v_str == "true" else "no"
        
        pattern = rf"({block}\s*{{[^}}]*?)^\s*enabled\s*=.*$"
        replacement = rf"\1    enabled = {v_str}"
        if re.search(pattern, content, re.M):
            content = re.sub(pattern, replacement, content, flags=re.M)
        
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
