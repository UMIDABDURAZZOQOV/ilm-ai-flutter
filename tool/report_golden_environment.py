"""Report public SDK/font fingerprints only; never inspect credentials or env vars."""
import argparse
import hashlib
import json
import platform
from pathlib import Path
import subprocess
from urllib.parse import urljoin, urlsplit
from urllib.request import url2pathname


def collect():
    config = Path('.dart_tool/package_config.json').resolve()
    packages = json.loads(config.read_text(encoding='utf-8'))['packages']
    flutter = next(package for package in packages if package['name'] == 'flutter')
    uri = urlsplit(urljoin(config.as_uri(), flutter['rootUri']))
    if uri.scheme != 'file' or uri.netloc not in ('', 'localhost'):
        raise ValueError('Flutter package must use a local file URI')
    sdk = Path(url2pathname(uri.path)).parent.parent
    names = (
        'Roboto-Regular.ttf',
        'Roboto-Medium.ttf',
        'Roboto-Bold.ttf',
        'MaterialIcons-Regular.otf',
    )
    fonts = []
    for name in names:
        path = sdk / 'bin/cache/artifacts/material_fonts' / name
        if path.is_file():
            fonts.append({
                'name': name,
                'bytes': path.stat().st_size,
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            })
        else:
            fonts.append({'name': name, 'missing': True})
    stamp = sdk / 'bin/internal/material_fonts.version'
    result = {
        'schema': 1,
        'os': platform.system(),
        'machine': platform.machine(),
        'fonts': fonts,
        'material_font_archive': stamp.read_text(encoding='utf-8').strip(),
        'environment_variables_or_credentials_read': False,
    }
    command = sdk / 'bin' / ('flutter.bat' if platform.system() == 'Windows' else 'flutter')
    try:
        completed = subprocess.run(
            [str(command), '--no-version-check', '--version', '--machine'],
            check=True, capture_output=True, text=True, encoding='utf-8', timeout=60,
        )
        version = json.loads(completed.stdout)
        result['flutter'] = {key: version.get(key) for key in (
            'frameworkVersion', 'frameworkRevision', 'engineRevision',
            'dartSdkVersion', 'channel',
        )}
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError) as error:
        result['version_probe_error'] = type(error).__name__
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = json.dumps(collect(), indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report, encoding='utf-8')
    print(report, end='')


if __name__ == '__main__':
    main()
