import unittest
from unittest.mock import patch
from e2a_r2 import require_full_preflight,preflight_before_data
class GateTests(unittest.TestCase):
 def test_no_restore_or_service_before_complete_preflight(self):
  with patch('e2a_r2.RUN') as run:
   run.__truediv__.return_value.exists.return_value=False
   with self.assertRaisesRegex(RuntimeError,'preflight'):require_full_preflight()
 def test_empty_then_full_preflight_precede_data(self):
  events=[]
  preflight_before_data(lambda:events.append('empty') or {'result':'PASS'},lambda:events.append('full') or {'result':'PASS'},lambda:events.append('data'))
  self.assertEqual(events,['empty','full','data'])
 def test_failure_at_either_gate_prevents_data(self):
  for phase in ['empty','full']:
   events=[]
   def gate(name):
    events.append(name)
    return {'result':'FAIL' if name==phase else 'PASS'}
   with self.assertRaises(RuntimeError):preflight_before_data(lambda:gate('empty'),lambda:gate('full'),lambda:events.append('data'))
   self.assertNotIn('data',events)
 def test_recorded_failure_blocks_all_data_and_auth_entrypoints(self):
  import e2a_r2 as lab
  with patch.object(lab,'docker') as docker:
   for call in [lab.bootstrap,lambda:lab.boot('a'),lambda:lab.auth_start('a'),lambda:lab.sql('anything','SELECT 1')]:
    with self.assertRaisesRegex(RuntimeError,'new authorization and new run'):call()
   docker.assert_not_called()
if __name__=='__main__':unittest.main(verbosity=2)
