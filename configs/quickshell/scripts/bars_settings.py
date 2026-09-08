#!/usr/bin/env python3
"""Persistência das configurações das barras (TopBar/BottomBar) do Quickshell.

Padrão idêntico ao appearance_settings.py: CLI com `get` e `set <key> <value>`,
gravando atomicamente em ~/.config/quickshell/bar-config.json. Esse arquivo é
observado pelo singleton config/BarConfig.qml (FileView watchChanges), então as
barras reagem ao vivo quando algum valor muda.

Valores:
  barHeight/barRadius/barMargin/itemSpacing/contentPadding - inteiros (geometria)
  showBorder/borderWidth                                 - bool + int (borda)
  topOpacity/bottomOpacity                               - float 0..1 ou null
                                                           (null = acompanha o tema)
  topItems/bottomItems                                   - lista JSON de ids
"""
import sys
import json
import os

CONFIG_PATH = os.path.expanduser("~/.config/quickshell/bar-config.json")

KNOWN_TOP_ITEMS = ["resource", "clock", "media"]
KNOWN_BOTTOM_ITEMS = ["workspaces", "sysmenu", "tray"]


def items_default(known):
    return [{"id": i, "enabled": True} for i in known]


DEFAULTS = {
    "barHeight": 34,
    "barRadius": 18,
    "barMargin": 8,
    "itemSpacing": 14,
    "contentPadding": 10,
    "showBorder": True,
    "borderWidth": 1,
    "topOpacity": None,
    "bottomOpacity": None,
    "topItems": items_default(KNOWN_TOP_ITEMS),
    "bottomItems": items_default(KNOWN_BOTTOM_ITEMS),
}


def load():
    """Lê o JSON atual; em caso de erro/corrupção, parte dos defaults."""
    data = {}
    if os.path.isfile(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "r") as f:
                parsed = json.load(f)
            if isinstance(parsed, dict):
                data = parsed
        except Exception:
            pass
    merged = dict(DEFAULTS)
    merged.update({k: v for k, v in data.items() if k in DEFAULTS})
    return merged


def save(data):
    """Grava atomicamente (temp + rename) para não deixar JSON meio-escrito."""
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    tmp = CONFIG_PATH + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, CONFIG_PATH)


def parse_items(value, known):
    """Normaliza topItems/bottomItems para [{id, enabled}, ...] preservando ordem."""
    raw = None
    try:
        raw = json.loads(value) if isinstance(value, str) else value
    except (json.JSONDecodeError, TypeError):
        raw = None
    if not isinstance(raw, list) or not raw:
        return items_default(known)

    result = []
    seen = set()
    for entry in raw:
        if isinstance(entry, dict):
            iid = entry.get("id")
            enabled = entry.get("enabled", True)
        else:
            iid = entry
            enabled = True
        if iid in known and iid not in seen:
            seen.add(iid)
            result.append({"id": iid, "enabled": bool(enabled)})
    return result if result else items_default(known)


def parse_value(key, value):
    if key == "showBorder":
        return str(value).strip().lower() in ("true", "1", "yes", "on")

    if key in ("topOpacity", "bottomOpacity"):
        if value is None or str(value).strip().lower() in ("null", "none", "auto", ""):
            return None
        try:
            return max(0.0, min(1.0, round(float(value), 2)))
        except ValueError:
            return DEFAULTS[key]

    if key in ("topItems", "bottomItems"):
        known = KNOWN_TOP_ITEMS if key == "topItems" else KNOWN_BOTTOM_ITEMS
        return parse_items(value, known)

    # Geometria e largura da borda: inteiros.
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return DEFAULTS[key]


def cmd_get():
    print(json.dumps(load(), ensure_ascii=False))


def cmd_set(key, value):
    if key not in DEFAULTS:
        print(f"Chave desconhecida: {key}", file=sys.stderr)
        sys.exit(1)
    data = load()
    data[key] = parse_value(key, value)
    save(data)
    # Eco do novo estado (útil para logs/debug).
    print(json.dumps({key: data[key]}, ensure_ascii=False))


if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "get"
    if action == "get":
        cmd_get()
    elif action == "set":
        if len(sys.argv) < 4:
            print("Uso: bars_settings.py set <key> <value>", file=sys.stderr)
            sys.exit(1)
        cmd_set(sys.argv[2], sys.argv[3])
    else:
        print(f"Ação desconhecida: {action}", file=sys.stderr)
        sys.exit(1)