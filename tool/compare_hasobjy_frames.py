"""Compare real simulator captures with Figma exports at 390 x 844.

Requires Pillow (verification tooling only). Run from the project root:
python3 tool/compare_hasobjy_frames.py --root reports/figma-design/update-2026-10-16
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageStat

ROOT = Path('reports/figma-design/audit')
FRAMES = {
    'A-S01': '9-2', 'A-S03': '9-15', 'A-S04': '9-34',
    'A-S05': '9-65', 'A-S06': '9-81', 'A-S07': '9-101',
    'B-S01': '10-2', 'B-S03': '10-40', 'B-S04': '10-69',
    'B-S05': '10-92', 'B-S06': '10-115',
}

def flatten(path):
    image = Image.open(path).convert('RGBA')
    white = Image.new('RGBA', image.size, 'white')
    white.alpha_composite(image)
    return white.convert('RGB')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    root = args.root
    manifest = root / 'frames.json'
    frames = {f['key']: f['node'].replace(':', '-') for f in json.loads(manifest.read_text())} if manifest.exists() else FRAMES
    output = root / 'comparison'
    output.mkdir(exist_ok=True)
    results = []
    pairs = []
    for frame, node in frames.items():
        figma = flatten(root / 'figma' / f'{node}.png' if manifest.exists() else root / f'figma-{node}.png')
        actual = flatten(root / 'device-390' / f'{frame}.png')
        if figma.size != (390, 844) or actual.size != figma.size:
            raise ValueError(f'{frame}: mismatched capture dimensions')
        difference = ImageChops.difference(figma, actual)
        Image.blend(figma, actual, .5).save(output / f'{frame}-overlay.png')
        difference.save(output / f'{frame}-diff.png')
        # Show Figma and the actual device render without scaling either image.
        pair = Image.new('RGB', (780, 874), 'white')
        pair.paste(figma, (0, 30))
        pair.paste(actual, (390, 30))
        draw = ImageDraw.Draw(pair)
        draw.text((12, 8), f'{frame} / FIGMA', fill='black')
        draw.text((402, 8), 'FLUTTER / iOS SIMULATOR', fill='black')
        pair.save(output / f'{frame}-pair.png')
        pairs.append(pair)
        # Content excludes only the deterministic status bar, not app content.
        content = difference.crop((0, 44, 390, 844))
        maximum_channel = ImageChops.lighter(
            ImageChops.lighter(*content.split()[:2]), content.split()[2])
        histogram = maximum_channel.histogram()
        pixels = 390 * 800
        results.append({
            'frame': frame, 'nodeId': node.replace('-', ':'),
            'size': [390, 844],
            'meanAbsoluteChannelErrorOutOf255': round(
                sum(ImageStat.Stat(content).mean) / 3, 4),
            'pixelsWithEveryChannelWithin8Percent': round(
                100 * sum(histogram[:9]) / pixels, 3),
            'note': 'Whole content image, including background; not a visual acceptance score.',
        })
    for index in range(0, len(pairs), 4):
        group = pairs[index:index + 4]
        sheet = Image.new('RGB', (780 * len(group), 874), 'white')
        for column, pair in enumerate(group):
            sheet.paste(pair, (column * 780, 0))
        sheet.save(output / f'contact-{index // 4}.png')
    (output / 'metrics.json').write_text(json.dumps(results, indent=2) + '\n')
    for result in results:
        print(result['frame'], 'MAE', result['meanAbsoluteChannelErrorOutOf255'],
              'within8', result['pixelsWithEveryChannelWithin8Percent'])

if __name__ == '__main__':
    main()
