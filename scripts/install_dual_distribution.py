"""Install exact aggregate ZIPs. Normal runs update DEV only; PROD retrofit is explicit."""
import argparse
import copy
import json
from pathlib import Path
import sys
import subprocess

sys.dont_write_bytecode = True
import distribution as d
import dual_distribution as dual
import migrate_distribution as m


def payloads(lock, sources_root, artifacts, initial=False):
    result = {}
    for family in (('PROD', 'DEV') if initial else ('DEV',)):
        expected, _ = dual.family_files(lock, sources_root, family)
        archive = Path(artifacts) / ('Apogee-' + lock['version'] + '-' + family + '.zip')
        result.update(dual.validate(archive.read_bytes(), expected))
    return result


def prepare(client, payload, known, initial=False, previous=None):
    names = tuple(n + 'Dev' for n in m.NAMES)
    if initial:
        names = m.NAMES + names
    d.require(set(p.split('/')[0] for p in payload) == set(names), 'Exact family roots required')
    before = m.managed(Path(client) / 'Interface/AddOns', names)
    known = copy.deepcopy(known)
    if previous is not None:
        d.require(previous['schema'] == 1 and previous['status'] == 'installed', 'Prior installed receipt required')
        d.require(Path(previous['client']).absolute() == Path(client).absolute(), 'Receipt belongs to another client')
        for p, h in previous['after'].items():
            d.safe_path(p)
            d.require(p.split('/')[0] in m.NAMES + tuple(n + 'Dev' for n in m.NAMES), 'Receipt escapes families')
            known['files'].setdefault(p, []).append(h)
            if p.startswith(d.MARKER + '/') and p.lower().endswith('.toc'):
                known['legacyTocHashes'].append(h)
    for p, b in payload.items():
        known['files'].setdefault(p, []).append(d.sha(b))
    preserved_docs = []
    desired = dict(payload)
    # Documentation is not needed to activate the artifact; never replace local edited notes.
    for p, b in before.items():
        if p in desired and b != desired[p] and p.lower().endswith(('.md', '.txt')):
            preserved_docs.append(p)
            del desired[p]
    preview = m.plan(client, desired, known, names)
    return desired, known, names, preview, preserved_docs


def activation(preview):
    writes = preview['writes']
    discovery = sorted(p for p in writes if p not in preview['before'] or p.lower().endswith('.toc'))
    return {'action': 'user-reload-after-install' if writes else 'none',
            'discoveryChanges': discovery,
            'restartRequired': 'unverified-if-reload-does-not-discover-changes' if discovery else False}


def install(client, payload, known, backup, initial=False, previous=None):
    desired, known, names, preview, docs = prepare(client, payload, known, initial, previous)
    result = m.apply(client, desired, known, backup, preview, names, atomic_dev=not initial)
    result['activation'] = activation(preview)
    result['preservedDocumentation'] = docs
    result['mode'] = 'initial-production-retrofit-and-dev' if initial else 'dev-only'
    result['packageFilesVerified'] = len(desired)
    (Path(backup) / 'transaction.json').write_bytes(d.canonical(result))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--client-root', type=Path, required=True)
    parser.add_argument('--sources-root', type=Path, required=True)
    parser.add_argument('--artifacts', type=Path, required=True)
    parser.add_argument('--backup', type=Path, required=True)
    parser.add_argument('--lock', type=Path, default=dual.LOCK)
    parser.add_argument('--previous-install', type=Path)
    parser.add_argument('--initial-retrofit', action='store_true', help='One-time explicitly authorized PROD safety migration')
    parser.add_argument('--inspect-only', action='store_true')
    args = parser.parse_args()
    try:
        lock = d.read_lock(args.lock)
        running = m.real_client_preflight(args.client_root, lock, allow_running_dev=not args.initial_retrofit)
        files = payloads(lock, args.sources_root, args.artifacts, args.initial_retrofit)
        known = m.catalog(d.ROOT / 'distribution/migration-known.json')
        previous = json.loads(args.previous_install.read_text()) if args.previous_install else None
        if args.inspect_only:
            _, _, _, preview, docs = prepare(args.client_root, files, known, args.initial_retrofit, previous)
            print(json.dumps({'writeCount': len(preview['writes']), 'preservedDocumentation': docs,
                              'inventory': preview['inventory'], 'clientRunning': running,
                              'activation': activation(preview)}))
        else:
            result = install(args.client_root, files, known, args.backup, args.initial_retrofit, previous)
            print(json.dumps({k: result[k] for k in ('status', 'mode', 'packageFilesVerified', 'preservedDocumentation', 'activation')}))
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, 'Family install stopped: ' + str(error) + '\n')


if __name__ == '__main__':
    main()
