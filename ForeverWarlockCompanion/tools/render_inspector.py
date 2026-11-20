"""Render two before/after previews of exported Lua frames, not WoW screenshots.
Usage: python3 tools/render_inspector.py BEFORE_PREFIX AFTER_PREFIX DESTINATION
"""
from pathlib import Path
import sys
from PIL import Image, ImageDraw
from render_layout import render, font


def main(before, after, destination):
    out = Path(destination)
    out.mkdir(parents=True, exist_ok=True)
    for section in ("item", "acquisition"):
        images = [render(prefix + "-" + section + ".tsv") for prefix in (before, after)]
        board = Image.new("RGB", (800, 1130), (13, 14, 21))
        draw = ImageDraw.Draw(board)
        draw.text((16, 12), "FEL CAPE · PREVIEW DE LOS FRAMES LUA", font=font(18, True), fill="#e8c878")
        draw.text((16, 40), "Datos del objeto publicados · equipo y bolsas simulados", font=font(14), fill="#c8c9d0")
        draw.text((16, 63), "No es una captura de WoW. Iconos y fuentes aproximados.", font=font(14), fill="#c8c9d0")
        for index, (image, label) in enumerate(zip(images, ("ANTES · 3.6", "DESPUÉS · 3.7 · PILOTO"))):
            draw.text((18 + index * 400, 92), label, font=font(15, True), fill="#eee7d6")
            board.paste(image, (18 + index * 400, 120))
        board.save(out / (section + "-comparison.png"))


if __name__ == "__main__":
    main(*sys.argv[1:])
