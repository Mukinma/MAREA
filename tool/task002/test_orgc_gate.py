import unittest,tempfile,json,hashlib
from pathlib import Path
from orgc_gate import validate_org0_gate
REQUIRED=['05-ORG0-installation.json','07-ORG0-GREEN.json','08-ORG0-concurrency-states.json','08b-ORG0-expiry-integrity.json','08c-ORG0-legacy-marker-regression.json','09b-ORG0-conservation-final.json','10-ORG0-recovery.json']
class AcceptanceGate(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);self.addCleanup(self.tmp.cleanup);self.proof=self.root/'proof.json';self.proof.write_text('{"result":"PASS"}');
  for name in REQUIRED:(self.root/name).write_text('{"result":"PASS"}')
  self.proof=self.root/REQUIRED[0];self.gate={'result':'PASS','stage':'ORG0_ONLY','gates':REQUIRED,'receipt_bindings':{name:hashlib.sha256((self.root/name).read_bytes()).hexdigest() for name in REQUIRED}}
 def test_pass_requires_bound_receipt(self):self.assertTrue(validate_org0_gate(self.root,self.gate))
 def test_invalidated_acceptance_is_rejected(self):
  (self.root/'12b-ORG0-ACCEPTANCE-INVALIDATED.json').write_text('{"result":"INVALIDATED"}')
  with self.assertRaises(ValueError):validate_org0_gate(self.root,self.gate)
 def test_changed_proof_is_rejected(self):
  self.proof.write_text('{"result":"FAIL"}')
  with self.assertRaises(ValueError):validate_org0_gate(self.root,self.gate)
 def test_missing_bindings_are_rejected(self):
  with self.assertRaises(ValueError):validate_org0_gate(self.root,{'result':'PASS','stage':'ORG0_ONLY'})
 def test_incomplete_pass_set_is_rejected(self):
  partial={'result':'PASS','stage':'ORG0_ONLY','gates':[REQUIRED[0]],'receipt_bindings':{REQUIRED[0]:self.gate['receipt_bindings'][REQUIRED[0]]}}
  with self.assertRaises(ValueError):validate_org0_gate(self.root,partial)
 def test_missing_file_is_rejected(self):
  self.proof.unlink()
  with self.assertRaises(ValueError):validate_org0_gate(self.root,self.gate)
if __name__=='__main__':unittest.main()
