"""Offline aggregate prototype. No network, installer, publisher, or cleanup commands."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LOCK = ROOT / 'distribution' / 'sources.lock.json'
CHILDREN = ('ApogeeHeals', 'ApogeeKeybinds', 'ApogeeGroupAlert',
            'ApogeeEssentials', 'ApogeeTank')
MARKER = 'ApogeePartyHealthBars'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode('utf-8')


def safe_path(value):
    require(isinstance(value, str) and value and '\\' not in value
            and ':' not in value and '\x00' not in value,
            'Unsafe package path')
    p = PurePosixPath(value)
    require(not p.is_absolute() and all(x not in ('', '.', '..') for x in value.split('/')),
            'Unsafe package path')
    return value


def read_lock(path=DEFAULT_LOCK):
    lock = json.loads(Path(path).read_text(encoding='utf-8'))
    require(lock['schema'] == 1 and lock['publicationAllowed'] is False, 'Prototype lock required')
    require(lock['projectId'] == 1608100 and lock['client'] == {
        'flavor': 'forever', 'interface': 16001, 'version': '1.60.1',
        'reviewedBuild': '1.60.1.70009', 'curseforgeVersionTypeId': 88568},
        'Unexpected client/project; no flavor fallback is permitted')
    require(re.fullmatch(r'[0-9A-Za-z.-]+', lock['version']), 'Unsafe version')
    require([c['name'] for c in lock['children']] == list(CHILDREN), 'Exact five children required')
    for child in lock['children']:
        require(re.fullmatch('[0-9a-f]{40}', child['commit']), 'Immutable commit required')
        require(child['repository'] == 'https://github.com/notify353/' + child['name'] + '.git',
                'Unexpected source identity')
        require(child['toc'] == child['name'] + '.toc', 'Canonical TOC required')
        require(child['files'] and child['toc'] in child['files'] and 'LICENSE' in child['files'],
                'Missing TOC or license')
        seen = set()
        for path, digest in child['files'].items():
            safe_path(path)
            require(path.casefold() not in seen, 'Case-colliding source path')
            seen.add(path.casefold())
            require(re.fullmatch('[0-9a-f]{64}', digest), 'Invalid source hash')
    return lock


def git_bytes(repo, *args):
    result = subprocess.run(['git', '-C', str(repo), *args], capture_output=True)
    require(result.returncode == 0, 'Git read failed: ' + ' '.join(args[:2]))
    return result.stdout


def source_tree(repo, revision):
    """Read committed bytes, never checkout/reset/fetch or include dirty local files."""
    require(re.fullmatch('[0-9a-f]{40}', revision), 'Immutable source revision required')
    require(git_bytes(repo, 'rev-parse', revision + '^{commit}').decode().strip() == revision,
            'Pinned commit unavailable')
    data = git_bytes(repo, 'archive', '--format=tar', revision)
    result = {}
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        for entry in archive:
            if entry.isdir():
                continue
            safe_path(entry.name)
            require(entry.isfile(), 'Source links/submodules are not allowed')
            result[entry.name] = archive.extractfile(entry).read()
    return result


def toc_info(data):
    metadata, runtime = {}, []
    for raw in data.decode('utf-8-sig').splitlines():
        line = raw.strip()
        if line.startswith('##') and ':' in line:
            key, value = line[2:].split(':', 1)
            require(key.strip() not in metadata, 'Duplicate TOC metadata')
            metadata[key.strip()] = value.strip()
        elif line and not line.startswith('#'):
            runtime.append(safe_path(line.replace('\\', '/')))
    require(len(runtime) == len(set(p.casefold() for p in runtime)), 'Duplicate loaded module')
    return metadata, runtime


def child_contract(child, files):
    meta, runtime = toc_info(files[child['toc']])
    require(meta.get('Interface') == '16001', 'Forever-only TOC required')
    require(meta.get('Version') == child['version'], 'Child version drift')
    require({k: v for k, v in meta.items() if k.startswith('SavedVariables')} == child['savedVariables'],
            'Child SavedVariables identity changed')
    require(not any(k in meta for k in ('Dependencies', 'RequiredDeps', 'OptionalDeps', 'LoadWith')),
            'Children must remain independent')
    require(runtime and all(p in files for p in runtime), 'Missing runtime module')
    require({p for p in files if p.endswith('.toc')} == {child['toc']}, 'Unexpected alternate TOC')
    require({p for p in files if p.endswith(('.lua', '.xml'))} == set(runtime),
            'Unlisted runtime or duplicated embedded addon')
    for path in runtime:
        require(files[path], 'Empty runtime source')
    return runtime


def marker_files(lock, candidate=False):
    if candidate:
        toc = ('## Interface: 16001\n## Title: Apogee Distribution\n'
               '## Notes: Distribution identity only. Gameplay belongs to independent Apogee addons.\n'
               '## Version: ' + lock['version'] + '\n## X-Curse-Project-ID: 1608100\n'
               '## X-Apogee-Distribution-Only: 1\n## X-Apogee-Distribution-Schema: 1\n')
        return {MARKER + '/' + MARKER + '.toc': toc.encode(),
                MARKER + '/README.md': (
                    '# Apogee distribution identity\n\nThis addon contains no executable code, '
                    'saved data, bindings, settings or gameplay.\n'
                    'Gameplay is provided by five independent Apogee addons.\n'
                    'Local candidate; native-client and CurseForge updater acceptance pending.\n').encode()}
    toc = ('## Interface: 16001\n## Title: Apogee Distribution Prototype (DO NOT INSTALL)\n'
           '## Notes: Metadata-only fixture; current Keybinds blocks this loaded addon.\n'
           '## Version: ' + lock['version'] + '\n## X-Curse-Project-ID: 1608100\n'
           '## X-Apogee-Distribution-Only: 1\n')
    return {MARKER + '/' + MARKER + '.toc': toc.encode(),
            MARKER + '/README.md': (
                '# Metadata-only test fixture\n\nNo gameplay, settings, saved data or dependencies.\n'
                'DO NOT INSTALL: unmodified Keybinds blocks a loaded APHB marker.\n').encode()}


def expected_hashes(lock, variant):
    require(variant in ('children-only', 'marker-fixture', 'local-candidate'), 'Unknown variant')
    hashes = {child['name'] + '/' + p: h for child in lock['children'] for p, h in child['files'].items()}
    if variant != 'children-only':
        hashes.update({p: sha(data) for p, data in marker_files(lock, variant == 'local-candidate').items()})
    return hashes


def collect(lock, sources_root, variant):
    result = {}
    for child in lock['children']:
        repo = Path(sources_root) / child['name']
        require(git_bytes(repo, 'remote', 'get-url', 'origin').decode().strip() == child['repository'],
                'Source remote identity mismatch')
        tree = source_tree(repo, child['commit'])
        files = {}
        for p, digest in child['files'].items():
            require(p in tree and sha(tree[p]) == digest, child['name'] + ': pinned file mismatch: ' + p)
            files[p] = tree[p]
        if child['name'] == 'ApogeeKeybinds':
            for p in ('Actions/Defaults.lua', 'UI/Cooldowns.lua', 'Rules/SelfBuffs.lua'):
                require(tree.get('common/' + p) == files[p], 'Keybinds generated policy drift')
        child_contract(child, files)
        result.update({child['name'] + '/' + p: data for p, data in files.items()})
    if variant != 'children-only':
        result.update(marker_files(lock, variant == 'local-candidate'))
    require({p: sha(data) for p, data in result.items()} == expected_hashes(lock, variant), 'Payload mismatch')
    return result


def zip_bytes(files):
    output = io.BytesIO()
    # Stored data + fixed timestamps/permissions/order give cross-run deterministic bytes.
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_STORED) as archive:
        for path, data in sorted(files.items()):
            safe_path(path)
            info = zipfile.ZipInfo(path, (1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    return output.getvalue()


def validate(data, lock, variant):
    expected = expected_hashes(lock, variant)
    files = {}
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        require(len(archive.infolist()) == len(expected), 'Wrong archive entry count')
        for entry in archive.infolist():
            safe_path(entry.filename)
            require(entry.filename in expected and entry.filename not in files, 'Unexpected/duplicate archive path')
            require(not entry.is_dir() and (entry.external_attr >> 16) == 0o100644,
                    'Only regular files allowed')
            require(entry.file_size <= 4 * 1024 * 1024, 'Oversized package entry')
            body = archive.read(entry)
            require(sha(body) == expected[entry.filename], 'Archive byte mismatch: ' + entry.filename)
            files[entry.filename] = body
    require(set(files) == set(expected), 'Incomplete package')
    for child in lock['children']:
        prefix = child['name'] + '/'
        child_contract(child, {p[len(prefix):]: body for p, body in files.items() if p.startswith(prefix)})
    if variant != 'children-only':
        meta, runtime = toc_info(files[MARKER + '/' + MARKER + '.toc'])
        require(not runtime and not any(k.startswith('SavedVariables') for k in meta), 'Marker has runtime/data')
        require(not any(k in meta for k in ('Dependencies', 'RequiredDeps', 'OptionalDeps', 'LoadWith')),
                'Marker has dependency')
        if variant == 'local-candidate':
            require(meta.get('X-Apogee-Distribution-Only') == '1'
                    and meta.get('X-Apogee-Distribution-Schema') == '1', 'Unknown marker contract')
    return files


def build(lock, sources_root, output, variant):
    files = collect(lock, sources_root, variant)
    data = zip_bytes(files)
    validate(data, lock, variant)
    output = Path(output)
    # All output is contained in a newly created directory; never overwrite previous results.
    output.mkdir(parents=True, exist_ok=False)
    name = 'ApogeePartyHealthBars-' + lock['version'] + '-' + variant + '.zip'
    manifest = {'schema': 1, 'publicationAllowed': False, 'installApproved': False,
                'variant': variant, 'projectId': lock['projectId'], 'client': lock['client'],
                'lockSha256': sha(canonical(lock)), 'archive': name, 'archiveSha256': sha(data),
                'children': [{k: c[k] for k in ('name', 'commit', 'version', 'savedVariables')}
                             for c in lock['children']], 'files': expected_hashes(lock, variant),
                'knownBlockers': ['CurseForge install/update ownership untested',
                                 'Combined native client acceptance pending'] + (
                                     ['Loaded APHB marker blocks unmodified Keybinds']
                                     if variant == 'marker-fixture' else
                                     ['Overlay leaves legacy APHB loadable if already installed']
                                     if variant == 'children-only' else
                                     ['Requires backup-first migration; ZIP overlay is not an installer'])}
    (output / name).write_bytes(data)
    (output / 'manifest.json').write_bytes(canonical(manifest))
    (output / (name + '.sha256')).write_text(sha(data) + '  ' + name + '\n', encoding='utf-8')
    return output / name


def preflight(lock, versions):
    """Offline check of a supplied API response; never performs an upload or auth request."""
    require(isinstance(versions, list), 'Expected raw version API list')
    matches = [row for row in versions if isinstance(row, dict)
               and row.get('name') == lock['client']['version']
               and row.get('gameVersionTypeID') == lock['client']['curseforgeVersionTypeId']]
    require(len(matches) == 1, 'Exact Forever version match required; no fallback')
    version_id = matches[0].get('id')
    require(type(version_id) is int and version_id > 0
            and version_id != lock['client']['curseforgeVersionTypeId'], 'Invalid per-version ID')
    return {'gameVersions': [version_id], 'publicationAllowed': False,
            'note': 'Input authenticity/freshness and publication approval are separate gates.'}


def review_packager(lock, data):
    require(sha(data) == lock['futurePackager']['releaseScriptSha256'], 'Unreviewed packager bytes')
    require(b'16???) game_type="forever"' in data and b'forever) game_id=88568' in data,
            'Forever mapping missing')
    return {'sha256': sha(data), 'executed': False, 'productionWorkflowChanged': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lock', type=Path, default=DEFAULT_LOCK)
    sub = parser.add_subparsers(dest='command', required=True)
    b = sub.add_parser('build')
    b.add_argument('--sources-root', type=Path, required=True)
    b.add_argument('--output', type=Path, required=True)
    b.add_argument('--variant', choices=('children-only', 'marker-fixture', 'local-candidate'), default='children-only')
    v = sub.add_parser('validate')
    v.add_argument('--archive', type=Path, required=True)
    v.add_argument('--variant', choices=('children-only', 'marker-fixture', 'local-candidate'), required=True)
    p = sub.add_parser('preflight')
    p.add_argument('--versions', type=Path, required=True)
    r = sub.add_parser('review-packager')
    r.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    try:
        lock = read_lock(args.lock)
        if args.command == 'build':
            print(build(lock, args.sources_root, args.output, args.variant))
        elif args.command == 'validate':
            print('Verified', len(validate(args.archive.read_bytes(), lock, args.variant)), 'exact files')
        elif args.command == 'preflight':
            print(json.dumps(preflight(lock, json.loads(args.versions.read_text(encoding='utf-8')))))
        else:
            print(json.dumps(review_packager(lock, args.source.read_bytes())))
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        parser.exit(1, 'Prototype stopped: ' + str(error) + '\n')


if __name__ == '__main__':
    main()
