#!/usr/bin/env python3
import sys
import os
import urllib.request
import urllib.parse

if len(sys.argv) < 2:
    sys.exit(1)

path = sys.argv[1]
raw_url = f"https://raw.githubusercontent.com/dharmx/walls/main/{urllib.parse.quote(path, safe='/')}"

WALLPAPERS_DIR = os.path.expanduser("~/.config/tema_manager/wallpapers")
os.makedirs(WALLPAPERS_DIR, exist_ok=True)
local_path = os.path.join(WALLPAPERS_DIR, os.path.basename(path))

if not os.path.exists(local_path):
    try:
        req = urllib.request.Request(raw_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(local_path, 'wb') as out_file:
            out_file.write(response.read())
    except Exception as e:
        with open("/tmp/dl_error.log", "w") as f:
            f.write(f"Error: {e}\nRaw URL: {raw_url}\n")
        print(f"Error: {e}")
        sys.exit(1)

print(local_path)
