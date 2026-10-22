"""Pure fail-closed acceptance validation. Never treats stale PASS as permission."""
import hashlib,json
from pathlib import Path
REQUIRED={'05-ORG0-installation.json','07-ORG0-GREEN.json','08-ORG0-concurrency-states.json','08b-ORG0-expiry-integrity.json','08c-ORG0-legacy-marker-regression.json','09b-ORG0-conservation-final.json','10-ORG0-recovery.json'}
def validate_org0_gate(root,gate):
 root=Path(root)
 if any(root.glob('*ORG0-ACCEPTANCE-INVALIDATED*.json')):raise ValueError('ORG0 acceptance invalidated')
 if gate.get('result')!='PASS' or gate.get('stage')!='ORG0_ONLY' or not isinstance(gate.get('receipt_bindings'),dict) or not gate['receipt_bindings']:raise ValueError('Complete bound ORG0 acceptance required')
 if not REQUIRED<=set(gate['receipt_bindings']) or not REQUIRED<=set(gate.get('gates',[])):raise ValueError('Mandatory ORG0 receipt set incomplete')
 for name,digest in gate['receipt_bindings'].items():
  p=Path(name)
  if p.is_absolute() or '..' in p.parts:raise ValueError('Invalid receipt path')
  try:raw=(root/p).read_bytes()
  except OSError as e:raise ValueError('Missing acceptance receipt') from e
  if hashlib.sha256(raw).hexdigest()!=digest:raise ValueError('Acceptance receipt drift')
  if p.suffix=='.json' and json.loads(raw).get('result')!='PASS':raise ValueError('Nonpassing receipt')
 return True
