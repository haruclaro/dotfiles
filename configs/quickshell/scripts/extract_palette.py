#!/usr/bin/env python3
import sys
import json
try:
    from PIL import Image
    def get_palette(image_path, num_colors=6):
        img = Image.open(image_path).convert('RGB')
        img = img.resize((150, 150))
        q = img.quantize(colors=num_colors, method=2)
        palette = q.getpalette()[:num_colors*3]
        hex_colors = []
        for i in range(0, len(palette), 3):
            r, g, b = palette[i:i+3]
            hex_colors.append(f"{r:02x}{g:02x}{b:02x}")
        # Sort colors by brightness roughly to assign them logically
        def brightness(h):
            return int(h[0:2],16)*0.299 + int(h[2:4],16)*0.587 + int(h[4:6],16)*0.114
        hex_colors.sort(key=brightness)
        
        # Mapping logic:
        # fundo (darkest)
        # superficie (2nd darkest)
        # base (3rd darkest)
        # destaque1 (bright/colorful) -> maybe 2nd brightest
        # destaque2 (brightest/colorful) -> maybe brightest
        # texto (brightest or very light) -> brightest
        
        if len(hex_colors) >= 6:
            return {
                "fundo": hex_colors[0],
                "superficie": hex_colors[1],
                "base": hex_colors[2],
                "destaque1": hex_colors[3],
                "destaque2": hex_colors[4],
                "texto": hex_colors[5]
            }
        return {}
    
    print(json.dumps(get_palette(sys.argv[1])))
except Exception as e:
    print("{}")
