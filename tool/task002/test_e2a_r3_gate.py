import unittest
from unittest.mock import patch
from e2a_r3 import require_full_preflight,preflight_before_data
class GateTests(unittest.TestCase):
 def test_no_restore_or_service_before_complete_preflight(self):
  with patch('e2a_r3.RUN') as run:
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
if __name__=='__main__':unittest.main(verbosity=2)
