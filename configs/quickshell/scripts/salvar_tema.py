#!/usr/bin/env python3
import sys
import json
import os
import subprocess
import re

name = sys.argv[1]
fundo = sys.argv[2]
superficie = sys.argv[3]
base = sys.argv[4]
destaque1 = sys.argv[5]
destaque2 = sys.argv[6]
texto = sys.argv[7]
wallpaper = sys.argv[8]
original_file_path = sys.argv[9] if len(sys.argv) > 9 else ""

slug = re.sub(r'[^a-z0-9]', '-', name.lower())
slug = re.sub(r'-+', '-', slug).strip('-')

theme_path = os.path.expanduser(f"~/.config/tema_manager/themes/{slug}.json")
dados = {
  "nome": name,
  "fundo": fundo,
  "superficie": superficie,
  "base": base,
  "destaque1": destaque1,
  "destaque2": destaque2,
  "texto": texto,
  "wallpaper": wallpaper
}
os.makedirs(os.path.dirname(theme_path), exist_ok=True)
with open(theme_path, "w") as f:
    json.dump(dados, f, indent=4)

if original_file_path and original_file_path != theme_path and os.path.exists(original_file_path):
    try:
        os.remove(original_file_path)
    except:
        pass

subprocess.run(["python3", os.path.expanduser("~/.config/quickshell/scripts/aplicar_tema.py"), theme_path])
