"""Fail closed on unavailable, ambiguous, or wrong-flavor upload metadata."""
import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
from curseforge_preflight import select_version

class VersionTests(unittest.TestCase):
    def test_exact_forever_only(self):
        correct = {'id': 123456, 'name': '1.60.1', 'gameVersionTypeID': 88568}
        self.assertEqual(select_version([{'id': 123, 'name': '1.60.1', 'gameVersionTypeID': 1}, correct]), correct)

    def test_refuses_unavailable_ambiguous_or_type_id(self):
        correct = {'id': 123456, 'name': '1.60.1', 'gameVersionTypeID': 88568}
        for rows in ([], {}, [correct, correct], [dict(correct, name='1.60.0')],
                     [dict(correct, gameVersionTypeID=1)], [dict(correct, id=88568)],
                     [dict(correct, id=True)], [dict(correct, id='123456')]):
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                select_version(rows)

if __name__ == '__main__':
    unittest.main(verbosity=2)
