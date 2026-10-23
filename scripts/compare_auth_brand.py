"""Compose controlled, account-free Samsung A12 login comparisons (Pillow)."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path,
                        default=Path('.dart_tool/auth-brand-review'))
    args = parser.parse_args()
    font_path = Path('C:/Windows/Fonts/arial.ttf')
    font = ImageFont.truetype(str(font_path), 20) if font_path.exists() else ImageFont.load_default()
    manifest = {
        'baseline_commit': '6d29d4e1cae59ed494f03677e44d21499a352224',
        'capture': 'Mocked Flutter widget render; no real account or device logout',
        'device_viewport': 'Samsung A12, 720x1600 physical, DPR 1.875',
        'safe_insets_logical': {'top': 24, 'bottom': 48},
        'text_scale': 1,
        'reduce_motion': True,
        'pairs': [],
    }
    for language in ('uz', 'ru', 'en'):
        for theme in ('light', 'dark'):
            name = f'{language}-{theme}'
            paths = [args.root / stage / f'{name}.png' for stage in ('before', 'after')]
            images = [Image.open(p).convert('RGB') for p in paths]
            if any(im.size != (720, 1600) for im in images):
                raise ValueError(f'{name}: expected exact 720x1600 captures')
            canvas = Image.new('RGB', (1464, 1696), '#e5e7eb')
            draw = ImageDraw.Draw(canvas)
            draw.text((16, 12), 'BEFORE | 6d29d4e', font=font, fill='#111827')
            draw.text((760, 12), 'AFTER | official Ilmo face', font=font, fill='#111827')
            for x, im in zip((0, 744), images):
                canvas.paste(im, (x, 48))
            draw.text((16, 1660), f'Samsung A12 viewport | {language.upper()} / {theme} | mocked widget render', font=font, fill='#111827')
            output = args.root / 'comparisons' / f'{name}.png'
            output.parent.mkdir(parents=True, exist_ok=True)
            canvas.save(output)
            # Two review artifacts travel with the report; all six stay local.
            if language == 'ru':
                public = Path('docs/brand/auth-login') / f'{name}.png'
                public.parent.mkdir(parents=True, exist_ok=True)
                canvas.save(public)
            manifest['pairs'].append({
                'name': name,
                'before_sha256': hashlib.sha256(paths[0].read_bytes()).hexdigest(),
                'after_sha256': hashlib.sha256(paths[1].read_bytes()).hexdigest(),
                'comparison': str(output),
            })
    (args.root / 'comparison-manifest.json').write_text(
        json.dumps(manifest, indent=2), encoding='utf-8')
    print(f'Prepared {len(manifest["pairs"])} controlled comparisons.')


if __name__ == '__main__':
    main()
