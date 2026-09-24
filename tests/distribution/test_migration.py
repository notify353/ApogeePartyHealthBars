"""Disposable migration fixtures, not native-client or CurseForge updater tests."""
import argparse
import copy
import importlib.util
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import distribution as d
import migrate_distribution as m


class MigrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lock = d.read_lock(ROOT / 'distribution/candidate.lock.json')
        cls.known = m.catalog(ROOT / 'distribution/migration-known.json')
        cls.payload = d.collect(cls.lock, OPTIONS.sources_root, 'local-candidate')
        OPTIONS.artifacts.mkdir(parents=True, exist_ok=False)
        OPTIONS.owns_artifacts = True
        cls.counter = 0

    def fixture(self, files=None):
        type(self).counter += 1
        base = OPTIONS.artifacts / str(self.counter)
        client = base / '_classic_beta_'
        (client / 'Interface/AddOns').mkdir(parents=True)
        m.put(client / 'Interface/AddOns', files or {})
        m.put(client, {'WTF/Account/Fixture/SavedVariables/ApogeePartyHealthBars.lua': b'-- saved state',
                       'WTF/Account/Fixture/Realm/Character/SavedVariables/ApogeeKeybinds.lua': b'-- character state',
                       'WTF/Account/Fixture/Realm/Character/AddOns.txt': b'ApogeeHeals: disabled\nApogeePartyHealthBars: disabled\n',
                       'WTF/Account/Fixture/bindings-cache.wtf': b'-- bindings',
                       'Interface/AddOns/Unrelated/user.txt': b'-- unrelated'})
        return client, base / 'backup'

    def assert_inert(self, client):
        files = m.managed(client / 'Interface/AddOns')
        for p, b in files.items():
            if p.startswith(d.MARKER + '/') and p.lower().endswith('.toc'):
                meta, runtime = d.toc_info(b)
                self.assertEqual(runtime, [])
                self.assertEqual(meta['X-Apogee-Distribution-Only'], '1')
                self.assertEqual(meta['X-Apogee-Distribution-Schema'], '1')
                self.assertFalse(any(k.startswith('SavedVariables') for k in meta))
        for p, b in self.payload.items():
            self.assertEqual(files[p], b)

    def test_actual_old_releases_and_main_all_loader_variants_rollback(self):
        for revision in self.known['legacyRevisions']:
            original = d.source_tree(ROOT, revision)
            baseline = {d.MARKER + '/' + p: b for p, b in original.items()}
            toc = original[d.MARKER + '.toc']
            for suffix in ('_Camelot.toc', '_Vanilla.toc', '_TBC.toc', '_Mainline.toc'):
                baseline[d.MARKER + '/' + d.MARKER + suffix] = toc
            baseline[d.MARKER + '/nested/UnknownName.toc'] = toc
            baseline[d.MARKER + '/unknown-user.lua'] = b'-- user file preserved, unreferenced'
            client, backup = self.fixture(baseline)
            protected = m.protected(client)
            result = m.apply(client, self.payload, self.known, backup)
            self.assertEqual(result['status'], 'installed')
            self.assert_inert(client)
            self.assertEqual(m.protected(client), protected)
            for p, b in baseline.items():
                if not p.lower().endswith('.toc') and p not in self.payload:
                    self.assertEqual((client / 'Interface/AddOns' / p).read_bytes(), b)
            self.assertEqual(m.rollback(backup)['status'], 'rolled-back')
            self.assertEqual(m.managed(client / 'Interface/AddOns'), baseline)
            self.assertEqual(m.protected(client), protected)
            self.assertTrue((backup / 'rollback-added-files').is_dir())

    def test_clean_install_preserves_disabled_preferences_and_rollback(self):
        client, backup = self.fixture()
        protected = m.protected(client)
        m.apply(client, self.payload, self.known, backup)
        self.assert_inert(client)
        self.assertEqual(m.protected(client), protected)
        m.rollback(backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns'), {})

    def test_old_prototype_marker_is_upgraded(self):
        old = d.marker_files(d.read_lock())
        client, backup = self.fixture(old)
        m.apply(client, self.payload, self.known, backup)
        self.assert_inert(client)
        m.rollback(backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns'), old)

    def test_missing_children_and_update_are_independent_and_idempotent(self):
        for absent in d.CHILDREN:
            baseline = {p: b for p, b in self.payload.items() if not p.startswith(absent + '/')}
            client, backup = self.fixture(baseline)
            m.apply(client, self.payload, self.known, backup)
            self.assert_inert(client)
            self.assertEqual(m.plan(client, self.payload, self.known)['writes'], {})
            m.rollback(backup)
            self.assertEqual(m.managed(client / 'Interface/AddOns'), baseline)

    def test_modified_canonical_or_alternate_loader_refused_before_backup(self):
        for path in (d.MARKER + '/' + d.MARKER + '.toc', d.MARKER + '/' + d.MARKER + '_Camelot.toc'):
            client, backup = self.fixture({path: b'## Interface: 16001\nUser.lua\n'})
            before = m.tree(client)
            with self.assertRaises(ValueError): m.apply(client, self.payload, self.known, backup)
            self.assertEqual(m.tree(client), before)
            self.assertFalse(backup.exists())

    def test_modified_child_conflict_refused(self):
        client, backup = self.fixture({'ApogeeHeals/Core/Access.lua': b'-- edited'})
        before = m.tree(client)
        with self.assertRaises(ValueError): m.apply(client, self.payload, self.known, backup)
        self.assertEqual(m.tree(client), before)
        self.assertFalse(backup.exists())

    def test_unexpected_child_loader_refused_but_unknown_nonloader_preserved(self):
        client, backup = self.fixture({'ApogeeHeals/ApogeeHeals_Camelot.toc': b'User.lua\n'})
        with self.assertRaises(ValueError): m.apply(client, self.payload, self.known, backup)
        client, backup = self.fixture({'ApogeeHeals/unknown.txt': b'user data'})
        m.apply(client, self.payload, self.known, backup)
        self.assertEqual((client / 'Interface/AddOns/ApogeeHeals/unknown.txt').read_bytes(), b'user data')

    def test_reviewed_snapshot_race_stops_before_backup(self):
        client, backup = self.fixture()
        preview = m.plan(client, self.payload, self.known)
        m.put(client / 'Interface/AddOns', {'ApogeeHeals/new-user-file': b'added after inspection'})
        with self.assertRaises(ValueError): m.apply(client, self.payload, self.known, backup, preview)
        self.assertFalse(backup.exists())

    def test_backup_failure_never_writes_destination(self):
        client, backup = self.fixture()
        before = m.tree(client)
        with patch.object(m, 'put', side_effect=OSError('fixture backup failure')):
            with self.assertRaises(OSError): m.apply(client, self.payload, self.known, backup)
        self.assertEqual(m.tree(client), before)

    def test_interrupted_install_recovers_from_verified_backup(self):
        client, backup = self.fixture()
        original_put = m.put
        def fail_partway(root, files):
            if Path(root) == client / 'Interface/AddOns':
                first = next(iter(files)); original_put(root, {first: files[first]})
                raise OSError('fixture mid-install failure')
            original_put(root, files)
        with patch.object(m, 'put', side_effect=fail_partway):
            with self.assertRaises(OSError): m.apply(client, self.payload, self.known, backup)
        self.assertEqual(m.rollback(backup)['status'], 'rolled-back')
        self.assertEqual(m.managed(client / 'Interface/AddOns'), {})

    def test_rollback_refuses_new_user_edits_without_overwriting(self):
        client, backup = self.fixture()
        m.apply(client, self.payload, self.known, backup)
        m.put(client / 'Interface/AddOns', {'ApogeeHeals/Core/Access.lua': b'-- user edit after install'})
        before = m.tree(client)
        with self.assertRaises(ValueError): m.rollback(backup)
        self.assertEqual(m.tree(client), before)

    def test_tampered_backup_refused(self):
        old = d.marker_files(d.read_lock())
        client, backup = self.fixture(old)
        m.apply(client, self.payload, self.known, backup)
        m.put(backup / 'addons-before', {d.MARKER + '/README.md': b'tampered'})
        before = m.tree(client)
        with self.assertRaises(ValueError): m.rollback(backup)
        self.assertEqual(m.tree(client), before)

    def test_paths_and_inside_client_backup_refused(self):
        client, backup = self.fixture()
        for p in ('../outside', '/absolute', 'a/../b'):
            with self.assertRaises(ValueError): m.under(client, p)
        with self.assertRaises(ValueError): m.apply(client, self.payload, self.known, client / 'backup')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--sources-root', type=Path, required=True)
    parser.add_argument('--artifacts', type=Path, required=True)
    OPTIONS = parser.parse_args()
    OPTIONS.owns_artifacts = False
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(MigrationTests))
    if OPTIONS.owns_artifacts:
        (OPTIONS.artifacts / 'summary.json').write_bytes(d.canonical({
            'tests': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors),
            'nativeClientTested': False, 'curseforgeAppTested': False, 'realInstallationModified': False}))
    sys.exit(not result.wasSuccessful())
