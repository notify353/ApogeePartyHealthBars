"""Backup-first local migration. No publishing, game control, or file deletion."""
import argparse
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
import distribution as d

NAMES = (d.MARKER,) + d.CHILDREN


def ordinary(path):
    """Reject symlinks/junctions in every existing ancestor before filesystem use."""
    path = Path(path).absolute()
    for item in (path, *path.parents):
        if item.exists() or item.is_symlink():
            info = item.lstat()
            d.require(not stat.S_ISLNK(info.st_mode)
                      and not getattr(info, 'st_file_attributes', 0) & 0x400,
                      'Linked/reparse path refused')
    return path


def under(root, relative):
    d.safe_path(relative)
    target = ordinary(Path(root) / relative)
    d.require(target.is_relative_to(Path(root).absolute()), 'Path escapes owned root')
    return target


def tree(root):
    root = ordinary(root)
    result = {}
    if not root.exists():
        return result
    d.require(root.is_dir(), 'Directory expected')
    for current, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            item = ordinary(Path(current) / name)
            if item.is_file():
                rel = item.relative_to(root).as_posix()
                d.safe_path(rel)
                result[rel] = item.read_bytes()
    d.require(len({p.casefold() for p in result}) == len(result), 'Case-colliding installed paths')
    return result


def managed(addons, names=NAMES):
    result = {}
    for name in names:
        result.update({name + '/' + p: b for p, b in tree(under(addons, name)).items()})
    return result


def hashes(files):
    return {p: d.sha(b) for p, b in files.items()}


def protected(client, names=NAMES):
    # Do not open/import/copy private saved data. Observe filesystem metadata only.
    def metadata(root):
        result = {}
        if not root.exists(): return result
        for current, dirs, files in os.walk(ordinary(root), followlinks=False):
            for name in dirs + files:
                item = ordinary(Path(current) / name)
                if item.is_file():
                    info = item.stat()
                    result[item.relative_to(root).as_posix()] = [info.st_size, info.st_mtime_ns]
        return result
    result = {'WTF/' + p: value for p, value in metadata(under(client, 'WTF')).items()}
    addons = under(client, 'Interface/AddOns')
    for item in addons.iterdir():
        if item.name not in names:
            ordinary(item)
            if item.is_dir():
                result.update({'Interface/AddOns/' + item.name + '/' + p: v for p, v in metadata(item).items()})
            elif item.is_file():
                info = item.stat()
                result['Interface/AddOns/' + item.name] = [info.st_size, info.st_mtime_ns]
    return result


def catalog(path):
    value = json.loads(Path(path).read_text(encoding='utf-8'))
    d.require(value['schema'] == 1, 'Unknown recognition catalog')
    for p, accepted in value['files'].items():
        d.safe_path(p)
        d.require(p.split('/')[0] in NAMES and accepted, 'Invalid recognized source')
    return value


def plan(client, payload, known, names=NAMES):
    client = ordinary(client)
    addons = under(client, 'Interface/AddOns')
    d.require(addons.is_dir(), 'Existing AddOns destination required')
    before = managed(addons, names)
    desired = dict(payload)
    marker = payload.get(d.MARKER + '/' + d.MARKER + '.toc')
    inventory = []
    for p, body in before.items():
        accepted = d.sha(body) in known['files'].get(p, [])
        status = 'recognized' if accepted else 'unknown-preserved'
        if p.lower().endswith('.toc'):
            root = p.split('/')[0]
            if root == d.MARKER and marker is not None:
                # All TOCs, including nested/alternate variants, are treated as potential loaders.
                d.require(body == marker or d.sha(body) in known['legacyTocHashes'],
                          'Unrecognized APHB loader; no changes made: ' + p)
                desired[p] = marker
                status = 'inert-marker' if body == marker else 'neutralize-known-loader'
            else:
                d.require(p in payload, 'Unexpected child loader; no changes made: ' + p)
        if p in payload and body != payload[p]:
            d.require(accepted, 'Unexpected conflicting edit; no changes made: ' + p)
        inventory.append({'path': p, 'sha256': d.sha(body), 'status': status})
    # Catch files where a needed directory will be created before any backup/write.
    for p in desired:
        target = under(addons, p)
        d.require(not target.exists() or target.is_file(), 'File target is a directory')
        for parent in target.parents:
            if parent == addons:
                break
            d.require(not parent.exists() or parent.is_dir(), 'Parent is a file')
    writes = {p: b for p, b in desired.items() if before.get(p) != b}
    return {'before': before, 'desired': desired, 'writes': writes, 'inventory': inventory}


def put(root, files):
    for p, b in files.items():
        target = under(root, p)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b)
        d.require(target.read_bytes() == b, 'Write verification failed')


def put_atomic(root, files):
    """Same-directory replacement prevents readers seeing a truncated DEV file."""
    for p, body in files.items():
        target = under(root, p)
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=target.parent, prefix='.apogee-', suffix='.tmp', delete=False) as staged:
            temporary = Path(staged.name)
            staged.write(body)
            staged.flush()
            os.fsync(staged.fileno())
        # On failure retain the temporary file for diagnosis; never alter the original.
        d.require(temporary.read_bytes() == body, 'Staged write verification failed')
        os.replace(temporary, target)
        d.require(target.read_bytes() == body, 'Write verification failed')


def apply(client, payload, known, backup, expected_plan=None, names=NAMES, atomic_dev=False):
    if atomic_dev:
        d.require(set(names) == {n + 'Dev' for n in NAMES}, 'Atomic live install is DEV-only')
    client = ordinary(client)
    backup = ordinary(backup)
    d.require(not backup.is_relative_to(client) and not client.is_relative_to(backup),
              'Backup must be outside the client')
    current = plan(client, payload, known, names)
    if expected_plan is not None:
        d.require(hashes(current['before']) == hashes(expected_plan['before']), 'Destination changed after review')
    saved = protected(client, names)
    backup.mkdir(parents=True, exist_ok=False)
    # Complete byte-verified backup before the first destination write.
    put(backup / 'addons-before', current['before'])
    d.require(tree(backup / 'addons-before') == current['before'], 'Addon backup verification failed')
    journal = {'schema': 1, 'client': str(client), 'status': 'prepared', 'names': list(names),
               'before': hashes(current['before']), 'after': hashes(current['desired']),
               'writes': hashes(current['writes']), 'inventory': current['inventory'],
               'protectedDigest': d.sha(d.canonical(saved)), 'protectedCount': len(saved)}
    journal_path = backup / 'transaction.json'
    journal_path.write_bytes(d.canonical(journal))
    d.require(managed(client / 'Interface/AddOns', names) == current['before'], 'Destination changed during backup')
    d.require(protected(client, names) == saved, 'Preferences changed during backup')
    try:
        journal['status'] = 'applying'; journal_path.write_bytes(d.canonical(journal))
        (put_atomic if atomic_dev else put)(client / 'Interface/AddOns', current['writes'])
        installed = managed(client / 'Interface/AddOns', names)
        d.require(all(installed.get(p) == b for p, b in current['desired'].items()), 'Installed payload mismatch')
        d.require(all(installed.get(p) == b for p, b in current['before'].items()
                      if p not in current['writes']), 'Preserved file changed')
        d.require(protected(client, names) == saved, 'Protected state changed; backup retained')
        journal['status'] = 'installed'
        journal_path.write_bytes(d.canonical(journal))
    except Exception:
        journal['status'] = 'incomplete-recover-with-rollback'
        journal_path.write_bytes(d.canonical(journal))
        raise
    return journal


def rollback(backup):
    backup = ordinary(backup)
    journal_path = backup / 'transaction.json'
    journal = json.loads(journal_path.read_text(encoding='utf-8'))
    d.require(journal['schema'] == 1 and journal['status'] in (
        'installed', 'applying', 'incomplete-recover-with-rollback', 'prepared'), 'No pending rollback')
    client = ordinary(journal['client'])
    d.require(not backup.is_relative_to(client) and not client.is_relative_to(backup), 'Unsafe backup location')
    addons = under(client, 'Interface/AddOns')
    names = tuple(journal.get('names', NAMES))
    d.require(names and all(n in NAMES or n.removesuffix('Dev') in NAMES for n in names), 'Unknown journal family')
    original = tree(backup / 'addons-before')
    d.require(hashes(original) == journal['before'], 'Backup corrupted; no rollback writes')
    current = managed(addons, names)
    for p, digest in journal['writes'].items():
        d.require(p.split('/')[0] in names, 'Journal escapes managed addons')
        body = current.get(p)
        d.require(body is None and p not in original
                  or body is not None and d.sha(body) in (digest, journal['before'].get(p)),
                  'User edit after installation; no rollback writes: ' + p)
    saved = protected(client, names)
    quarantine = backup / 'rollback-added-files'
    d.require(not quarantine.exists(), 'Existing rollback output refused')
    quarantine.mkdir()
    for p in journal['writes']:
        if p in original:
            put(addons, {p: original[p]})
        elif p in current:
            # Preserve new candidate files outside AddOns rather than deleting them.
            source, target = under(addons, p), under(quarantine, p)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(target))
    after = managed(addons, names)
    d.require(all(after.get(p) == b for p, b in original.items() if p in journal['writes']), 'Rollback mismatch')
    d.require(all(p not in after for p in journal['writes'] if p not in original), 'Added files still active')
    d.require(protected(client, names) == saved, 'Rollback touched protected state')
    journal['status'] = 'rolled-back'
    journal_path.write_bytes(d.canonical(journal))
    return journal


def real_client_preflight(client, lock, allow_running_dev=False):
    client = ordinary(client)
    d.require(client.name == '_classic_beta_', 'Only reviewed Forever client is supported')
    lines = (client.parent / '.build.info').read_text(encoding='utf-8-sig').splitlines()
    keys = [k.split('!')[0] for k in lines[0].split('|')]
    rows = [dict(zip(keys, line.split('|'))) for line in lines[1:]]
    d.require([r.get('Version') for r in rows if r.get('Product') == 'wow_classic_beta']
              == [lock['client']['reviewedBuild']], 'Forever build changed; review required')
    d.require(os.name == 'nt', 'Real installation is supported on reviewed Windows host only')
    result = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq WowB.exe', '/FO', 'CSV', '/NH'],
                            capture_output=True, text=True, check=True)
    running = 'wowb.exe' in result.stdout.lower()
    d.require(allow_running_dev or not running, 'Forever client is running; close it before migration')
    return running


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('inspect', 'install', 'rollback'))
    parser.add_argument('--client-root', type=Path)
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--lock', type=Path, default=d.ROOT / 'distribution/candidate.lock.json')
    parser.add_argument('--catalog', type=Path, default=d.ROOT / 'distribution/migration-known.json')
    parser.add_argument('--backup', type=Path)
    args = parser.parse_args()
    try:
        lock = d.read_lock(args.lock)
        if args.command == 'rollback':
            d.require(args.backup is not None, '--backup required')
            journal = json.loads((args.backup / 'transaction.json').read_text())
            real_client_preflight(Path(journal['client']), lock)
            result = rollback(args.backup)
        else:
            d.require(args.client_root is not None and args.archive is not None, 'Client/archive required')
            real_client_preflight(args.client_root, lock)
            payload = d.validate(args.archive.read_bytes(), lock, 'local-candidate')
            known = catalog(args.catalog)
            preview = plan(args.client_root, payload, known)
            if args.command == 'inspect':
                print(json.dumps({'filesToWrite': len(preview['writes']), 'inventory': preview['inventory']}))
                return
            d.require(args.backup is not None, 'New external --backup required')
            result = apply(args.client_root, payload, known, args.backup, preview)
        print(json.dumps({'status': result['status'], 'writeCount': len(result['writes']),
                          'protectedCount': result['protectedCount'], 'publicationAllowed': False}))
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, 'Migration stopped: ' + str(error) + '\n')


if __name__ == '__main__':
    main()
