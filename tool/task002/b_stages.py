"""Additional fail-closed entry gates for fixture/API stage dispatch."""
import json
import b_lab as L
def require_receipts(*names):
 L.require_preflight()
 for name in names:
  p=L.RUN/name
  L.require(p.exists(),'Missing stage receipt '+name)
  L.require(json.loads(p.read_text()).get('result')=='PASS','Unverified stage '+name)
