import argparse
import copy
import json
from pathlib import Path
import subprocess
import sys
import unittest
from types import SimpleNamespace
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

    def test_native_forever_identity_and_revision_tolerance(self):
        for child in self.lock['children']:
            name = child['name'] + 'Dev'
            subprocess.run(['lua', str(ROOT / 'tests/distribution/client_identity.lua'),
                            str(OPTIONS.artifacts / 'DEV' / name), name], check=True)

    def test_receipted_retirement_and_rollback_preserve_unknown_files(self):
        path = 'ApogeeEssentialsDev/Thanks/Retired.lua'
        extra = 'ApogeeEssentialsDev/Thanks/User.lua'
        files = dict(self.dev); files[path] = b'-- retired module'; files[extra] = b'-- user file'
        client, backup = self.fixture(files)
        previous = {'schema': 1, 'status': 'installed', 'client': str(client), 'after': {path: d.sha(files[path])}}
        result = installer.install(client, self.dev, self.known, backup, previous=previous, retire_files=[path])
        self.assertFalse((client / 'Interface/AddOns' / path).exists())
        self.assertEqual((backup / 'retired-files' / path).read_bytes(), files[path])
        self.assertEqual((client / 'Interface/AddOns' / extra).read_bytes(), files[extra])
        self.assertEqual(result['retired'], previous['after'])
        m.rollback(backup)
        self.assertEqual((client / 'Interface/AddOns' / path).read_bytes(), files[path])

    def test_interrupted_retirement_recovers_from_verified_backup(self):
        paths = ['ApogeeEssentialsDev/Thanks/One.lua', 'ApogeeEssentialsDev/Thanks/Two.lua']
        files = dict(self.dev)
        for p in paths: files[p] = b'-- retired'
        client, backup = self.fixture(files)
        previous = {'schema': 1, 'status': 'installed', 'client': str(client),
                    'after': {p: d.sha(files[p]) for p in paths}}
        replace = m.os.replace
        def fail_second(source, target):
            if str(source).endswith('Two.lua'): raise OSError('injected sharing violation')
            return replace(source, target)
        with patch.object(m.os, 'replace', side_effect=fail_second), self.assertRaises(OSError):
            installer.install(client, self.dev, self.known, backup, previous=previous, retire_files=paths)
        self.assertEqual(json.loads((backup / 'transaction.json').read_text())['status'],
                         'incomplete-recover-with-rollback')
        m.rollback(backup)
        for p in paths: self.assertEqual((client / 'Interface/AddOns' / p).read_bytes(), files[p])

    def test_retirement_refuses_modified_or_packaged_files_and_rollback_conflict(self):
        path = 'ApogeeEssentialsDev/Thanks/Retired.lua'
        files = dict(self.dev); files[path] = b'-- original'
        client, backup = self.fixture(files)
        previous = {'schema': 1, 'status': 'installed', 'client': str(client), 'after': {path: d.sha(files[path])}}
        target = client / 'Interface/AddOns' / path
        target.write_bytes(b'-- user change')
        with self.assertRaises(ValueError):
            installer.install(client, self.dev, self.known, backup, previous=previous, retire_files=[path])
        self.assertFalse(backup.exists())
        target.write_bytes(files[path])
        with self.assertRaises(ValueError):
            installer.install(client, files, self.known, backup, previous=previous, retire_files=[path])
        self.assertFalse(backup.exists())
        installer.install(client, self.dev, self.known, backup, previous=previous, retire_files=[path])
        target.write_bytes(b'-- new user file')
        with self.assertRaises(ValueError): m.rollback(backup)
        self.assertEqual(target.read_bytes(), b'-- new user file')

    def test_public_selection_omits_tank_but_retains_complete_dev(self):
        self.assertNotIn('ApogeeTank', d.public_children(self.lock))
        self.assertFalse(any(p.startswith('ApogeeTank/') for p in self.prod))
        self.assertIn('ApogeeTankDev/ApogeeTankDev.toc', self.dev)
        for family, files in (('PROD', self.prod), ('DEV', self.dev)):
            for p, b in files.items():
                if p.endswith('.toc'):
                    meta, runtime = d.toc_info(b)
                    self.assertFalse(any(k in meta for k in ('Dependencies', 'RequiredDeps', 'OptionalDeps', 'LoadWith')))
                    self.assertTrue(all(p.rsplit('/', 1)[0] + '/' + f in files for f in runtime))
        # Simulated acceptance tests publisher mechanics only, never live acceptance.
        accepted = {'accepted': True, 'runtimeFiles': {
            f: {p: d.sha(b) for p, b in files.items() if p.endswith('.lua')}
            for f, files in (('PROD', self.prod), ('DEV', self.dev))}}
        evidence = OPTIONS.artifacts / 'simulated-native-acceptance.json'
        evidence.write_bytes(d.canonical(accepted))
        with patch.object(publisher, 'ACCEPTANCE', evidence):
            self.assertEqual(publisher.payload(OPTIONS.sources_root, self.lock['version']), d.zip_bytes(self.prod))

    def test_auction_is_hosted_in_both_families(self):
        self.assertIn('ApogeeAuction', d.public_children(self.lock))
        prod_meta, _ = d.toc_info(self.prod['ApogeeAuction/ApogeeAuction.toc'])
        self.assertEqual(prod_meta['SavedVariablesPerCharacter'], 'ApogeeAuctionDB')
        self.assertEqual(prod_meta['IconTexture'], 'Interface/AddOns/ApogeeAuction/Media/Textures/ApogeeLogo.png')
        name = 'ApogeeAuctionDev'
        meta, runtime = d.toc_info(self.dev[name + '/' + name + '.toc'])
        gameplay = ['Core/Compare.lua', 'Core/Combat.lua', 'Core/Profiles.lua', 'Rules/Paladin.lua', 'Rules/Paladin/Healing.lua',
                    'Rules/Paladin/Damage.lua', 'Rules/Paladin/Tank.lua',
                    'Rules/Warrior.lua', 'Rules/Warrior/Damage.lua', 'Rules/Warrior/Tank.lua',
                    'Rules/Priest.lua', 'Rules/Priest/Healing.lua', 'Rules/Priest/Damage.lua',
                    'Rules/Mage.lua', 'Rules/Mage/Damage.lua', 'Rules/Warlock.lua', 'Rules/Warlock/Damage.lua',
                    'Rules/Rogue.lua', 'Rules/Rogue/Damage.lua', 'Rules/Hunter.lua', 'Rules/Hunter/Damage.lua',
                    'Rules/Shaman.lua', 'Rules/Shaman/Healing.lua', 'Rules/Shaman/Damage.lua',
                    'Rules/Druid.lua', 'Rules/Druid/Healing.lua', 'Rules/Druid/Tank.lua', 'Rules/Druid/Damage.lua',
                    'Core/Items.lua', 'Core/Group.lua', 'Core/Evaluate.lua']
        self.assertEqual(runtime, [dual.GATE_PATH, name + '.lua'] + gameplay + ['RoleSettings.lua', 'Auction/Filter.lua', 'Auction/Browse.lua'])
        self.assertEqual(meta.get('SavedVariablesPerCharacter'), 'ApogeeAuctionDevDB')
        self.assertNotIn('SavedVariables', meta)
        body = self.dev[name + '/' + name + '.lua']
        self.assertTrue(body.startswith(dual.prefix(name, 'DEV')))
        child = next(c for c in self.lock['children'] if c['name'] == 'ApogeeAuction')
        source = d.source_tree(OPTIONS.sources_root / child['name'], child['commit'])
        expected_body = source['ApogeeAuction.lua']
        self.assertEqual(body, dual.prefix(name, 'DEV') + expected_body)
        settings_body = self.dev[name + '/RoleSettings.lua']
        expected_settings = source['RoleSettings.lua'].replace(
            b'ApogeeAuctionDB', b'ApogeeAuctionDevDB').replace(
            b'Apogee Auction', b'Apogee Auction DEV').replace(
            b'APOGEE_AUCTION_DEFAULTS', b'APOGEE_AUCTION_DEV_DEFAULTS')
        self.assertEqual(settings_body, dual.prefix(name, 'DEV') + expected_settings)
        for path in gameplay + ['Auction/Filter.lua', 'Auction/Browse.lua']:
            self.assertEqual(self.dev[name + '/' + path], dual.prefix(name, 'DEV') + source[path])
        # Retain old installed paths as inert, unloaded stubs. The owning
        # evaluation suite also executes them and checks for registrations.
        for path in ('Rules/Other.lua', 'Rules/Paladin/Combat.lua', 'Rules/Warrior/Combat.lua'):
            self.assertNotIn(path, runtime)
            self.assertEqual(self.dev[name + '/' + path], source[path])
            self.assertEqual(self.prod['ApogeeAuction/' + path], source[path])
        pinned_files = {p: source[p] for p in child['files']}
        d.child_contract(child, pinned_files)
        for path in ('Rules/Other.lua', 'Rules/Paladin/Combat.lua', 'Rules/Warrior/Combat.lua'):
            changed = dict(pinned_files)
            changed[path] += b'CreateFrame("Frame")\n'
            with self.assertRaises(ValueError): d.child_contract(child, changed)
        changed = dict(pinned_files)
        changed['Rules/Unexpected.lua'] = source['Rules/Other.lua']
        with self.assertRaises(ValueError): d.child_contract(child, changed)
        foreign_child = dict(child, name='ApogeeHeals')
        with self.assertRaises(ValueError): d.child_contract(foreign_child, pinned_files)
        changed = dict(pinned_files)
        changed[child['toc']] += b'README.md\n'
        with self.assertRaises(ValueError): d.child_contract(child, changed)
        (OPTIONS.artifacts / 'loot-scenarios.lua').write_bytes(source['tests/loot-scenarios.lua'])
        evaluation_check = OPTIONS.artifacts / 'auction-evaluation.lua'
        evaluation_check.write_bytes(source['tests/evaluation.lua'])
        subprocess.run(['lua', str(evaluation_check), str(OPTIONS.artifacts / 'DEV' / name), name], check=True)
        # Execute real loot/group regressions against transformed package bytes.
        for script in ('loot-scenarios.lua', 'group-fixtures.lua', 'group-scenarios.lua', 'group-browse.lua', 'core-stats.lua'):
            (OPTIONS.artifacts / script).write_bytes(source['tests/' + script])
        for script in ('loot-scenarios.lua', 'group-scenarios.lua', 'group-browse.lua', 'core-stats.lua'):
            subprocess.run(['lua', str(OPTIONS.artifacts / script),
                            str(OPTIONS.artifacts / 'DEV' / name), name], check=True)
        settings_check = OPTIONS.artifacts / 'auction-settings.lua'
        settings_check.write_bytes(source['tests/role-settings.lua'])
        subprocess.run(['lua', str(settings_check),
                        str(OPTIONS.artifacts / 'DEV' / name / 'RoleSettings.lua'), name], check=True)
        for script in ('auction-filter.lua', 'auction-browse.lua'):
            check_path = OPTIONS.artifacts / script
            check_path.write_bytes(source['tests/' + script])
            subprocess.run(['lua', str(check_path), str(OPTIONS.artifacts / 'DEV' / name), name], check=True)
        # Execute the generated body in a strict sandbox: admission must precede
        # even client inspection and tooltip registration.
        check = OPTIONS.artifacts / 'auction-bootstrap.lua'
        check.write_text('''
local path = arg[1]
for _, admitted in ipairs({false, true}) do
    local namespace = {__ApogeeFamilyAdmission=function(name)
        assert(name == "ApogeeAuctionDev"); return admitted end}
    local calls, registrations = 0, 0
    local env = {type=type,
        Enum={TooltipDataType={Item=0}},
        TooltipDataProcessor={AddTooltipPostCall=function(kind, callback)
            assert(kind == 0 and type(callback) == "function")
            registrations=registrations+1
        end},
        GetBuildInfo=function()
        calls=calls+1; return "1.60.1", "70009", "", 16001 end}
    setmetatable(env, {__index=function(_, k) error("Unexpected API: "..k) end,
                      __newindex=function(_, k) error("Unexpected global: "..k) end})
    local chunk=assert(loadfile(path)); setfenv(chunk, env)
    chunk("ApogeeAuctionDev", namespace)
    assert(calls == (admitted and 1 or 0))
    assert(registrations == (admitted and 1 or 0))
    assert(namespace.ready == (admitted and true or nil))
end
''')
        subprocess.run(['lua', str(check), str(OPTIONS.artifacts / 'DEV' / name / (name + '.lua'))], check=True)

    def test_local_only_history_remains_private_and_pins_are_verified(self):
        baseline = copy.deepcopy(self.lock)
        child = baseline['children'].pop()
        baseline['publicChildren'].remove('ApogeeAuction')
        child.pop('repository'); child['localOnly'] = True
        baseline['localDevChildren'] = [child]
        self.assertEqual(d.local_dev_children(baseline), [child])
        self.assertFalse(any(p.startswith('ApogeeAuction/') for p in
                             dual.family_files(baseline, OPTIONS.sources_root, 'PROD')[0]))
        bad = copy.deepcopy(baseline); bad['publicChildren'].append('ApogeeAuction')
        with self.assertRaises(ValueError): d.public_children(bad)
        bad = copy.deepcopy(baseline)
        bad['localDevChildren'][0]['repository'] = 'https://example.com/unreviewed.git'
        with self.assertRaises(ValueError): d.local_dev_children(bad)
        bad = copy.deepcopy(self.lock); bad['localDevChildren'] = [child]
        with self.assertRaises(ValueError): d.local_dev_children(bad)
        for family in ('PROD', 'DEV'):
            bad = copy.deepcopy(self.lock)
            bad['children'][-1]['files']['ApogeeAuction.lua'] = '0' * 64
            with self.assertRaisesRegex(ValueError, 'pinned file mismatch'):
                dual.family_files(bad, OPTIONS.sources_root, family)

    def test_auction_install_and_rollback_preserve_existing_family(self):
        old = {p: b for p, b in self.dev.items() if not p.startswith('ApogeeAuctionDev/')}
        client, backup = self.fixture(old)
        result = installer.install(client, self.dev, self.known, backup)
        self.assertIn('ApogeeAuctionDev', result['names'])
        self.assertEqual(m.tree(client / 'Interface/AddOns/ApogeeAuctionDev'),
                         {p.split('/', 1)[1]: b for p, b in self.dev.items() if p.startswith('ApogeeAuctionDev/')})
        m.rollback(backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns', m.DEV_NAMES + m.LOCAL_DEV_NAMES), old)
        for names in ([], ['Unknown'], ['ApogeeTank', 'ApogeeHeals'], ['ApogeeHeals', 'ApogeeHeals']):
            invalid = copy.deepcopy(self.lock); invalid['publicChildren'] = names
            with self.assertRaises(ValueError): d.public_children(invalid)

    def test_production_gameplay_bodies_are_identical_to_pins(self):
        source = d.collect(self.lock, OPTIONS.sources_root, 'local-candidate')
        for path, change in self.prod_changes.items():
            prefix = dual.prefix(path.split('/')[0], 'PROD')
            self.assertEqual(self.prod[path], prefix + source[change['source']])
            self.assertEqual(change['identityEdits'], [])

    def test_group_and_heals_icons_bundle_same_brand_asset(self):
        logo = 'Media/Textures/ApogeeLogo.png'
        for family, files in (('PROD', self.prod), ('DEV', self.dev)):
            suffix = 'Dev' if family == 'DEV' else ''
            expected = files['ApogeeKeybinds' + suffix + '/' + logo]
            for base in (d.MARKER, 'ApogeeHeals'):
                name = base + suffix
                meta, runtime = d.toc_info(files[name + '/' + name + '.toc'])
                self.assertEqual(meta['IconTexture'], 'Interface/AddOns/' + name + '/' + logo)
                self.assertEqual(files[name + '/' + logo], expected)
                if base == d.MARKER:
                    self.assertEqual(runtime, [])
                    self.assertFalse(any(k.startswith('SavedVariables') for k in meta))

    def test_exact_roots_tocs_guards_separate_saves_and_no_dev_project_ids(self):
        saves = {}
        for family, files in (('PROD', self.prod), ('DEV', self.dev)):
            names = tuple(n + ('Dev' if family == 'DEV' else '') for n in (d.MARKER, *dual.family_children(self.lock, family)))
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
        # Keep pathlib on the real host platform while simulating the installer OS check.
        with patch.object(m, 'os', SimpleNamespace(name='nt')), patch.object(m.subprocess, 'run', return_value=process):
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
        self.assertEqual(m.managed(client / 'Interface/AddOns', m.DEV_NAMES + m.LOCAL_DEV_NAMES), self.dev)

    def test_public_package_has_player_guide_and_required_notices(self):
        source = d.collect(self.lock, OPTIONS.sources_root, 'local-candidate')
        for child in self.lock['children']:
            if child['name'] not in d.public_children(self.lock): continue
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
        legacy_lock = copy.deepcopy(self.lock); legacy_lock.pop('publicChildren', None)
        retrofit_prod, _ = dual.family_files(legacy_lock, OPTIONS.sources_root, 'PROD')
        result = installer.install(client, dict(retrofit_prod, **self.dev), self.known, backup, True)
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
        self.assertEqual(m.managed(client / 'Interface/AddOns', m.DEV_NAMES + m.LOCAL_DEV_NAMES), self.dev)
        m.rollback(first_backup)
        self.assertEqual(m.managed(client / 'Interface/AddOns', tuple(n + 'Dev' for n in m.NAMES)), {})

    def test_lexical_transform_preserves_comments_and_gameplay_literals(self):
        source = b'-- ApogeeTankUIDB\nlocal x="1"; local y="Interface/Icons/Spell"\nApogeeTankUIDB={}\n'
        output, edits = dual.transform_lua(source, 'ApogeeTank')
        self.assertTrue(output.startswith(b'-- ApogeeTankUIDB'))
        self.assertIn(b'ApogeeTankDevUIDB={}', output)
        self.assertIn(b'local x="1"', output)
        with self.assertRaises(ValueError): dual.transform_lua(b'ApogeeTankUnknown={}', 'ApogeeTank')

    def test_heals_default_is_independent_and_reset_dialog_is_family_local(self):
        canonical = 'APOGEE_HEALS_RESET_CHARACTER'
        development = 'APOGEE_HEALS_DEV_RESET_CHARACTER'
        for family, files in (('PROD', self.prod), ('DEV', self.dev)):
            suffix = 'Dev' if family == 'DEV' else ''
            settings = files['ApogeeHeals' + suffix + '/UI/Settings.lua'].decode()
            expected = development if suffix else canonical
            forbidden = canonical if suffix else development
            tokens = [token.strip(chr(34) + chr(39)) for kind, token in dual.lua_tokens(settings)
                      if kind in ('identifier', 'string')]
            self.assertIn(expected, tokens)
            self.assertNotIn(forbidden, tokens)
            editor = files['ApogeeHeals' + suffix + '/UI/BindingEditor.lua'].decode()
            self.assertNotIn('ApogeeKeybinds', editor)
            meta, _ = d.toc_info(files['ApogeeHeals' + suffix + '/ApogeeHeals' + suffix + '.toc'])
            self.assertNotIn('Dependencies', meta)
            self.assertNotIn('RequiredDeps', meta)
        source = ('-- ' + canonical + '\nStaticPopup_Show("' + canonical + '")\n').encode()
        output, edits = dual.transform_lua(source, 'ApogeeHeals')
        self.assertEqual(output, ('-- ' + canonical + '\nStaticPopup_Show("' + development + '")\n').encode())
        self.assertEqual(len(edits), 1)


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
