"""Private diagnostic comparisons; never writes to product assets or git docs.

Run after UIUX_CAPTURE: python scripts/compare_uiux_captures.py --stage phase1
Requires Pillow. Raw user screenshots are not copied or published.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / '.dart_tool/uiux-review'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True, choices=['phase1', 'phase2', 'phase3', 'phase4', 'product'])
    parser.add_argument('--baseline', default='before', choices=['before', 'exit-dialog'])
    args = parser.parse_args()
    destination = REVIEW / 'comparisons' / args.stage
    destination.mkdir(parents=True, exist_ok=True)
    entries = []
    for after in sorted((REVIEW / args.stage).glob('*.png')):
        before = REVIEW / args.baseline / after.name
        if not before.exists():
            continue
        sheet = Image.new('RGB', (720, 836), '#e8e7ef')
        draw = ImageDraw.Draw(sheet)
        draw.text((12, 6), f'{after.stem} - isolated widget fixtures, not device screenshots', fill='#2A1F6B')
        draw.text((12, 21), 'BEFORE ' + ('aec64b8' if args.baseline == 'before' else '10df787'), fill='#2A1F6B')
        draw.text((372, 21), f'AFTER {args.stage}', fill='#2A1F6B')
        for x, path in [(0, before), (360, after)]:
            with Image.open(path) as image:
                image = image.convert('RGB').resize((360, 800), Image.Resampling.LANCZOS)
                sheet.paste(image, (x, 36))
        result = destination / after.name
        sheet.save(result, optimize=True)
        entries.append({'screen': after.stem, 'comparison': result.relative_to(ROOT).as_posix(),
                        'before_sha256': hashlib.sha256(before.read_bytes()).hexdigest(),
                        'after_sha256': hashlib.sha256(after.read_bytes()).hexdigest()})
    (destination / 'manifest.json').write_text(json.dumps(entries, indent=2) + '\n', encoding='utf-8')
    print(f'Wrote {len(entries)} private BEFORE/AFTER pairs to {destination}')


if __name__ == '__main__':
    main()
