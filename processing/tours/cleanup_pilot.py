"""Remove orphan media ONLY for deleted disposable accounts in pilot checkpoints."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import requests
from local_runner import read_config

ROOT = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true')
    args = parser.parse_args()
    if not args.run:
        parser.exit(message='Explicit opt-in required: cleanup_pilot.py --run\n')
    config = read_config(ROOT / 'config/.env.tours-local')
    session = requests.Session()
    session.headers.update({'apikey': config['SUPABASE_SERVICE_ROLE_KEY'],
                            'Authorization': 'Bearer ' + config['SUPABASE_SERVICE_ROLE_KEY']})
    base = config['SUPABASE_URL']
    owners = set()
    for checkpoint in (ROOT / 'output/tours-pilot').glob('resources-*.json'):
        record = json.loads(checkpoint.read_text())
        if not re.fullmatch(r'[0-9a-f]{10}', record['run']):
            raise ValueError('Invalid pilot checkpoint')
        for index, user in enumerate(record['users']):
            if user['email'] != f'marea-tours-{record["run"]}-{index}@example.invalid':
                raise ValueError('Checkpoint is not a disposable pilot account')
            if not re.fullmatch(r'[0-9a-f-]{36}', user['id']):
                raise ValueError('Invalid disposable owner ID')
            response = session.get(base + '/auth/v1/admin/users/' + user['id'], timeout=30)
            # Never touch live accounts (including a concurrently executing test).
            if response.status_code == 404:
                owners.add(user['id'])
            elif response.status_code != 200:
                raise RuntimeError('Cannot verify disposable account deletion')
    removed = 0
    for owner in sorted(owners):
        for bucket in ('tour-inputs', 'tour-assets'):
            todo, files = [owner], []
            while todo:
                prefix = todo.pop()
                offset = 0
                while True:
                    response = session.post(base + '/storage/v1/object/list/' + bucket,
                                            json={'prefix': prefix, 'limit': 100, 'offset': offset}, timeout=30)
                    response.raise_for_status()
                    entries = response.json()
                    for entry in entries:
                        name = entry['name']
                        if '/' in name or '\\' in name or name in ('', '.', '..'):
                            raise ValueError('Unsafe Storage entry')
                        path = prefix + '/' + name
                        if entry.get('id'):
                            files.append(path)
                        else:
                            todo.append(path)
                    if len(entries) < 100:
                        break
                    offset += len(entries)
            for start in range(0, len(files), 100):
                response = session.delete(base + '/storage/v1/object/' + bucket,
                                          json={'prefixes': files[start:start + 100]}, timeout=60)
                response.raise_for_status()
                removed += len(files[start:start + 100])
    print(json.dumps({'deleted_disposable_accounts_checked': len(owners),
                      'orphan_test_objects_removed': removed}))

if __name__ == '__main__':
    main()
