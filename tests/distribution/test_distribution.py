"""Filesystem fixtures only. Never installs addons or models CurseForge internals."""
import argparse
import copy
import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import unittest
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('aggregate', ROOT / 'scripts/distribution.py')
d = importlib.util.module_from_spec(spec)
spec.loader.exec_module(d)


def snapshot(root):
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in root.rglob('*') if p.is_file()}


def write_tree(root, files):
    root.mkdir(parents=True, exist_ok=False)
    for path, data in files.items():
        d.safe_path(path)
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)


def overlay_fixture(root, incoming, baseline):
    """Deliberately conservative fixture: detect unexpected overwrites before writes.

    It neither removes obsolete files nor claims to implement an actual updater.
    """
    current = snapshot(root)
    for path in incoming:
        if path in current and current[path] != incoming[path]:
            d.require(path in baseline and current[path] == baseline[path], 'Unexpected local edit')
    for path, data in incoming.items():
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)


class DistributionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lock = d.read_lock()
        cls.files = d.collect(cls.lock, OPTIONS.sources_root, 'children-only')
        cls.marker = d.collect(cls.lock, OPTIONS.sources_root, 'marker-fixture')
        cls.zip = d.zip_bytes(cls.files)
        cls.counter = 0
        OPTIONS.artifacts.mkdir(parents=True, exist_ok=False)
        OPTIONS.owns_artifacts = True
        write_tree(OPTIONS.artifacts / 'children', cls.files)

    def fixture(self, label):
        type(self).counter += 1
        return OPTIONS.artifacts / (str(self.counter) + '-' + label)

    def legacy(self, revision):
        tree = d.source_tree(ROOT, revision)
        files = {'AddOns/' + d.MARKER + '/' + p: data for p, data in tree.items()}
        files.update({
            'WTF/Account/Fixture/SavedVariables/ApogeePartyHealthBars.lua': b'-- synthetic legacy state\n',
            'WTF/Account/Fixture/SavedVariables/ApogeeEssentials.lua': b'-- synthetic child state\n',
            'WTF/Account/Fixture/Realm/Character/SavedVariables/ApogeeHeals.lua': b'-- synthetic bindings\n',
            'WTF/Account/Fixture/Realm/Character/AddOns.txt': b'ApogeeHeals: disabled\n',
            'WTF/Account/Fixture/bindings-cache.wtf': b'-- synthetic native binding backup\n',
            'AddOns/UnrelatedAddon/user.txt': b'preserve unrelated user files\n',
            'AddOns/ApogeePartyHealthBars/user-note.txt': b'preserve unknown local file\n',
        })
        return files

    def test_exact_canonical_folders_and_child_bytes(self):
        self.assertEqual(set(p.split('/')[0] for p in self.files), set(d.CHILDREN))
        self.assertEqual(len(d.validate(self.zip, self.lock, 'children-only')), 134)
        self.assertFalse(any('.git' in p.split('/') for p in self.files))

    def test_repeated_build_is_byte_identical(self):
        again = d.collect(self.lock, OPTIONS.sources_root, 'children-only')
        self.assertEqual(self.zip, d.zip_bytes(dict(reversed(list(again.items())))))
        one = d.build(self.lock, OPTIONS.sources_root, self.fixture('build-a'), 'children-only')
        two = d.build(self.lock, OPTIONS.sources_root, self.fixture('build-b'), 'children-only')
        self.assertEqual(one.read_bytes(), two.read_bytes())
        self.assertEqual((one.parent / 'manifest.json').read_bytes(), (two.parent / 'manifest.json').read_bytes())
        with self.assertRaises(FileExistsError):
            d.build(self.lock, OPTIONS.sources_root, one.parent, 'children-only')

    def test_corrupted_and_extra_missing_paths_rejected(self):
        damaged = dict(self.files)
        damaged[next(iter(damaged))] += b'-- tamper'
        with self.assertRaises(ValueError): d.validate(d.zip_bytes(damaged), self.lock, 'children-only')
        extra = dict(self.files, **{'AnotherCopy/ApogeeHeals.lua': b'duplicate'})
        with self.assertRaises(ValueError): d.validate(d.zip_bytes(extra), self.lock, 'children-only')
        missing = dict(self.files); missing.pop(next(iter(missing)))
        with self.assertRaises(ValueError): d.validate(d.zip_bytes(missing), self.lock, 'children-only')

    def test_unsafe_archive_paths_and_duplicate_entries_rejected(self):
        for name in ('../escape', '/absolute', 'C:/absolute', 'a\\b', 'a/../b', 'a//b'):
            with self.assertRaises(ValueError): d.safe_path(name)
        out = io.BytesIO()
        with zipfile.ZipFile(out, 'w') as z:
            z.writestr('../escape', b'x')
        with self.assertRaises(ValueError): d.validate(out.getvalue(), self.lock, 'children-only')
        # Duplicate entries with a compensating omission cannot satisfy the exact inventory.
        names = list(self.files)
        out = io.BytesIO()
        with zipfile.ZipFile(out, 'w') as z:
            for p in names[1:]:
                info = zipfile.ZipInfo(p); info.external_attr = 0o100644 << 16
                z.writestr(info, self.files[p])
            info = zipfile.ZipInfo(names[1]); info.external_attr = 0o100644 << 16
            z.writestr(info, self.files[names[1]])
        with self.assertRaises(ValueError): d.validate(out.getvalue(), self.lock, 'children-only')

    def test_wrong_source_hash_and_commit_fail_closed(self):
        changed = copy.deepcopy(self.lock)
        changed['children'][0]['files']['LICENSE'] = '0' * 64
        with self.assertRaises(ValueError): d.collect(changed, OPTIONS.sources_root, 'children-only')
        changed['children'][0]['commit'] = '0' * 40
        with self.assertRaises(ValueError): d.collect(changed, OPTIONS.sources_root, 'children-only')

    def test_marker_is_metadata_only_and_contains_no_old_runtime(self):
        meta, runtime = d.toc_info(self.marker[d.MARKER + '/' + d.MARKER + '.toc'])
        self.assertEqual(runtime, [])
        self.assertEqual(meta['X-Apogee-Distribution-Only'], '1')
        self.assertFalse(any(k.startswith('SavedVariables') for k in meta))
        self.assertEqual(len(d.validate(d.zip_bytes(self.marker), self.lock, 'marker-fixture')), 136)
        self.assertFalse(any(p.startswith(d.MARKER + '/') and p.endswith(('.lua', '.xml')) for p in self.marker))

    def test_children_are_structurally_independent_if_missing_or_disabled(self):
        # This proves no TOC dependency/embedded cross-load; native combat coexistence is separate.
        for absent in d.CHILDREN:
            remaining = {p: body for p, body in self.files.items() if not p.startswith(absent + '/')}
            for child in self.lock['children']:
                if child['name'] == absent: continue
                prefix = child['name'] + '/'
                files = {p[len(prefix):]: body for p, body in remaining.items() if p.startswith(prefix)}
                d.child_contract(child, files)
        for child in self.lock['children']:
            prefix = child['name'] + '/'
            runtime = d.child_contract(child, {p[len(prefix):]: b for p, b in self.files.items() if p.startswith(prefix)})
            self.assertEqual(len(runtime), len(set(runtime)))

    def test_child_savedvariables_and_load_graph_changes_rejected(self):
        child = self.lock['children'][0]; prefix = child['name'] + '/'
        files = {p[len(prefix):]: b for p, b in self.files.items() if p.startswith(prefix)}
        original = files[child['toc']]
        for suffix in (b'\n## Dependencies: ApogeePartyHealthBars\n',
                       b'\nCore/Access.lua\n', b'\nMissing.lua\n'):
            files[child['toc']] = original + suffix
            with self.assertRaises(ValueError): d.child_contract(child, files)
        files[child['toc']] = original.replace(b'ApogeeHealsDB', b'RenamedDB')
        with self.assertRaises(ValueError): d.child_contract(child, files)

    def test_keybinds_actual_conflict_and_claim_functions(self):
        lua = OPTIONS.artifacts / 'keybinds-guard-fixture.lua'
        lua.write_text('''local root = arg[1]
local K = {active=true, Inputs={all={{id="one", key="1"}}}, Message=function() end}
local loaded=false
C_AddOns={IsAddOnLoaded=function(name) assert(name=="ApogeePartyHealthBars"); return loaded end}
InCombatLockdown=function() return false end
assert(loadfile(root.."/Core/Client.lua"))("ApogeeKeybinds", K)
assert(loadfile(root.."/Actions/Secure.lua"))("ApogeeKeybinds", K)
K.Secure.owner={}
K.Secure.buttons.one={GetName=function() return "FixtureButton" end}
local claims=0
ClearOverrideBindings=function() end
SetOverrideBindingClick=function() claims=claims+1 end
for _,scenario in ipairs({"absent", "disabled", "legacy-loaded", "marker-loaded"}) do
    loaded=scenario=="legacy-loaded" or scenario=="marker-loaded"
    local before=claims
    assert(K.API.Conflict()==loaded)
    assert(K.Secure.Claim()==not loaded)
    assert(claims==before+(loaded and 0 or 1))
end
print("Actual Keybinds conflict/claim: absent and disabled pass; legacy and marker loaded block")
''', encoding='utf-8')
        result = subprocess.run(['lua', str(lua), str(OPTIONS.artifacts / 'children/ApogeeKeybinds')],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        (OPTIONS.artifacts / 'keybinds-guard-result.txt').write_text(result.stdout, encoding='utf-8')

    def test_legacy_overlay_preserves_state_and_demonstrates_obsolete_files(self):
        for revision in self.lock['legacyFixtures'].values():
            baseline = self.legacy(revision)
            for variant, package in (('children', self.files), ('marker', self.marker)):
                root = self.fixture(variant + '-upgrade')
                write_tree(root, baseline)
                # Persist a separate backup before the fixture overlay.
                backup = self.fixture('backup'); write_tree(backup, snapshot(root))
                overlay_fixture(root, {'AddOns/' + p: b for p, b in package.items()}, baseline)
                after = snapshot(root)
                for p, body in baseline.items():
                    if p.startswith('WTF/') or p.endswith('user-note.txt') or p.startswith('AddOns/Unrelated'):
                        self.assertEqual(after[p], body)
                old_lua = 'AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.lua'
                self.assertEqual(after[old_lua], baseline[old_lua])
                _, runtime = d.toc_info(after['AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.toc'])
                self.assertEqual(bool(runtime), variant == 'children')
                # Non-destructive rollback demonstration: reconstruct the prior snapshot in a NEW root.
                restored = self.fixture('restored'); write_tree(restored, snapshot(backup))
                self.assertEqual(snapshot(restored), baseline)

    def test_unknown_user_edit_collision_stops_before_any_write(self):
        baseline = {'AddOns/' + p: b for p, b in self.files.items()}
        root = self.fixture('user-edit'); write_tree(root, baseline)
        changed = root / 'AddOns/ApogeeHeals/Core/Access.lua'
        changed.write_bytes(b'-- unexpected user modification\n')
        before = snapshot(root)
        with self.assertRaises(ValueError): overlay_fixture(root, baseline, baseline)
        self.assertEqual(snapshot(root), before)

    def test_alternate_legacy_toc_is_not_silently_removed(self):
        root = self.fixture('alternate-toc')
        baseline = {'AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars_Camelot.toc': b'Old.lua\n',
                    'AddOns/ApogeePartyHealthBars/Old.lua': b'-- obsolete\n'}
        write_tree(root, baseline)
        overlay_fixture(root, {'AddOns/' + p: b for p, b in self.marker.items()}, baseline)
        candidates = list((root / 'AddOns/ApogeePartyHealthBars').glob('*.toc'))
        self.assertEqual(len(candidates), 2)
        self.assertTrue(any(d.toc_info(p.read_bytes())[1] for p in candidates))

    def test_version_metadata_has_no_retail_or_nearest_fallback(self):
        valid = {'name': '1.60.1', 'gameVersionTypeID': 88568, 'id': 999001}
        self.assertEqual(d.preflight(self.lock, [valid])['gameVersions'], [999001])
        for rows in ([], [dict(valid, gameVersionTypeID=517)], [dict(valid, name='1.60.0')],
                     [valid, valid], [dict(valid, id=88568)], [dict(valid, id=True)]):
            with self.assertRaises(ValueError): d.preflight(self.lock, rows)
        self.assertFalse(d.preflight(self.lock, [valid])['publicationAllowed'])

    def test_wrong_packager_rejected(self):
        with self.assertRaises(ValueError): d.review_packager(self.lock, b'old retail-only packager')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--sources-root', type=Path, required=True)
    parser.add_argument('--artifacts', type=Path, required=True)
    OPTIONS = parser.parse_args()
    OPTIONS.owns_artifacts = False
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(DistributionTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if OPTIONS.owns_artifacts:
        (OPTIONS.artifacts / 'summary.json').write_bytes(d.canonical({
            'tests': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors),
            'nativeClientTested': False, 'curseforgeAppTested': False, 'realInstallationModified': False}))
    sys.exit(not result.wasSuccessful())
