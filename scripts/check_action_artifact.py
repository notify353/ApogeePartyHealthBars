"""Synthetic Actions fixture: exact bytes and paths, never real release data."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile


def fixture():
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w') as archive:
        entry = zipfile.ZipInfo('SyntheticAddon/README.txt', (2026, 1, 1, 0, 0, 0))
        archive.writestr(entry, b'Synthetic compatibility fixture only.\n')
    package = buffer.getvalue()
    receipt = json.dumps({'synthetic': True, 'sha256': hashlib.sha256(package).hexdigest()},
                         sort_keys=True).encode() + b'\n'
    return {'package.zip': package, 'receipt.json': receipt,
            'nested/manifest.json': b'{"synthetic": true}\n'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('create', 'verify', 'verify-receipt'))
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    expected = fixture()
    if args.mode == 'verify-receipt':
        expected = {'receipt.json': expected['receipt.json']}
    if args.mode == 'create':
        args.directory.mkdir(parents=True, exist_ok=False)
        for name, data in expected.items():
            target = args.directory / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    else:
        actual = {p.relative_to(args.directory).as_posix(): p.read_bytes()
                  for p in args.directory.rglob('*') if p.is_file()}
        if actual != expected:
            raise SystemExit('Artifact paths or bytes differ from the synthetic fixture')
        print('Exact artifact paths and bytes verified.')


if __name__ == '__main__':
    main()
