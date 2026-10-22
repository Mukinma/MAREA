"""Pure fail-closed acceptance validation. Never treats stale PASS as permission."""
import hashlib,json
from pathlib import Path
def validate_org0_gate(root,gate):
 root=Path(root)
 if any(root.glob('*ORG0-ACCEPTANCE-INVALIDATED*.json')):raise ValueError('ORG0 acceptance invalidated')
 if gate.get('result')!='PASS' or gate.get('stage')!='ORG0_ONLY' or not isinstance(gate.get('receipt_bindings'),dict) or not gate['receipt_bindings']:raise ValueError('Complete bound ORG0 acceptance required')
 for name,digest in gate['receipt_bindings'].items():
  p=Path(name)
  if p.is_absolute() or '..' in p.parts:raise ValueError('Invalid receipt path')
  try:raw=(root/p).read_bytes()
  except OSError as e:raise ValueError('Missing acceptance receipt') from e
  if hashlib.sha256(raw).hexdigest()!=digest:raise ValueError('Acceptance receipt drift')
  if p.suffix=='.json' and json.loads(raw).get('result')!='PASS':raise ValueError('Nonpassing receipt')
 return True
