"""Two inspectable family artifacts from one immutable source lock; offline only."""
import argparse
import json
from pathlib import Path
import re
import sys
import zipfile
import io

sys.dont_write_bytecode = True
import distribution as d

LOCK = d.ROOT / 'distribution/candidate.lock.json'
GATE = d.ROOT / 'distribution/FamilyGate.lua'
GATE_PATH = '__Distribution/FamilyGate.lua'
LABELS = {'ApogeeHeals': 'Apogee Heals', 'ApogeeKeybinds': 'Apogee Keybinds',
          'ApogeeGroupAlert': 'Apogee Group Alert', 'ApogeeEssentials': 'Apogee Essentials',
          'ApogeeTank': 'Apogee Tank'}
# Exact identity inventory reviewed with each owning addon task. No Blizzard names or gameplay keys.
IDENTITIES = {
    'ApogeeHeals': ['ApogeeHealsDB', 'ApogeeHealsAnchor', 'ApogeeHealsUnit',
                    'ApogeeHealsBindingEditor', 'ApogeeHealsBuffPicker', 'ApogeeHealsMinimapButton'],
    'ApogeeKeybinds': ['ApogeeKeybindsDB', 'ApogeeKeybindsPhysical', 'ApogeeKeybindsHud',
                      'ApogeeKeybindsSlotMenu', 'ApogeeKeybindsMinimapButton'],
    'ApogeeGroupAlert': ['ApogeeGroupAlertDB', 'ApogeeGroupAlertCharacterDB', 'ApogeeGroupAlertGroups'],
    'ApogeeEssentials': ['ApogeeEssentialsDB'],
    'ApogeeTank': ['ApogeeTankEffectsDB', 'ApogeeTankCooldownsDB', 'ApogeeTankUIDB',
                  'ApogeeTankTargetMarkerButton', 'ApogeeTankThreatHud', 'ApogeeTankAuraAction',
                  'ApogeeTankCooldownAction', 'ApogeeTankSealAction', 'ApogeeTankMinimapButton',
                  'ApogeeTankPickerWindow', 'ApogeeTank']}


def identity_map(name):
    result = {s: name + 'Dev' + s[len(name):] for s in IDENTITIES[name]}
    if name == 'ApogeeKeybinds':
        result['APOGEE_KEYBINDS_RESET_CHARACTER'] = 'APOGEE_KEYBINDS_DEV_RESET_CHARACTER'
    if name == 'ApogeeGroupAlert':
        result.update(SLASH_APOGEEGROUPALERT1='SLASH_APOGEEGROUPALERTDEV1',
                      APOGEEGROUPALERT='APOGEEGROUPALERTDEV')
    return result


def lua_tokens(text):
    """Small lexical scanner: never rewrite comments or arbitrary Lua source substrings."""
    at = 0
    while at < len(text):
        start = at
        comment = text.startswith('--', at)
        if comment:
            at += 2
        long = re.match(r'\[(=*)\[', text[at:])
        if long:
            end = text.find(']' + long[1] + ']', at + len(long[0]))
            d.require(end >= 0, 'Unclosed Lua long string/comment')
            at = end + len(long[1]) + 2
            yield ('comment' if comment else 'longstring'), text[start:at]
        elif comment:
            end = text.find('\n', at)
            at = len(text) if end < 0 else end
            yield 'comment', text[start:at]
        elif text[at] in ('"', "'"):
            quote = text[at]; at += 1
            while at < len(text) and text[at] != quote:
                at += 2 if text[at] == '\\' else 1
            d.require(at < len(text), 'Unclosed Lua string')
            at += 1
            yield 'string', text[start:at]
        else:
            identifier = re.match(r'[A-Za-z_][A-Za-z0-9_]*', text[at:])
            if identifier:
                at += len(identifier[0]); yield 'identifier', text[start:at]
            else:
                at += 1; yield 'other', text[start:at]


def transform_lua(data, name):
    mapping, audit, result = identity_map(name), [], []
    for kind, token in lua_tokens(data.decode('utf-8-sig')):
        new = token
        if kind == 'identifier':
            new = mapping.get(token, token)
            d.require(not token.startswith(name) or token in mapping, 'Unaudited identity token: ' + token)
        elif kind in ('string', 'longstring'):
            # Exact standalone identity strings, owned asset folder segments, and reviewed display labels.
            if kind == 'string' and token[1:-1] in mapping:
                new = token[0] + mapping[token[1:-1]] + token[-1]
            else:
                new = token.replace(name + '/', name + 'Dev/').replace(name + '\\', name + 'Dev\\')
                new = new.replace(LABELS[name], LABELS[name] + ' DEV')
                if name == 'ApogeeGroupAlert' and token[1:-1] == '/aga':
                    new = token[0] + '/agadev' + token[-1]
            # An owned technical name not accounted for above requires a new explicit audit.
            d.require(name not in new.replace(name + 'Dev', ''), 'Unaudited identity string: ' + token)
        if new != token:
            audit.append({'kind': kind, 'from': token, 'to': new})
        result.append(new)
    return ''.join(result).encode(), audit


def prefix(name, family):
    return (('-- Distribution schema 1: admission is checked before this source chunk.\n'
             'do local n, a = ...; if n ~= "%s" or type(a) ~= "table"\n'
             ' or type(a.__ApogeeFamilyAdmission) ~= "function"\n'
             ' or a.__ApogeeFamilyAdmission(n) ~= true then return end end\n') % name).encode()


def family_files(lock, sources_root, family):
    d.require(family in ('PROD', 'DEV'), 'Unknown family')
    source = d.collect(lock, sources_root, 'local-candidate')
    output, changes = {}, {}
    marker = d.MARKER + ('Dev' if family == 'DEV' else '')
    for child in lock['children']:
        old = child['name']; name = old + ('Dev' if family == 'DEV' else '')
        meta, runtime = d.toc_info(source[old + '/' + child['toc']])
        d.require(all(p.endswith('.lua') for p in runtime), 'Only audited direct Lua TOCs supported')
        meta.update({'Title': LABELS[old] + (' DEV' if family == 'DEV' else ''),
                     'Group': marker, 'Category': 'Apogee ' + family,
                     'X-Apogee-Family': family, 'X-Apogee-Family-Schema': '1'})
        if family == 'DEV':
            meta = {k: v for k, v in meta.items() if not k.startswith(('X-Curse', 'X-Wago', 'X-WoWI'))}
            meta = {k: v.replace(old, name) if k.startswith('SavedVariables') or k == 'IconTexture' else v
                    for k, v in meta.items()}
        renamed = {p: name + '.lua' if p == old + '.lua' else p for p in runtime}
        toc = ''.join('## ' + k + ': ' + v + '\n' for k, v in meta.items()) + '\n'
        toc += GATE_PATH + '\n' + ''.join(renamed[p] + '\n' for p in runtime)
        output[name + '/' + name + '.toc'] = toc.encode()
        output[name + '/' + GATE_PATH] = GATE.read_bytes().replace(b'@NAME@', name.encode()).replace(b'@FAMILY@', family.encode())
        for p in child['files']:
            if p == child['toc']:
                continue
            data = source[old + '/' + p]
            target = name + '/' + renamed.get(p, p)
            if p in runtime:
                body, audit = transform_lua(data, old) if family == 'DEV' else (data, [])
                output[target] = prefix(name, family) + body
                changes[target] = {'source': old + '/' + p, 'sourceSha256': d.sha(data),
                                   'gameplayBodySha256': d.sha(body), 'identityEdits': audit}
            else:
                output[target] = data
    marker_meta, _ = d.toc_info(source[d.MARKER + '/' + d.MARKER + '.toc'])
    marker_meta.update(Title='Apogee ' + family + ' (distribution only)', Group=marker, Category='Apogee ' + family)
    marker_meta.update({'X-Apogee-Family': family, 'X-Apogee-Family-Schema': '1'})
    if family == 'DEV':
        marker_meta.pop('X-Curse-Project-ID', None)
    output[marker + '/' + marker + '.toc'] = ''.join('## ' + k + ': ' + v + '\n' for k, v in marker_meta.items()).encode()
    output[marker + '/README.md'] = ('# Apogee ' + family + '\n\nDistribution identity only; no runtime or saved data.\n'
                                      'Switch the complete family in AddOns and reload. DEV settings are separate.\n').encode()
    return output, changes


def validate(data, expected):
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        d.require(len(archive.infolist()) == len(expected), 'Wrong family file count')
        files = {}
        for entry in archive.infolist():
            d.safe_path(entry.filename)
            d.require(entry.filename in expected and entry.filename not in files
                      and entry.file_size <= 4 * 1024 * 1024
                      and entry.external_attr >> 16 == 0o100644, 'Invalid family ZIP entry')
            files[entry.filename] = archive.read(entry)
        d.require(files == expected, 'Family payload differs from independently generated pinned sources')
    return files


def build(lock, sources_root, output):
    artifacts = {}
    for family in ('PROD', 'DEV'):
        files, changes = family_files(lock, sources_root, family)
        data = d.zip_bytes(files)
        validate(data, files)
        name = 'Apogee-' + lock['version'] + '-' + family + '.zip'
        manifest = {'schema': 1, 'family': family, 'publicationAllowed': False,
                    'lockSha256': d.sha(d.canonical(lock)), 'gateSha256': d.sha(GATE.read_bytes()),
                    'archive': name, 'archiveSha256': d.sha(data),
                    'files': {p: d.sha(b) for p, b in files.items()}, 'runtimeChanges': changes,
                    'children': [{k: c[k] for k in ('name', 'commit', 'version')} for c in lock['children']],
                    'nativeClientTested': False, 'curseforgeAppTested': False}
        artifacts[family] = (name, data, manifest)
    output = Path(output); output.mkdir(parents=True, exist_ok=False)
    for family, (name, data, manifest) in artifacts.items():
        (output / name).write_bytes(data)
        (output / (family + '-manifest.json')).write_bytes(d.canonical(manifest))
        (output / (name + '.sha256')).write_text(d.sha(data) + '  ' + name + '\n')
    return {f: d.sha(data) for f, (_, data, _) in artifacts.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lock', type=Path, default=LOCK)
    parser.add_argument('--sources-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(build(d.read_lock(args.lock), args.sources_root, args.output)))
    except (ValueError, KeyError, OSError) as error:
        parser.exit(1, 'Dual build stopped: ' + str(error) + '\n')


if __name__ == '__main__':
    main()
