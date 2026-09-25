"""Self-contained source/metadata/release-gate checks; no child clones required."""
import json
from pathlib import Path
import re
import sys
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import distribution as d


class RepositoryTests(unittest.TestCase):
    def test_featureless_marker_and_no_legacy_runtime(self):
        meta, runtime = d.toc_info((ROOT / 'ApogeePartyHealthBars.toc').read_bytes())
        self.assertEqual(runtime, [])
        self.assertEqual(meta['Interface'], '16001')
        self.assertEqual(meta['X-Curse-Project-ID'], '1608100')
        self.assertEqual(meta['X-Apogee-Distribution-Only'], '1')
        self.assertEqual(meta['X-Apogee-Distribution-Schema'], '1')
        self.assertFalse(any(k.startswith('SavedVariables') for k in meta))
        self.assertFalse(list(ROOT.glob('*.lua')))
        for name in ('Actions','Bootstrap','Core','DungeonGuide','Integrations','Media','PartyFrames',
                     'Profiles','Reminders','Runtime','Settings','assets'):
            self.assertFalse((ROOT / name).exists(), name)
        self.assertEqual([p.name for p in (ROOT / 'tests').iterdir()], ['distribution'])

    def test_forever_lock_and_api_baseline(self):
        lock = d.read_lock(ROOT / 'distribution/candidate.lock.json')
        record = json.loads((ROOT / 'docs/wow-api-export.json').read_text())
        self.assertEqual(record['clientVersion'], lock['client']['reviewedBuild'])
        self.assertEqual(record['interface'], 16001)
        self.assertEqual(record['product'], 'wow_classic_beta')
        self.assertGreaterEqual(len(record['files']), 5)
        for item in record['files']:
            d.safe_path(item['path']); self.assertRegex(item['sha256'], r'^[0-9a-f]{64}$')

    def test_release_is_fail_closed_and_ci_uses_distribution_checks(self):
        workflow = (ROOT / '.github/workflows/release.yml').read_text()
        self.assertIn('contents: read', workflow)
        self.assertIn('exit 1', workflow)
        for unsafe in ('contents: write','CF_API_KEY','gh release','BigWigsMods/packager','tags:'):
            self.assertNotIn(unsafe, workflow)
        for filename in ('prepare-release.ps1','publish-release.ps1'):
            script = (ROOT / 'scripts' / filename).read_text()
            self.assertIn('throw ', script)
            self.assertNotIn('git tag', script); self.assertNotIn('git push', script)
        ci = (ROOT / '.github/workflows/lua-validation.yml').read_text()
        self.assertIn('test_repository.py', ci)
        self.assertIn('test-local.ps1', ci)
        self.assertIn('APOGEE_DISTRIBUTION_SOURCES_READY', ci)
        self.assertNotIn('pull_request_target', ci)
        self.assertNotIn('contents: write', ci)
        for name in d.CHILDREN:
            self.assertIn('repository: notify353/' + name, ci)
            self.assertIn('steps.pins.outputs.' + name, ci)


if __name__ == '__main__':
    unittest.main(verbosity=2)
