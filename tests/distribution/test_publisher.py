import os
import io
import json
import tempfile
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
import publish_distribution as p

class PublisherTests(unittest.TestCase):
    def test_requires_stable_version(self):
        self.assertEqual(p.stable('1.0.0'), '1.0.0')
        for value in ('1.0.0-local.1','v1.0.0','01.0.0','1.0','../1.0.0'):
            with self.assertRaises(ValueError): p.stable(value)

    def test_no_local_upload(self):
        with patch.dict(os.environ, {}, clear=True), self.assertRaises(ValueError):
            p.actions_guard('1.0.0')

    def test_exact_flavor_upload_metadata(self):
        row={'id':123456,'name':'1.60.1','gameVersionTypeID':88568}
        result=p.metadata('1.0.0',row,'Player changes')
        self.assertEqual(result['gameVersions'],[123456])
        self.assertNotIn('gameVersionNames',result)
        self.assertEqual(result['releaseType'],'release')
        with self.assertRaises(ValueError): p.metadata('1.0.0',dict(row,gameVersionTypeID=1),'Changes')

    def test_multipart_preserves_exact_zip_bytes(self):
        archive=b'PK\x03\x04test\x00\xff\r\ncontents'
        body=p.multipart({'gameVersions':[123456]},'ApogeeForever-1.0.0.zip',archive,'boundary')
        self.assertEqual(body.split(b'Content-Type: application/zip\r\n\r\n')[1], archive+b'\r\n--boundary--\r\n')
        with self.assertRaises(ValueError): p.multipart({},'bad\r\nname.zip',archive,'boundary')

    def test_uncertain_post_is_recorded_and_cannot_be_retried(self):
        archive=b'PK-test'; version='1.0.0'
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); filename='ApogeeForever-'+version+'.zip'
            (root/filename).write_bytes(archive)
            (root/'release-notes.md').write_text('Changes\n')
            (root/'receipt.json').write_text(json.dumps({'version':version,'projectId':1608100,
                'filename':filename,'sha256':p.d.sha(archive),'publicationState':'staged'}))
            requests=[]
            class Opener:
                def open(self,request,timeout):
                    requests.append(request.get_method())
                    if request.get_method() == 'POST': raise TimeoutError('uncertain upload')
                    return io.BytesIO(json.dumps([{'id':123456,'name':'1.60.1','gameVersionTypeID':88568}]).encode())
            with patch.object(p,'actions_guard'), patch.object(p,'payload',return_value=archive), \
                 patch.object(p,'release_notes',return_value='Changes\n'), patch.object(p,'gh'), \
                 patch.object(p.urllib.request,'build_opener',return_value=Opener()), \
                 patch.dict(os.environ,{'CF_API_KEY':'test-placeholder'}):
                with self.assertRaises(TimeoutError): p.upload(root,root)
                self.assertEqual(json.loads((root/'receipt.json').read_text())['publicationState'],'curseforge-upload-attempted')
                with self.assertRaises(ValueError): p.upload(root,root)
            self.assertEqual(requests,['GET','POST'])

    def test_mismatched_public_bytes_never_publish_github(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            (root/'receipt.json').write_text(json.dumps({'version':'1.0.0','projectId':1608100,
                'filename':'ApogeeForever-1.0.0.zip','sha256':p.d.sha(b'expected'),
                'publicationState':'awaiting-public-byte-verification','curseforgeFileId':1234005}))
            class Opener:
                def open(self,*args,**kwargs): return io.BytesIO(b'wrong')
            with patch.object(p,'actions_guard'), patch.object(p,'gh') as github, \
                 patch.object(p.urllib.request,'build_opener',return_value=Opener()):
                with self.assertRaises(ValueError):
                    p.verify(root,'https://edge.forgecdn.net/files/1234/5/ApogeeForever-1.0.0.zip')
                github.assert_not_called()

    def test_foreign_download_link_never_fetched(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            (root/'receipt.json').write_text(json.dumps({'version':'1.0.0','projectId':1608100,
                'filename':'ApogeeForever-1.0.0.zip','sha256':p.d.sha(b'expected'),
                'publicationState':'awaiting-public-byte-verification','curseforgeFileId':1234005}))
            with patch.object(p,'actions_guard'), patch.object(p.urllib.request,'build_opener') as network:
                with self.assertRaises(ValueError):
                    p.verify(root,'https://example.com/files/1234/5/ApogeeForever-1.0.0.zip')
                network.assert_not_called()

if __name__ == '__main__': unittest.main(verbosity=2)
