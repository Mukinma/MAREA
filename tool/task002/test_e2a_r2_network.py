import copy,json,unittest
from pathlib import Path
from e2a_r2_network import validate_runtime
from e2a_isolation import IsolationError
class RuntimeTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.x=json.loads((Path(__file__).resolve().parents[2]/'docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation/09-live-verified-capture.json').read_text())
 def test_empty_shared_namespace_passes_runtime_checks(self):self.assertEqual(validate_runtime(self.x['shared'],self.x['anchor']['inspect'],{5432})['result'],'PASS')
 def test_loopback_listener_only_on_allowed_port(self):
  x=copy.deepcopy(self.x['shared']);x['kernel']['proc']['/proc/net/tcp']+='0: 0100007F:1538 00000000:0000 0A\n'
  self.assertEqual(validate_runtime(x,self.x['anchor']['inspect'],{5432})['listeners'],[5432])
  with self.assertRaises(IsolationError):validate_runtime(x,self.x['anchor']['inspect'],{9999})
 def test_wildcard_or_external_socket_rejected(self):
  for addr in ['00000000','0100000A']:
   x=copy.deepcopy(self.x['shared']);x['kernel']['proc']['/proc/net/tcp']+=f'0: {addr}:1538 00000000:0000 0A\n'
   with self.assertRaises(IsolationError):validate_runtime(x,self.x['anchor']['inspect'],{5432})
 def test_missing_or_inconsistent_views_rejected(self):
  x=copy.deepcopy(self.x['shared']);x['kernel']['proc'].pop('/proc/net/udp6')
  with self.assertRaises(IsolationError):validate_runtime(x,self.x['anchor']['inspect'],{5432})
if __name__=='__main__':unittest.main(verbosity=2)
