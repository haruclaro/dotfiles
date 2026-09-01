#!/usr/bin/env python3
import sys
import json
import subprocess
import os

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except:
        return ""

def get_cursors_and_icons():
    cursors = set()
    icons = set()
    dirs = ["/usr/share/icons", os.path.expanduser("~/.icons"), os.path.expanduser("~/.local/share/icons")]
    for d in dirs:
        if os.path.isdir(d):
            for item in os.listdir(d):
                p = os.path.join(d, item)
                if os.path.isdir(os.path.join(p, "cursors")):
                    cursors.add(item)
                elif os.path.isfile(os.path.join(p, "index.theme")):
                    icons.add(item)
    return sorted(list(cursors)), sorted(list(icons))

def get_fonts():
    try:
        out = subprocess.check_output(["fc-list", ":", "family"], text=True)
        fonts = set()
        for line in out.splitlines():
            # fc-list returns e.g. "DejaVu Sans,DejaVu Sans Condensed"
            f = line.split(",")[0].strip()
            if f:
                fonts.add(f)
        return sorted(list(fonts))
    except:
        return []

def get_sddm_themes():
    d = "/usr/share/sddm/themes"
    themes = {}
    if os.path.isdir(d):
        for item in os.listdir(d):
            p = os.path.join(d, item)
            if os.path.isdir(p):
                preview = ""
                meta = os.path.join(p, "metadata.desktop")
                if os.path.isfile(meta):
                    try:
                        for line in open(meta):
                            if line.startswith("Screenshot="):
                                img = line.split("=")[1].strip()
                                if os.path.isfile(os.path.join(p, img)):
                                    preview = os.path.join(p, img)
                                break
                    except: pass
                if not preview:
                    for root_path in [p, os.path.join(p, "Previews"), os.path.join(p, "Backgrounds")]:
                        if os.path.isdir(root_path):
                            for f in os.listdir(root_path):
                                if f.endswith((".png", ".jpg")):
                                    preview = os.path.join(root_path, f)
                                    if "preview" in f.lower() or "background" in f.lower() or "astronaut" in f.lower(): break
                        if preview: break
                themes[item] = preview
    return themes

def get_plymouth_themes():
    d = "/usr/share/plymouth/themes"
    themes = {}
    if os.path.isdir(d):
        for item in os.listdir(d):
            p = os.path.join(d, item)
            if os.path.isdir(p) and os.path.exists(os.path.join(p, f"{item}.plymouth")):
                preview = ""
                for f in os.listdir(p):
                    if f.endswith(".png"):
                        if "background" in f.lower() or "splash" in f.lower():
                            preview = os.path.join(p, f)
                            break
                        if "progress" in f.lower() or "box" in f.lower():
                            preview = os.path.join(p, f)
                themes[item] = preview
    return themes

def get_settings():
    color_scheme = run_cmd("gsettings get org.gnome.desktop.interface color-scheme").strip("'")
    if not color_scheme: color_scheme = "prefer-dark"

    cursor_theme = run_cmd("gsettings get org.gnome.desktop.interface cursor-theme").strip("'")
    cursor_size = run_cmd("gsettings get org.gnome.desktop.interface cursor-size")
    cursor_size = int(cursor_size) if cursor_size.isdigit() else 24

    icon_theme = run_cmd("gsettings get org.gnome.desktop.interface icon-theme").strip("'")
    
    font_name = run_cmd("gsettings get org.gnome.desktop.interface font-name").strip("'")
    if font_name:
        parts = font_name.split(" ")
        font_family = " ".join(parts[:-1]) if len(parts) > 1 else parts[0]
        font_size = int(parts[-1]) if parts[-1].isdigit() else 11
    else:
        font_family = "Sans"
        font_size = 11

    sddm_theme = ""
    try:
        if os.path.isfile("/etc/sddm.conf.d/theme.conf"):
            for line in open("/etc/sddm.conf.d/theme.conf"):
                if line.startswith("Current="):
                    sddm_theme = line.split("=")[1].strip()
    except: pass

    plymouth_theme = run_cmd("plymouth-set-default-theme")

    cursors, icons = get_cursors_and_icons()
    sddm_themes = get_sddm_themes()
    plymouth_themes = get_plymouth_themes()

    previews = {"cursors": {}, "icons": {}, "sddm": sddm_themes, "plymouth": plymouth_themes}
    cache_file = os.path.expanduser("~/.cache/quickshell_cursors/previews.json")
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                c = json.load(f)
                previews["cursors"] = c.get("cursors", {})
                previews["icons"] = c.get("icons", {})
        except: pass

    return {
        "color_scheme": color_scheme,
        "cursor_theme": cursor_theme,
        "cursor_size": cursor_size,
        "icon_theme": icon_theme,
        "font_family": font_family,
        "font_size": font_size,
        "sddm_theme": sddm_theme,
        "plymouth_theme": plymouth_theme,
        "cursors": cursors,
        "icons": icons,
        "sddm_list": sorted(list(sddm_themes.keys())),
        "plymouth_list": sorted(list(plymouth_themes.keys())),
        "fonts": get_fonts(),
        "previews": previews
    }

def set_setting(key, value):
    if key == "color_scheme":
        run_cmd(f"gsettings set org.gnome.desktop.interface color-scheme '{value}'")
    elif key == "cursor_theme":
        run_cmd(f"gsettings set org.gnome.desktop.interface cursor-theme '{value}'")
        # Also need to grab current size to pass to hyprctl
        c_size = run_cmd("gsettings get org.gnome.desktop.interface cursor-size")
        c_size = c_size if c_size.isdigit() else "24"
        run_cmd(f"hyprctl setcursor '{value}' {c_size}")
    elif key == "cursor_size":
        run_cmd(f"gsettings set org.gnome.desktop.interface cursor-size {value}")
        c_theme = run_cmd("gsettings get org.gnome.desktop.interface cursor-theme").strip("'")
        if c_theme: run_cmd(f"hyprctl setcursor '{c_theme}' {value}")
    elif key == "icon_theme":
        run_cmd(f"gsettings set org.gnome.desktop.interface icon-theme '{value}'")
    elif key == "font_family":
        f_name = run_cmd("gsettings get org.gnome.desktop.interface font-name").strip("'")
        f_size = f_name.split(" ")[-1] if f_name and f_name.split(" ")[-1].isdigit() else "11"
        run_cmd(f"gsettings set org.gnome.desktop.interface font-name '{value} {f_size}'")
    elif key == "font_size":
        f_name = run_cmd("gsettings get org.gnome.desktop.interface font-name").strip("'")
        if f_name:
            f_fam = " ".join(f_name.split(" ")[:-1]) if len(f_name.split(" ")) > 1 else f_name
            run_cmd(f"gsettings set org.gnome.desktop.interface font-name '{f_fam} {value}'")
        else:
            run_cmd(f"gsettings set org.gnome.desktop.interface font-name 'Sans {value}'")
    elif key == "sddm_theme":
        script = f"mkdir -p /etc/sddm.conf.d && echo -e '[Theme]\\nCurrent={value}' > /etc/sddm.conf.d/theme.conf"
        # Run detached polkit request
        subprocess.Popen(["pkexec", "bash", "-c", script])
    elif key == "plymouth_theme":
        # Launch rebuild initrd in background so it doesn't hang QML
        subprocess.Popen(["pkexec", "plymouth-set-default-theme", value, "-R"])

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "get":
        print(json.dumps(get_settings()))
    elif action == "set":
        set_setting(sys.argv[2], sys.argv[3])
