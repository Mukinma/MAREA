"""Opt-in hosted cleanup lease contract; one disposable account, no camera/AR."""
import argparse
import json
from pathlib import Path
import secrets
import subprocess
import uuid
import requests
from local_runner import read_config
from worker import Backend

ROOT = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true')
    args = parser.parse_args()
    if not args.run:
        parser.exit(message='Explicit opt-in required: check_cleanup_lease.py --run\n')
    config = read_config(ROOT / 'config/.env.tours-local')
    baseline = subprocess.run(['supabase', 'db', 'query', '--linked', '--output', 'json',
        "select count(*)::int n from private.tour_jobs where cleanup_needed or state in ('queued','processing')"],
        capture_output=True, text=True)
    if baseline.returncode or json.loads(baseline.stdout)['rows'][0]['n'] != 0:
        raise RuntimeError('Requires idle queue without foreign cleanup work')
    public = json.loads((ROOT / 'config/supabase.production.json').read_text())
    base, admin = config['SUPABASE_URL'], config['SUPABASE_SERVICE_ROLE_KEY']
    service = Backend(base, admin)
    session = requests.Session()
    anon = public['SUPABASE_ANON_KEY']
    def call(path, body=None, token=None, method='POST', privileged=False):
        key = admin if privileged else anon
        response = session.request(method, base + path, json=body,
            headers={'apikey': key, 'Authorization': 'Bearer ' + (token or key)}, timeout=60)
        response.raise_for_status()
        return response.json() if response.content else None
    policy = call('/rest/v1/rpc/registration_policy', {})
    run, password = secrets.token_hex(5), secrets.token_urlsafe(32)
    email = f'marea-tours-{run}-0@example.invalid'
    user = call('/auth/v1/admin/users', {'email': email, 'password': password, 'email_confirm': True,
        'user_metadata': {'full_name': 'Synthetic cleanup verification', 'username': f'tour_{run}_0',
            'user_type': 'Negocio', 'registration_flow': 'minimal-v1', 'accepted_terms': True,
            'adult_confirmed': True, 'terms_version': policy['terms']['version'],
            'privacy_version': policy['privacy']['version']}}, privileged=True)
    checkpoint = ROOT / 'output/tours-pilot' / f'resources-{run}.json'
    checkpoint.write_text(json.dumps({'run': run, 'users': [{'id': user['id'], 'email': email}]}))
    checkpoint.chmod(0o600)
    token = call('/auth/v1/token?grant_type=password', {'email': email, 'password': password})['access_token']
    def rpc(name, body):
        return call('/rest/v1/rpc/' + name, body, token=token)
    assertions = 0
    def check(value):
        nonlocal assertions
        if not value:
            raise AssertionError('Hosted cleanup lease contract failed')
        assertions += 1
    try:
        tour = rpc('tours_save', {'p_tour': str(uuid.uuid4()), 'p_title': 'TEST cleanup lease',
            'p_space': {}, 'p_document': {'zones': [], 'ar_order': []}})
        capture = rpc('tours_capture_begin', {'p_tour': tour['id'], 'p_scene': str(uuid.uuid4()), 'p_mode': 'import'})
        frame = str(uuid.uuid4())
        path = f'{user["id"]}/{capture["id"]}/{frame}.jpg'
        upload = session.post(base + '/storage/v1/object/tour-inputs/' + path,
            data=(ROOT / 'output/tours-pilot/remote-panorama.jpg').read_bytes(),
            headers={'apikey': anon, 'Authorization': 'Bearer ' + token, 'Content-Type': 'image/jpeg'}, timeout=60)
        upload.raise_for_status()
        # Queue fixture deliberately cancelled before any worker processes it.
        job = rpc('tours_capture_submit', {'p_capture': capture['id'], 'p_manifest': {'mode': 'import',
            'frames': [{'id': frame, 'path': path,
                'width': 4096, 'height': 2048, 'yaw': 0, 'pitch': 0, 'roll': 0, 'hfov': 360, 'vfov': 180}]}})
        rpc('tours_job_cancel', {'p_job': job['id']})
        lease = next(entry for entry in service.rpc('tours_claim_cleanup', {}) if entry['id'] == job['id'])
        guard = {'p_job': job['id'], 'p_lease': lease['lease_id']}
        check(service.rpc('tours_renew_cleanup', guard))
        denied = session.post(base + '/rest/v1/rpc/tours_renew_cleanup', json=guard,
            headers={'apikey': anon, 'Authorization': 'Bearer ' + token}, timeout=30)
        check(not denied.ok)
        # Accelerate ONLY this test account's guard; no sleep or foreign changes.
        query = f"update private.tour_output_writes set expires_at=clock_timestamp()-interval '1 second' where job_id='{job['id']}'::uuid and owner_id='{user['id']}'::uuid returning job_id"
        result = subprocess.run(['supabase', 'db', 'query', '--linked', '--output', 'json', query], capture_output=True, text=True)
        if result.returncode or len(json.loads(result.stdout)['rows']) != 1:
            raise RuntimeError('Could not expire isolated test guard')
        check(not service.rpc('tours_renew_cleanup', guard))
        replacement = next(entry for entry in service.rpc('tours_claim_cleanup', {}) if entry['id'] == job['id'])
        check(replacement['lease_id'] != lease['lease_id'])
        check(not service.rpc('tours_renew_cleanup', guard))
        new_guard = {'p_job': job['id'], 'p_lease': replacement['lease_id']}
        check(service.rpc('tours_renew_cleanup', new_guard))
        service.remove(replacement['paths'])
        check(service.rpc('tours_finish_cleanup', {**new_guard, 'p_success': True}))
    finally:
        response = session.post(base + '/functions/v1/delete-account', json={},
            headers={'apikey': anon, 'Authorization': 'Bearer ' + token}, timeout=60)
        if response.status_code != 204:
            raise RuntimeError('Disposable cleanup contract account could not be removed')
        remaining = session.post(base + '/storage/v1/object/list/tour-inputs',
            json={'prefix': user['id'], 'limit': 100},
            headers={'apikey': admin, 'Authorization': 'Bearer ' + admin}, timeout=30)
        remaining.raise_for_status()
        check(remaining.json() == [])
    result = {'passed': True, 'assertions': assertions, 'data': 'disposable cancelled queue fixture; no physical tests'}
    (ROOT / 'output/tours-pilot/cleanup-lease-result.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))

if __name__ == '__main__':
    main()
