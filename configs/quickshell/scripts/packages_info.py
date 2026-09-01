import sys
import os
import subprocess
import json

def run(cmd):
    try: return subprocess.check_output(cmd, shell=True, text=True).strip()
    except: return ""

def get_stats():
    pacman_pkg = run("pacman -Qqn | wc -l")
    aur_pkg = run("pacman -Qqm | wc -l")
    updates = run("checkupdates 2>/dev/null | wc -l")
    if not updates or not updates.isdigit(): updates = "0"
    
    try:
        aur_updates = run("yay -Qua 2>/dev/null | wc -l")
        if aur_updates.isdigit():
            updates = str(int(updates) + int(aur_updates))
    except: pass

    flatpak_pkg = run("flatpak list --app 2>/dev/null | wc -l")
    if not flatpak_pkg or not flatpak_pkg.isdigit(): flatpak_pkg = "0"

    appimage_pkg = run("find ~/Applications -maxdepth 1 -type f -name '*.AppImage' 2>/dev/null | wc -l")
    if not appimage_pkg or not appimage_pkg.isdigit(): appimage_pkg = "0"
    
    return {
        "pacman": pacman_pkg,
        "aur": aur_pkg,
        "flatpak": flatpak_pkg,
        "appimage": appimage_pkg,
        "updates": updates
    }

def get_list(ptype):
    packages = []
    
    if ptype == "native":
        installed = run("pacman -Qqn").split("\n")
        updates_raw = run("checkupdates 2>/dev/null")
        updates_set = set()
        for line in updates_raw.split("\n"):
            if line: updates_set.add(line.split(" ")[0])
            
        for pkg in installed:
            if not pkg: continue
            packages.append({
                "name": pkg,
                "repo": "Arch",
                "desc": "Pacote do Sistema",
                "installed": True,
                "has_update": pkg in updates_set
            })
            
    elif ptype == "aur":
        installed = run("pacman -Qqm").split("\n")
        updates_raw = run("yay -Qua 2>/dev/null")
        updates_set = set()
        for line in updates_raw.split("\n"):
            if line: updates_set.add(line.split(" ")[0])
            
        for pkg in installed:
            if not pkg: continue
            packages.append({
                "name": pkg,
                "repo": "AUR",
                "desc": "Pacote mantido pela comunidade",
                "installed": True,
                "has_update": pkg in updates_set
            })
            
    elif ptype == "flatpak":
        installed = run("flatpak list --app --columns=application,name 2>/dev/null").split("\n")
        updates_raw = run("flatpak remote-ls --updates --columns=application 2>/dev/null")
        updates_set = set(updates_raw.split("\n"))
        
        for line in installed:
            if not line: continue
            parts = line.split("\t")
            if len(parts) >= 2:
                app_id, name = parts[0], parts[1]
                packages.append({
                    "name": name,
                    "repo": "Flatpak",
                    "desc": app_id,
                    "installed": True,
                    "has_update": app_id in updates_set,
                    "app_id": app_id
                })
                
    elif ptype == "appimage":
        app_dir = os.path.expanduser("~/Applications")
        if os.path.isdir(app_dir):
            for f in os.listdir(app_dir):
                if f.endswith(".AppImage"):
                    packages.append({
                        "name": f,
                        "repo": "AppImage",
                        "desc": "Portátil",
                        "installed": True,
                        "has_update": False
                    })
                    
    # Sort: has_update=True first, then alphabetically by name
    packages.sort(key=lambda x: (not x["has_update"], x["name"].lower()))
    return {"results": packages}

def search_packages(query):
    try:
        res = run(f"yay -Ss '{query}' | head -n 40")
        packages = []
        lines = res.split("\n")
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if not line:
                i += 1
                continue
            if "/" in line:
                parts = line.split(" ")
                name_ver = parts[0]
                repo = name_ver.split("/")[0]
                name = name_ver.split("/")[1]
                installed = "(Installed)" in line or "(Instalado)" in line or "[instalado" in line.lower()
                desc = lines[i+1].strip() if i+1 < len(lines) else ""
                packages.append({
                    "name": name,
                    "repo": repo,
                    "desc": desc,
                    "installed": installed,
                    "has_update": False
                })
                i += 2
            else:
                i += 1
        return {"results": packages}
    except:
        return {"results": []}

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "get":
        print(json.dumps(get_stats()))
    elif action == "list":
        print(json.dumps(get_list(sys.argv[2])))
    elif action == "search":
        print(json.dumps(search_packages(sys.argv[2])))
    elif action == "install":
        pkg = sys.argv[2]
        term = run("xdg-terminal-exec") or "ghostty"
        os.system(f"{term} -e bash -c 'yay -S {pkg}; quickshell ipc call packages reload; echo \"\"; read -p \"Pressione ENTER para sair...\"' &")
    elif action == "remove":
        pkg = sys.argv[2]
        repo = sys.argv[3] if len(sys.argv) > 3 else ""
        term = run("xdg-terminal-exec") or "ghostty"
        if repo == "Flatpak":
            # the app_id is passed as pkg for flatpak
            os.system(f"{term} -e bash -c 'flatpak uninstall {pkg}; quickshell ipc call packages reload; echo \"\"; read -p \"Pressione ENTER para sair...\"' &")
        elif repo == "AppImage":
            os.system(f"rm -f ~/Applications/{pkg}")
            os.system("quickshell ipc call packages reload &")
        else:
            os.system(f"{term} -e bash -c 'yay -Rns {pkg}; quickshell ipc call packages reload; echo \"\"; read -p \"Pressione ENTER para sair...\"' &")
    elif action == "update":
        term = run("xdg-terminal-exec") or "ghostty"
        os.system(f"{term} -e bash -c 'yay -Syu; quickshell ipc call packages reload; echo \"\"; read -p \"Pressione ENTER para sair...\"' &")
