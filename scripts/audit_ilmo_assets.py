"""Read-only Ilmo PNG audit; optional reports never write into assets/."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "mascot"
POSES = ["hello", "thinking", "explaining", "happy", "sad"]


def inspect(path):
    with Image.open(path) as source:
        image = source.convert("RGBA")
        alpha = image.getchannel("A")
        hist = alpha.histogram()
        pixels = image.width * image.height
        bbox = alpha.getbbox()
        solid = alpha.point(lambda value: 255 if value >= 128 else 0).getbbox()
        border = [alpha.crop((0, 0, image.width, 1)),
                  alpha.crop((0, image.height - 1, image.width, image.height)),
                  alpha.crop((0, 1, 1, image.height - 1)),
                  alpha.crop((image.width - 1, 1, image.width, image.height - 1))]
        return {
            "file": path.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size,
            "dimensions": list(image.size),
            "source_mode": source.mode,
            "alpha_bbox": list(bbox) if bbox else None,
            "alpha_128_bbox": list(solid) if solid else None,
            "transparent_fraction": round(hist[0] / pixels, 6),
            "semi_transparent_fraction": round(sum(hist[1:255]) / pixels, 6),
            "opaque_fraction": round(hist[255] / pixels, 6),
            "nontransparent_border_pixels": sum(
                sum(layer.histogram()[1:]) for layer in border),
            "decoded_rgba_bytes": pixels * 4,
        }


def safe_output(value):
    path = (ROOT / value).resolve()
    if path.is_relative_to((ROOT / "assets").resolve()):
        raise ValueError("Audit outputs must not replace source assets")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def preview(path):
    # Diagnostic composites only. The original PNGs are never resaved.
    names = [f"ilmo_{pose}" for pose in POSES]
    names += ["app_icon", "app_icon_foreground", "splash_logo"]
    sheet = Image.new("RGB", (1600, 1200), "#e9e9ed")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(names):
        x, y = (index % 4) * 400, (index // 4) * 600
        draw.text((x + 12, y + 12), name, fill="#18152b")
        with Image.open(ASSETS / f"{name}.png") as source:
            image = source.convert("RGBA")
            for col, background in enumerate(["#ffffff", "#13102c"]):
                panel = Image.new("RGBA", (188, 255), background)
                thumb = image.resize((188, 188), Image.Resampling.LANCZOS)
                panel.alpha_composite(thumb, (0, 25))
                sheet.paste(panel.convert("RGB"), (x + 8 + col * 196, y + 38))
            offset = 0
            for size in [48, 72, 96, 140]:
                panel = Image.new("RGBA", (size, size), "#ffffff")
                panel.alpha_composite(image.resize((size, size), Image.Resampling.LANCZOS))
                sheet.paste(panel.convert("RGB"), (x + 8 + offset, y + 325))
                draw.text((x + 8 + offset, y + 480), f"{size}px", fill="#18152b")
                offset += size + 8
    sheet.save(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report")
    parser.add_argument("--preview")
    args = parser.parse_args()
    rows = [inspect(path) for path in sorted(ASSETS.glob("*.png"))]
    report = {"schema_version": 1, "assets": rows,
              "total_bytes": sum(row["bytes"] for row in rows),
              "note": "Pixel metrics do not certify artistic consistency or halo quality."}
    encoded = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.report:
        safe_output(args.report).write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")
    if args.preview:
        preview(safe_output(args.preview))


if __name__ == "__main__":
    main()
