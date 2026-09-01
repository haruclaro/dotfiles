import os
import subprocess
import json

CACHE_DIR = os.path.expanduser("~/.cache/quickshell_cursors")
os.makedirs(CACHE_DIR, exist_ok=True)

def generate_cursor_preview(theme_name, theme_path):
    out_png = os.path.join(CACHE_DIR, f"{theme_name}.png")
    if os.path.exists(out_png): return out_png
    
    left_ptr = os.path.join(theme_path, "cursors", "left_ptr")
    if not os.path.exists(left_ptr): return ""
    
    try:
        tmp_dir = "/tmp/qc_cursor_" + theme_name
        os.makedirs(tmp_dir, exist_ok=True)
        subprocess.check_call(["xcur2png", left_ptr, "-d", tmp_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        files = sorted([f for f in os.listdir(tmp_dir) if f.endswith(".png")])
        if files:
            subprocess.check_call(["cp", os.path.join(tmp_dir, files[0]), out_png])
            return out_png
    except:
        pass
    return ""

def get_icon_preview(theme_path):
    try:
        cmd = f"find {theme_path} -name 'folder.svg' -o -name 'folder.png' -o -name 'system-file-manager.svg' -o -name 'system-file-manager.png' | grep -v '24x24' | head -n 1"
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except:
        return ""

dirs = ["/usr/share/icons", os.path.expanduser("~/.icons"), os.path.expanduser("~/.local/share/icons")]

previews = {"cursors": {}, "icons": {}}

for d in dirs:
    if os.path.isdir(d):
        for item in os.listdir(d):
            p = os.path.join(d, item)
            if os.path.isdir(os.path.join(p, "cursors")):
                previews["cursors"][item] = generate_cursor_preview(item, p)
            elif os.path.isfile(os.path.join(p, "index.theme")):
                # Check cache first for icons? Icons are just paths.
                previews["icons"][item] = get_icon_preview(p)

with open(os.path.join(CACHE_DIR, "previews.json"), "w") as f:
    json.dump(previews, f)

print("Cache generated successfully.")
