"""Read-only authenticated Forever version lookup. Never uploads or prints credentials."""
import json
import os
import sys
import urllib.error
import urllib.request

URL = 'https://wow.curseforge.com/api/game/versions'

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError('Authenticated redirect refused')

def select_version(rows):
    if not isinstance(rows, list):
        raise ValueError('Unexpected version response')
    matches = [row for row in rows if isinstance(row, dict)
               and row.get('name') == '1.60.1' and row.get('gameVersionTypeID') == 88568]
    if len(matches) != 1:
        raise ValueError('Exactly one Forever 1.60.1 upload version is required; no fallback')
    row = matches[0]
    if type(row.get('id')) is not int or row['id'] <= 0 or row['id'] == 88568:
        raise ValueError('Invalid upload version ID')
    return {key: row[key] for key in ('id', 'name', 'gameVersionTypeID')}

def main():
    token = os.environ.get('CF_API_KEY')
    if not token:
        sys.exit('CurseForge credential is unavailable')
    request = urllib.request.Request(URL, headers={'X-Api-Token': token, 'Accept': 'application/json'})
    try:
        with urllib.request.build_opener(NoRedirect).open(request, timeout=30) as response:
            result = select_version(json.load(response))
    except urllib.error.HTTPError as error:
        sys.exit('CurseForge preflight HTTP status ' + str(error.code))
    except (ValueError, OSError):
        sys.exit('CurseForge exact Forever version lookup failed; no upload attempted')
    print(json.dumps(result, sort_keys=True))

if __name__ == '__main__':
    main()
