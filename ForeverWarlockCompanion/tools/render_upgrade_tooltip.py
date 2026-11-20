"""Before/after tooltip previews; frames and player APIs are simulated."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw
from render_layout import render, font


def main(before, after, destination):
    old, new = render(before), render(after)
    width = 860
    height = max(old.height, new.height) + 225
    board = Image.new("RGB", (width, height), (13, 14, 21))
    draw = ImageDraw.Draw(board)
    draw.text((20, 14), "TOOLTIP · ANTES / DESPUÉS", font=font(22, True), fill="#e8c878")
    draw.text((20, 48), "Preview de frames Lua · no es una captura de WoW", font=font(15), fill="#c8c9d0")
    draw.text((20, 73), "Fel Cape publicada; equipo, pesos y porcentajes de prueba simulados.", font=font(14), fill="#c8c9d0")
    for x, image, title in ((20, old, "ANTES · 3.7"), (450, new, "DESPUÉS · 3.8")):
        draw.text((x, 108), title, font=font(17, True), fill="#eee7d6")
        board.paste(image, (x, 142))
    y = height - 64
    draw.text((20, y), "Escala de colores (muestras de estilo):", font=font(14), fill="#c8c9d0")
    for x, text, color in ((20, "1 BiS", "#ff8000"), (190, "2–3 BiS", "#a335ee"), (380, "4–5 BiS", "#0070dd"), (590, "Resto", "#1eff00")):
        draw.text((x, y + 28), text, font=font(18, True), fill=color)
    out = Path(destination)
    out.parent.mkdir(parents=True, exist_ok=True)
    board.save(out)


if __name__ == "__main__":
    main(*sys.argv[1:])
