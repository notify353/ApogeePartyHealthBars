import argparse
import copy
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import distribution as d
import dual_distribution as dual
import migrate_distribution as m
import install_dual_distribution as installer
import publish_distribution as publisher


class DualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lock = d.read_lock(dual.LOCK)
        cls.known = m.catalog(ROOT / 'distribution/migration-known.json')
        cls.prod, cls.prod_changes = dual.family_files(cls.lock, OPTIONS.sources_root, 'PROD')
        cls.dev, cls.dev_changes = dual.family_files(cls.lock, OPTIONS.sources_root, 'DEV')
        OPTIONS.artifacts.mkdir(parents=True, exist_ok=False); OPTIONS.owns_artifacts = True
        m.put(OPTIONS.artifacts / 'PROD', cls.prod); m.put(OPTIONS.artifacts / 'DEV', cls.dev)
        cls.counter = 0

    def fixture(self, files):
        type(self).counter += 1
        base = OPTIONS.artifacts / ('fixture-' + str(self.counter))
        client = base / '_classic_beta_'; (client / 'Interface/AddOns').mkdir(parents=True)
        m.put(client / 'Interface/AddOns', files)
        m.put(client, {'WTF/Account/Private/SavedVariables/ApogeeEssentials.lua': b'private prod settings',
                       'WTF/Account/Private/AddOns.txt': b'unchanged enablement',
                       'Interface/AddOns/Unrelated/keep.txt': b'unchanged unrelated'})
        return client, base / 'backup'

    def test_production_gameplay_bodies_are_identical_to_pins(self):
        source = d.collect(self.lock, OPTIONS.sources_root, 'local-candidate')
        for path, change in self.prod_changes.items():
            prefix = dual.prefix(path.split('/')[0], 'PROD')
            self.assertEqual(self.prod[path], prefix + source[change['source']])
            self.assertEqual(change['identityEdits'], [])

    def test_exact_roots_tocs_guards_separate_saves_and_no_dev_project_ids(self):
        saves = {}
        for family, files in (('PROD', self.prod), ('DEV', self.dev)):
            names = tuple(n + ('Dev' if family == 'DEV' else '') for n in m.NAMES)
            self.assertEqual(set(p.split('/')[0] for p in files), set(names))
            saves[family] = set()
            for name in names:
                meta, runtime = d.toc_info(files[name + '/' + name + '.toc'])
                self.assertEqual(meta['Group'], names[0])
                self.assertEqual(meta['Category'], 'Apogee Forever' if family == 'PROD' else 'Apogee Dev')
                if name.startswith(d.MARKER):
                    self.assertEqual(meta['Title'], 'Apogee Forever' if family == 'PROD' else 'Apogee Dev')
                    self.assertEqual(runtime, []); continue
                self.assertEqual(runtime[0], dual.GATE_PATH)
                self.assertEqual(len(runtime), len(set(runtime)))
                for p in runtime[1:]:
                    self.assertTrue(files[name + '/' + p].startswith(dual.prefix(name, family)))
                for key, value in meta.items():
                    if key.startswith('SavedVariables'): saves[family].update(value.replace(',', ' ').split())
                if family == 'DEV': self.assertFalse(any(k.startswith('X-Curse') for k in meta))
        self.assertTrue(saves['PROD']); self.assertTrue(saves['DEV'])
        self.assertFalse(saves['PROD'] & saves['DEV'])

    def test_release_requires_native_accepted_runtime(self):
        accepted = json.loads(publisher.ACCEPTANCE.read_text())
        actual = {family: {p: d.sha(b) for p, b in files.items() if p.endswith('.lua')}
                  for family, files in (('PROD', self.prod), ('DEV', self.dev))}
        if actual == accepted['runtimeFiles']:
            self.assertTrue(publisher.payload(OPTIONS.sources_root, '1.0.0').startswith(b'PK'))
        else:
            with self.assertRaisesRegex(ValueError, 'Runtime changed since native acceptance'):
                publisher.payload(OPTIONS.sources_root, '1.0.0')

    def test_running_client_allowed_only_for_dev_preflight(self):
        client, _ = self.fixture(self.dev)
        (client.parent / '.build.info').write_text('Product|Version\nwow_classic_beta|' + self.lock['client']['reviewedBuild'])
        process = subprocess.CompletedProcess([], 0, stdout='"WowB.exe","123"', stderr='')
        with patch.object(m.os, 'name', 'nt'), patch.object(m.subprocess, 'run', return_value=process):
            self.assertTrue(m.real_client_preflight(client, self.lock, allow_running_dev=True))
            with self.assertRaisesRegex(ValueError, 'close it before migration'):
                m.real_client_preflight(client, self.lock)
            bad = copy.deepcopy(self.lock); bad['client']['reviewedBuild'] = 'wrong'
            with self.assertRaisesRegex(ValueError, 'build changed'):
                m.real_client_preflight(client, bad, allow_running_dev=True)

    def test_atomic_dev_failure_retains_original_and_verified_backup(self):
        client, backup = self.fixture(self.dev)
        updated = dict(self.dev)
        path = 'ApogeeHealsDev/' + dual.GATE_PATH
        updated[path] += b'\n-- next version\n'
        previous = {'schema': 1, 'status': 'installed', 'client': str(client), 'after': m.hashes(self.dev)}
        with patch.object(m.os, 'replace', side_effect=OSError('fixture sharing violation')):
            with self.assertRaisesRegex(OSError, 'sharing violation'):
                installer.install(client, updated, self.known, backup, previous=previous)
        self.assertEqual((client / 'Interface/AddOns' / path).read_bytes(), self.dev[path])
        self.assertEqual(m.tree(backup / 'addons-before'), self.dev)
        self.assertEqual(json.loads((backup / 'transaction.json').read_bytes())['status'], 'incomplete-recover-with-rollback')
        with self.assertRaisesRegex(ValueError, 'DEV-only'):
            m.apply(client, self.prod, self.known, backup.parent / 'forbidden', atomic_dev=True)

    def test_activation_distinguishes_existing_runtime_and_discovery(self):
        self.assertFalse(installer.activation({'before': {'a.lua': b'old'}, 'writes': {'a.lua': b'new'}})['restartRequired'])
        result = installer.activation({'before': {}, 'writes': {'a.lua': b'new', 'a.toc': b'metadata'}})
        self.assertEqual(result['discoveryChanges'], ['a.lua', 'a.toc'])
        self.assertEqual(result['action'], 'user-reload-after-install')

    def test_dev_install_still_refuses_concurrent_protected_changes(self):
        client, backup = self.fixture(self.dev)
        with patch.object(m, 'protected', side_effect=[{}, {'WTF/fixture': [1, 2]}]):
            with self.assertRaisesRegex(ValueError, 'Preferences changed during backup'):
                installer.install(client, self.dev, self.known, backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns', tuple(n + 'Dev' for n in m.NAMES)), self.dev)

    def test_public_package_has_player_guide_and_required_notices(self):
        source = d.collect(self.lock, OPTIONS.sources_root, 'local-candidate')
        for child in self.lock['children']:
            for p in child['files']:
                path = child['name'] + '/' + p
                if p in ('LICENSE', 'NOTICE.md', 'THIRD_PARTY_NOTICES.md'):
                    self.assertEqual(self.prod[path], source[path])
                elif p.endswith('.md') or p.startswith('docs/'):
                    self.assertNotIn(path, self.prod)
        guide = self.prod[d.MARKER + '/README.md'].decode()
        self.assertIn('Forever 1.60.1', guide)
        self.assertNotIn('PROD', guide)

    def test_every_actual_runtime_chunk_is_denied_without_gameplay_effects(self):
        result = subprocess.run(['lua', str(ROOT / 'tests/distribution/family_matrix.lua'), str(OPTIONS.artifacts)],
                                capture_output=True, text=True)
        (OPTIONS.artifacts / 'family-matrix.log').write_text(result.stdout + result.stderr)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_reproducibility_and_corruption(self):
        first = dual.build(self.lock, OPTIONS.sources_root, OPTIONS.artifacts / 'build-a')
        second = dual.build(self.lock, OPTIONS.sources_root, OPTIONS.artifacts / 'build-b')
        self.assertEqual(first, second)
        for family, files in (('PROD', self.prod), ('DEV', self.dev)):
            self.assertEqual(dual.validate(d.zip_bytes(files), files), files)
            altered = dict(files); p = next(iter(altered)); altered[p] += b'altered'
            with self.assertRaises(ValueError): dual.validate(d.zip_bytes(altered), files)

    def test_one_time_retrofit_and_dev_coexistence_preserve_saves_and_unknown_docs(self):
        baseline = d.collect(d.read_lock(), OPTIONS.sources_root, 'children-only')
        baseline['ApogeeKeybinds/README.md'] = b'user edited documentation'
        baseline['ApogeeTank/unknown.lua'] = b'user source unreferenced'
        client, backup = self.fixture(baseline)
        protected = m.protected(client, m.NAMES + tuple(n + 'Dev' for n in m.NAMES))
        result = installer.install(client, dict(self.prod, **self.dev), self.known, backup, True)
        self.assertEqual((client / 'Interface/AddOns/ApogeeKeybinds/README.md').read_bytes(), baseline['ApogeeKeybinds/README.md'])
        self.assertEqual(m.protected(client, tuple(result['names'])), protected)
        for p, b in dict(self.prod, **self.dev).items():
            if p not in result['preservedDocumentation']:
                self.assertEqual((client / 'Interface/AddOns' / p).read_bytes(), b)
        m.rollback(backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns', tuple(result['names'])), baseline)

    def test_dev_update_never_touches_production_and_rolls_back(self):
        baseline = dict(self.prod, **self.dev)
        client, backup = self.fixture(baseline)
        original = m.managed(client / 'Interface/AddOns')
        result = installer.install(client, self.dev, self.known, backup)
        self.assertEqual(result['writes'], {})
        self.assertEqual(m.managed(client / 'Interface/AddOns'), original)
        m.rollback(backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns'), original)

    def test_conflicting_dev_runtime_prevents_all_writes(self):
        baseline = dict(self.dev)
        baseline['ApogeeHealsDev/Core/Access.lua'] += b'-- local unexpected change'
        client, backup = self.fixture(baseline)
        before = m.tree(client)
        with self.assertRaises(ValueError): installer.install(client, self.dev, self.known, backup)
        self.assertEqual(m.tree(client), before); self.assertFalse(backup.exists())

    def test_reviewed_dev_update_uses_receipt_and_preserves_rollback_chain(self):
        client, first_backup = self.fixture(self.prod)
        first = installer.install(client, self.dev, self.known, first_backup)
        updated = dict(self.dev)
        path = 'ApogeeHealsDev/' + dual.GATE_PATH
        updated[path] += b'\n-- fixture next reviewed version\n'
        second_backup = first_backup.parent / 'backup-update'
        result = installer.install(client, updated, self.known, second_backup, previous=first)
        self.assertEqual(len(result['writes']), 1)
        self.assertEqual(m.managed(client / 'Interface/AddOns'), self.prod)
        m.rollback(second_backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns', tuple(n + 'Dev' for n in m.NAMES)), self.dev)
        m.rollback(first_backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns', tuple(n + 'Dev' for n in m.NAMES)), {})

    def test_lexical_transform_preserves_comments_and_gameplay_literals(self):
        source = b'-- ApogeeTankUIDB\nlocal x="1"; local y="Interface/Icons/Spell"\nApogeeTankUIDB={}\n'
        output, edits = dual.transform_lua(source, 'ApogeeTank')
        self.assertTrue(output.startswith(b'-- ApogeeTankUIDB'))
        self.assertIn(b'ApogeeTankDevUIDB={}', output)
        self.assertIn(b'local x="1"', output)
        with self.assertRaises(ValueError): dual.transform_lua(b'ApogeeTankUnknown={}', 'ApogeeTank')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--sources-root', type=Path, required=True)
    parser.add_argument('--artifacts', type=Path, required=True)
    OPTIONS = parser.parse_args(); OPTIONS.owns_artifacts = False
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(DualTests))
    if OPTIONS.owns_artifacts:
        (OPTIONS.artifacts / 'summary.json').write_bytes(d.canonical({
            'tests': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors),
            'nativeClientTested': False, 'curseforgeAppTested': False}))
    sys.exit(not result.wasSuccessful())
