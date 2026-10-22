"""Compose launcher assets from the approved PNG, without redrawing Ilmo.

Requires Pillow. Run this script, then dart run flutter_launcher_icons, then this
script with --finalize-native. Each step can be run from the repository root.
Only the explicitly listed derived files are written; original assets are read-only.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw
from PIL.PngImagePlugin import PngInfo

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/mascot"
SOURCE = ASSETS / "ilmo_app_icon_new.png"
SOURCE_SHA = "13a5e77618906ab89d8f0c48d68dd6b46214f058b2d535ebc778479f76ea67ea"
INDIGO = (42, 31, 107, 255)
SIZE = 1024
REPORT = ROOT / "docs/brand"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def geometry(image):
    alpha = image.getchannel("A")
    box = alpha.getbbox()
    if box is None:
        raise ValueError("The approved source must contain visible artwork")
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    radius = max(
        math.hypot(x + .5 - cx, y + .5 - cy)
        for y in range(image.height)
        for x in range(image.width)
        if alpha.getpixel((x, y))
    )
    return box, radius


def compose(source, scale, background):
    # Crop only fully transparent outer rows/columns. All nonzero alpha is kept.
    box, _ = geometry(source)
    artwork = source.crop(box)
    dimensions = tuple(max(1, int(side * scale)) for side in artwork.size)
    artwork = artwork.resize(dimensions, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), background)
    offset = tuple((SIZE - side) // 2 for side in dimensions)
    canvas.alpha_composite(artwork, offset)
    return canvas


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    metadata = PngInfo()
    metadata.add(b"sRGB", b"\x00")
    image.save(path, optimize=True, pnginfo=metadata)


def mask(kind, size):
    result = Image.new("L", (size, size))
    draw = ImageDraw.Draw(result)
    edge = size - 1
    if kind == "circle":
        draw.ellipse((0, 0, edge, edge), fill=255)
    elif kind == "rounded":
        draw.rounded_rectangle((0, 0, edge, edge), radius=size * .23, fill=255)
    elif kind == "teardrop":
        draw.ellipse((0, 0, edge, edge), fill=255)
        draw.rectangle((size // 2, 0, edge, size // 2), fill=255)
    else:
        # Superellipse approximation of a squircle; a review mask, not an OEM spec.
        radius = size / 2
        for y in range(size):
            for x in range(size):
                if abs((x + .5 - radius) / radius) ** 4 + abs(
                    (y + .5 - radius) / radius
                ) ** 4 <= 1:
                    result.putpixel((x, y), 255)
    return result


def preview(legacy, foreground):
    sheet = Image.new("RGB", (1000, 620), "#eeedf5")
    draw = ImageDraw.Draw(sheet)
    draw.text((24, 18), "ILM AI - launcher icon review (not a device screenshot)", fill="#2A1F6B")
    old = Image.open(ASSETS / "app_icon.png").convert("RGBA")
    for x, label, icon in [(24, "Previous legacy", old), (244, "New legacy / Store", legacy)]:
        draw.text((x, 50), label, fill="#2A1F6B")
        sheet.paste(icon.resize((192, 192), Image.Resampling.LANCZOS).convert("RGB"), (x, 76))
    guide = Image.new("RGBA", (SIZE, SIZE), INDIGO)
    guide.alpha_composite(foreground)
    guide_draw = ImageDraw.Draw(guide)
    radius = SIZE * 33 / 108
    guide_draw.ellipse((SIZE / 2 - radius, SIZE / 2 - radius,
                        SIZE / 2 + radius, SIZE / 2 + radius), outline="#2DD4BF", width=3)
    sheet.paste(guide.resize((192, 192), Image.Resampling.LANCZOS).convert("RGB"), (484, 76))
    draw.text((484, 50), "108dp layer / 66dp safe circle", fill="#2A1F6B")
    # Android shows a central 72dp viewport of the 108dp foreground layer.
    viewport = SIZE * 72 / 108
    start = (SIZE - viewport) / 2
    visible = Image.new("RGBA", (SIZE, SIZE), INDIGO)
    visible.alpha_composite(foreground)
    visible = visible.resize((768, 768), Image.Resampling.LANCZOS,
                             box=(start, start, start + viewport, start + viewport))
    for index, kind in enumerate(["circle", "squircle", "rounded", "teardrop"]):
        x = 24 + index * 240
        draw.text((x, 302), "Adaptive: " + kind, fill="#2A1F6B")
        for y, side in [(330, 128), (478, 64), (554, 48)]:
            thumb = visible.resize((side, side), Image.Resampling.LANCZOS)
            sheet.paste(thumb.convert("RGB"), (x, y), mask(kind, side))
    save(sheet, REPORT / "launcher_icon_review.png")


def finalize_native():
    """Fix average-resize rounding in launcher_icons 0.14.4/image 4.3.

    That generator can turn an opaque constant (42,31,107,255) into
    (42,30,106,254) at fractional resize ratios. Use the same approved master
    with Pillow for the generated square rasters; keep its adaptive XML/layers.
    """
    if sha(SOURCE) != SOURCE_SHA:
        raise ValueError("Approved source changed")
    manifest_path = REPORT / "launcher_icon_manifest.json"
    report = json.loads(manifest_path.read_text(encoding="utf-8"))
    for row in report["outputs"]:
        if not row["file"].startswith(("android/", "ios/")):
            assert sha(ROOT / row["file"]) == row["sha256"]
    legacy = Image.open(ASSETS / "launcher_icon.png").convert("RGB")
    outputs = {}
    for density, side in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)]:
        path = ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
        assert path.is_file(), "Run flutter_launcher_icons first"
        outputs[path] = side
    directory = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((directory / "Contents.json").read_text(encoding="utf-8"))
    for icon in contents["images"]:
        name = icon.get("filename")
        if name:
            assert Path(name).name == name and name.endswith(".png")
            side = int(float(icon["size"].split("x")[0]) * float(icon["scale"][:-1]))
            outputs[directory / name] = side
    for path, side in outputs.items():
        save(legacy.resize((side, side), Image.Resampling.LANCZOS), path)
    report["outputs"] = [row for row in report["outputs"]
                         if not row["file"].startswith(("android/", "ios/"))]
    report["outputs"] += [
        {"file": path.relative_to(ROOT).as_posix(), "sha256": sha(path),
         "bytes": path.stat().st_size} for path in outputs
    ]
    manifest_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Finalized {len(outputs)} native square icons with opaque indigo edges")


def main():
    if sha(SOURCE) != SOURCE_SHA:
        raise ValueError("Source changed: review the new artwork before regenerating")
    originals = [ASSETS / name for name in ["app_icon.png", "app_icon_foreground.png"]]
    before = {path.name: sha(path) for path in originals}
    source = Image.open(SOURCE).convert("RGBA")
    box, radius = geometry(source)
    # Legacy/iOS/Store use 88% of the square. No rounded corners or new shadows.
    legacy = compose(source, SIZE * .88 / max(box[2] - box[0], box[3] - box[1]), INDIGO)
    # Android: all nonzero alpha, including faint edge pixels, inside the 66dp
    # safe circle. Reserve 1dp for rounding and resampling at native densities.
    scale = (SIZE * 32 / 108 - 2) / radius
    foreground = compose(source, scale, (0, 0, 0, 0))
    fg_alpha = foreground.getchannel("A")
    max_radius = max(
        math.hypot(x + .5 - SIZE / 2, y + .5 - SIZE / 2)
        for y in range(SIZE) for x in range(SIZE) if fg_alpha.getpixel((x, y))
    )
    assert max_radius < SIZE * 33 / 108
    paths = [ASSETS / "launcher_icon.png", ASSETS / "launcher_icon_foreground.png",
             ROOT / "artwork/icons/ilm_ai_play_store_512.png"]
    store = legacy.resize((512, 512), Image.Resampling.LANCZOS)
    for image, path in zip([legacy, foreground, store], paths):
        save(image, path)
    assert store.getchannel("A").getextrema() == (255, 255)
    assert paths[-1].stat().st_size <= 1024 * 1024
    assert before == {path.name: sha(path) for path in originals}
    preview(legacy, foreground)
    report = {
        "source": {"file": SOURCE.relative_to(ROOT).as_posix(), "sha256": SOURCE_SHA,
                   "dimensions": list(source.size), "alpha_bbox": list(box)},
        "original_backups": before,
        "background": "#2A1F6B", "adaptive_inset_percent": 0,
        "adaptive_canvas_dp": 108, "safe_circle_diameter_dp": 66,
        "foreground_nonzero_alpha_radius_dp": round(max_radius * 108 / SIZE, 4),
        "outputs": [{"file": path.relative_to(ROOT).as_posix(), "sha256": sha(path),
                     "bytes": path.stat().st_size} for path in paths],
    }
    (REPORT / "launcher_icon_manifest.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--finalize-native", action="store_true",
                        help="Run after flutter_launcher_icons to normalize square rasters")
    if parser.parse_args().finalize_native:
        finalize_native()
    else:
        main()
