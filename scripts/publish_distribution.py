"""Exact-byte Actions publisher. Not wired to a production trigger until access review."""
import argparse
import copy
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import urllib.request
from urllib.parse import urlsplit
import uuid

sys.dont_write_bytecode = True
import distribution as d
import dual_distribution as dual
from curseforge_preflight import NoRedirect, URL, select_version

REPOSITORY = 'notify353/ApogeePartyHealthBars'
PROJECT = 1608100
ACCEPTANCE = d.ROOT / 'distribution/native-acceptance.json'


def stable(version):
    d.require(re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)', version),
              'Stable X.Y.Z version required')
    return version


def release_notes(version):
    text = (d.ROOT / 'CHANGELOG.md').read_text(encoding='utf-8')
    header = '## [' + version + ']'
    d.require(header in text, 'Versioned changelog section required')
    return text.split(header, 1)[1].split('\n## [', 1)[0].split('\n', 1)[1].strip() + '\n'


def payload(sources_root, version):
    stable(version)
    lock = copy.deepcopy(d.read_lock(dual.LOCK)); lock['version'] = version
    accepted = json.loads(ACCEPTANCE.read_text())
    d.require(accepted.get('accepted') is True, 'Native owner acceptance required')
    packages = {}
    for family in ('PROD', 'DEV'):
        files, _ = dual.family_files(lock, sources_root, family)
        actual = {p: d.sha(b) for p, b in files.items() if p.endswith('.lua')}
        d.require(actual == accepted['runtimeFiles'][family], 'Runtime changed since native acceptance')
        packages[family] = files
    prod = packages['PROD']
    d.require(set(p.split('/')[0] for p in prod) == {d.MARKER, *d.CHILDREN}, 'Exactly six canonical roots required')
    for name in (d.MARKER, *d.CHILDREN):
        meta, _ = d.toc_info(prod[name + '/' + name + '.toc'])
        d.require(meta['Interface'] == '16001' and meta['X-Apogee-Family'] == 'PROD', 'Forever PROD only')
    archive = d.zip_bytes(prod); dual.validate(archive, prod)
    return archive


def stage(sources_root, version, output):
    archive = payload(sources_root, version)
    notes = release_notes(version)
    output = Path(output); output.mkdir(parents=True, exist_ok=False)
    filename = 'ApogeeForever-' + version + '.zip'
    (output / filename).write_bytes(archive)
    (output / (filename + '.sha256')).write_text(d.sha(archive) + '  ' + filename + '\n')
    (output / 'release-notes.md').write_text(notes, encoding='utf-8')
    receipt = {'schema': 1, 'version': version, 'projectId': PROJECT, 'filename': filename,
               'sha256': d.sha(archive), 'publicationState': 'staged', 'curseforgeClientTested': False}
    (output / 'receipt.json').write_bytes(d.canonical(receipt))
    return receipt


def gh(*args):
    result = subprocess.run(['gh', *args, '--repo', REPOSITORY], capture_output=True, text=True)
    d.require(result.returncode == 0, 'GitHub release operation failed; inspect release state before retrying')
    return result.stdout


def actions_guard(version):
    d.require(os.environ.get('GITHUB_ACTIONS') == 'true'
              and os.environ.get('GITHUB_REPOSITORY') == REPOSITORY
              and os.environ.get('GITHUB_REF') == 'refs/tags/v' + stable(version)
              and os.environ.get('APOGEE_PUBLISH_APPROVED') == 'true', 'Approved production tag in Actions required')
    head = d.git_bytes(d.ROOT, 'rev-parse', 'HEAD').decode().strip()
    tag = d.git_bytes(d.ROOT, 'rev-parse', 'refs/tags/v' + version + '^{commit}').decode().strip()
    d.require(head == tag == os.environ.get('GITHUB_SHA'), 'Exact approved tag checkout required')
    ancestor = subprocess.run(['git', '-C', str(d.ROOT), 'merge-base', '--is-ancestor', head, 'origin/main'], capture_output=True)
    d.require(ancestor.returncode == 0, 'Release commit must be integrated into main')


def metadata(version, row, notes):
    exact = select_version([row])
    return {'displayName': 'Apogee Forever ' + stable(version), 'releaseType': 'release',
            'gameVersions': [exact['id']], 'changelogType': 'markdown', 'changelog': notes}


def multipart(meta, filename, archive, boundary):
    d.require(re.fullmatch(r'ApogeeForever-[0-9]+\.[0-9]+\.[0-9]+\.zip', filename), 'Unsafe archive name')
    return (('--' + boundary + '\r\nContent-Disposition: form-data; name="metadata"\r\n'
             'Content-Type: application/json\r\n\r\n').encode() + json.dumps(meta).encode() +
            ('\r\n--' + boundary + '\r\nContent-Disposition: form-data; name="file"; filename="' + filename +
             '"\r\nContent-Type: application/zip\r\n\r\n').encode() + archive +
            ('\r\n--' + boundary + '--\r\n').encode())


def upload(sources_root, output):
    output = Path(output); receipt_path = output / 'receipt.json'
    receipt = json.loads(receipt_path.read_text()); version = receipt['version']
    actions_guard(version)
    d.require(receipt.get('projectId') == PROJECT and receipt.get('filename') == 'ApogeeForever-' + stable(version) + '.zip'
              and re.fullmatch('[0-9a-f]{64}', receipt.get('sha256', '')), 'Invalid release receipt')
    d.require(receipt['publicationState'] == 'staged', 'Previous upload attempt exists; never retry automatically')
    archive = (output / receipt['filename']).read_bytes()
    d.require(archive == payload(sources_root, version) and d.sha(archive) == receipt['sha256'], 'Staged ZIP changed')
    notes = release_notes(version)
    d.require((output / 'release-notes.md').read_text(encoding='utf-8') == notes, 'Release notes changed')
    token = os.environ.get('CF_API_KEY'); d.require(token, 'CurseForge credential unavailable')
    opener = urllib.request.build_opener(NoRedirect)
    request = urllib.request.Request(URL, headers={'X-Api-Token': token, 'Accept': 'application/json'})
    with opener.open(request, timeout=30) as response:
        row = select_version(json.load(response))
    meta = metadata(version, row, notes)
    # Creating an existing release fails. No automatic recovery can repeat a CF POST.
    gh('release', 'create', 'v' + version, '--verify-tag', '--draft', '--title', 'Apogee Forever ' + version,
       '--notes-file', str(output / 'release-notes.md'))
    gh('release', 'upload', 'v' + version, str(output / receipt['filename']), str(output / (receipt['filename'] + '.sha256')))
    receipt.update(publicationState='curseforge-upload-attempted', uploadVersion=row)
    receipt_path.write_bytes(d.canonical(receipt))
    boundary = 'apogee-' + uuid.uuid4().hex
    request = urllib.request.Request('https://wow.curseforge.com/api/projects/1608100/upload-file',
        data=multipart(meta, receipt['filename'], archive, boundary), method='POST',
        headers={'X-Api-Token': token, 'Content-Type': 'multipart/form-data; boundary=' + boundary})
    with opener.open(request, timeout=120) as response:
        result = json.load(response)
    file_id = result.get('id')
    d.require(type(file_id) is int and file_id > 0, 'Upload response missing file ID; investigate before retrying')
    receipt.update(publicationState='awaiting-public-byte-verification', curseforgeFileId=file_id)
    receipt_path.write_bytes(d.canonical(receipt))
    return receipt


def verify(output, download_url):
    output = Path(output); receipt_path = output / 'receipt.json'
    receipt = json.loads(receipt_path.read_text()); version = receipt['version']
    actions_guard(version)
    d.require(receipt.get('projectId') == PROJECT and receipt.get('filename') == 'ApogeeForever-' + stable(version) + '.zip'
              and re.fullmatch('[0-9a-f]{64}', receipt.get('sha256', '')), 'Invalid release receipt')
    d.require(receipt['publicationState'] == 'awaiting-public-byte-verification', 'Confirmed upload receipt required')
    url = urlsplit(download_url)
    d.require(url.scheme == 'https' and url.hostname in ('edge.forgecdn.net', 'mediafilez.forgecdn.net')
              and not url.username and not url.password and not url.query and not url.fragment
              and url.path.endswith('/' + receipt['filename'])
              and len(url.path.split('/')) == 5 and url.path.split('/')[1] == 'files'
              and ''.join(url.path.split('/')[2:4]).isdigit()
              and int(url.path.split('/')[2]) * 1000 + int(url.path.split('/')[3]) == receipt['curseforgeFileId'], 'Use the exact approved file download link')
    with urllib.request.build_opener(NoRedirect).open(download_url, timeout=60) as response:
        cf_bytes = response.read(16 * 1024 * 1024)
    d.require(d.sha(cf_bytes) == receipt['sha256'], 'CurseForge package checksum differs')
    with tempfile.TemporaryDirectory() as folder:
        gh('release', 'download', 'v' + version, '--pattern', receipt['filename'], '--dir', folder)
        d.require(d.sha((Path(folder) / receipt['filename']).read_bytes()) == receipt['sha256'], 'GitHub package checksum differs')
    gh('release', 'edit', 'v' + version, '--draft=false')
    receipt.update(publicationState='published-and-byte-verified', curseforgeDownloadUrl=download_url)
    receipt_path.write_bytes(d.canonical(receipt))
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=('stage', 'upload', 'verify'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--sources-root', type=Path)
    parser.add_argument('--version')
    parser.add_argument('--curseforge-download-url')
    args = parser.parse_args()
    try:
        if args.operation == 'stage':
            d.require(args.sources_root and args.version, 'Stage requires sources and version')
            result = stage(args.sources_root, args.version, args.output)
        elif args.operation == 'upload':
            d.require(args.sources_root, 'Upload requires source verification')
            result = upload(args.sources_root, args.output)
        else:
            d.require(args.curseforge_download_url, 'Verification requires approved download URL')
            result = verify(args.output, args.curseforge_download_url)
        print(json.dumps(result, sort_keys=True))
    except Exception:
        # Never print credential-bearing request objects, response bodies or subprocess stderr.
        parser.exit(1, 'Release operation stopped. Inspect the receipt and service state before retrying; no automatic upload retry.\n')

if __name__ == '__main__':
    main()
