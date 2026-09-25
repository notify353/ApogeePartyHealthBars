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

    def test_release_requires_guarded_actions_and_private_sources_are_restricted(self):
        workflow = (ROOT / '.github/workflows/release.yml').read_text()
        self.assertIn("tags: ['v*.*.*']", workflow)
        self.assertIn('environment: production', workflow)
        self.assertIn('publish_distribution.py stage', workflow)
        self.assertIn('publish_distribution.py upload', workflow)
        self.assertIn('test-local.ps1', workflow)
        self.assertIn('if: always()', workflow)
        self.assertNotIn('pull_request', workflow)
        self.assertNotIn('workflow_dispatch', workflow)
        self.assertNotIn('BigWigsMods/packager', workflow)
        self.assertNotIn('dual_distribution.py --', workflow)
        publish = (ROOT / 'scripts/publish-release.ps1').read_text()
        self.assertIn('-not $ConfirmProduction', publish)
        self.assertIn("@('test','aggregate','version')", publish)
        self.assertIn('never reuse or move', publish)
        ci = (ROOT / '.github/workflows/lua-validation.yml').read_text()
        self.assertIn('test_repository.py', ci)
        self.assertIn('test-local.ps1', ci)
        self.assertIn('APOGEE_DISTRIBUTION_SOURCES_READY', ci)
        self.assertIn("github.ref == 'refs/heads/main'", ci)
        self.assertIn("github.event_name != 'pull_request'", ci)
        self.assertIn('environment: distribution-validation', ci)
        self.assertNotIn('pull_request_target', ci)
        self.assertNotIn('contents: write', ci)
        for name in d.CHILDREN:
            self.assertIn('repository: notify353/' + name, ci)
            self.assertIn('steps.pins.outputs.' + name, ci)
        preflight = (ROOT / '.github/workflows/curseforge-preflight.yml').read_text()
        self.assertIn('environment: distribution-validation', preflight)
        self.assertNotIn('publish_distribution', preflight)
        self.assertNotIn('contents: write', preflight)


if __name__ == '__main__':
    unittest.main(verbosity=2)
