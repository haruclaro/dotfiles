import sys
import os
import subprocess
import json
import configparser

def run(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True).strip()
    except: return ""

def get_desktop_files():
    apps = {}
    dirs = [
        "/usr/share/applications", 
        os.path.expanduser("~/.local/share/applications"),
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
        "/var/lib/snapd/desktop/applications"
    ]
    for d in dirs:
        if os.path.exists(d):
            for f in os.listdir(d):
                if f.endswith(".desktop"):
                    path = os.path.join(d, f)
                    try:
                        cfg = configparser.ConfigParser(interpolation=None)
                        cfg.read(path)
                        if "Desktop Entry" in cfg:
                            name = cfg["Desktop Entry"].get("Name", f)
                            exec_cmd = cfg["Desktop Entry"].get("Exec", "")
                            # Ignore hidden or no-exec
                            if cfg["Desktop Entry"].get("NoDisplay", "false").lower() == "true": continue
                            if not exec_cmd: continue
                            apps[f] = name
                    except:
                        pass
    return apps

def get_default_browser():
    return run("xdg-settings get default-web-browser")

def get_default_mime(mime):
    return run(f"xdg-mime query default {mime}")

def get_terminal(apps):
    exec_cmd = "ghostty"
    try:
        for line in open(os.path.expanduser("~/.config/hypr/hyprland.conf")):
            if line.strip().startswith("$terminal ="):
                exec_cmd = line.split("=")[1].strip()
    except: pass

    # reverse lookup in apps
    dirs = [
        "/usr/share/applications", 
        os.path.expanduser("~/.local/share/applications"),
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
        "/var/lib/snapd/desktop/applications"
    ]
    for d in dirs:
        if os.path.exists(d):
            for f in os.listdir(d):
                if f.endswith(".desktop"):
                    path = os.path.join(d, f)
                    try:
                        cfg = configparser.ConfigParser(interpolation=None)
                        cfg.read(path)
                        if "Desktop Entry" in cfg:
                            exe = cfg["Desktop Entry"].get("Exec", "").split(" ")[0]
                            if exe == exec_cmd or exe.endswith(f"/{exec_cmd}"):
                                return f
                    except: pass
    return exec_cmd

def get_settings():
    apps = get_desktop_files()
    # Sort them by name
    sorted_apps = [{"id": k, "name": v} for k, v in sorted(apps.items(), key=lambda item: item[1].lower())]
    
    return {
        "apps_list": sorted_apps,
        "browser": get_default_browser(),
        "file_manager": get_default_mime("inode/directory"),
        "text_editor": get_default_mime("text/plain"),
        "terminal": get_terminal(apps)
    }

def set_setting(key, value):
    if key == "browser":
        run(f"xdg-settings set default-web-browser {value}")
        run(f"xdg-mime default {value} x-scheme-handler/http")
        run(f"xdg-mime default {value} x-scheme-handler/https")
    elif key == "file_manager":
        run(f"xdg-mime default {value} inode/directory")
    elif key == "text_editor":
        run(f"xdg-mime default {value} text/plain")
    elif key == "terminal":
        # Resolve the desktop file to its executable
        exec_cmd = value
        dirs = [
            "/usr/share/applications", 
            os.path.expanduser("~/.local/share/applications"),
            "/var/lib/flatpak/exports/share/applications",
            os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
            "/var/lib/snapd/desktop/applications"
        ]
        for d in dirs:
            path = os.path.join(d, value)
            if os.path.exists(path):
                try:
                    cfg = configparser.ConfigParser(interpolation=None)
                    cfg.read(path)
                    if "Desktop Entry" in cfg:
                        exec_cmd = cfg["Desktop Entry"].get("Exec", value).split(" ")[0]
                except: pass
                break
                
        conf = os.path.expanduser("~/.config/hypr/hyprland.conf")
        run(f"sed -i 's|^$terminal = .*|$terminal = {exec_cmd}|' {conf}")
        run("hyprctl reload")

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "get":
        print(json.dumps(get_settings()))
    elif action == "set":
        set_setting(sys.argv[2], sys.argv[3])
