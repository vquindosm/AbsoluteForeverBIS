"""Before/after tooltip previews; frames and player APIs are simulated."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw
from render_layout import render, font


def main(before, after, destination, before_version="3.8", after_version="3.9"):
    old, new = render(before), render(after)
    width = 860
    height = max(old.height, new.height) + 170
    board = Image.new("RGB", (width, height), (13, 14, 21))
    draw = ImageDraw.Draw(board)
    draw.text((20, 14), "TOOLTIP · ANTES / DESPUÉS", font=font(22, True), fill="#e8c878")
    draw.text((20, 48), "Preview simulada · iconos/fuentes aproximados · no es una captura de WoW", font=font(15), fill="#c8c9d0")
    draw.text((20, 73), "Fel Cape publicada; equipo, pesos y porcentajes de prueba simulados.", font=font(14), fill="#c8c9d0")
    for x, image, title in ((20, old, "ANTES · " + before_version), (450, new, "DESPUÉS · " + after_version)):
        draw.text((x, 108), title, font=font(17, True), fill="#eee7d6")
        board.paste(image, (x, 142))
    out = Path(destination)
    out.parent.mkdir(parents=True, exist_ok=True)
    board.save(out)


if __name__ == "__main__":
    main(*sys.argv[1:])
