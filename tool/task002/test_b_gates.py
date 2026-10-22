import unittest
from unittest.mock import patch,Mock
import b_lab as L
import b_stages
import b_cases
import b_more

class BGateTests(unittest.TestCase):
 def test_missing_or_failed_receipt_stops_stage(self):
  for exists,body in [(False,'{}'),(True,'{"result":"FAIL"}')]:
   with patch.object(L,'require_preflight'),patch.object(L,'RUN') as run:
    run.__truediv__.return_value.exists.return_value=exists;run.__truediv__.return_value.read_text.return_value=body
    with self.assertRaises(RuntimeError):b_stages.require_receipts('stage.json')
 def test_setup_does_not_start_Auth_before_gate(self):
  with patch.object(b_stages,'require_receipts',side_effect=RuntimeError('gate')),patch.object(b_cases.S,'auth_start') as start:
   with self.assertRaisesRegex(RuntimeError,'gate'):b_cases.setup()
   start.assert_not_called()
 def test_compatibility_does_not_start_Storage_before_gate(self):
  with patch.object(b_stages,'require_receipts',side_effect=RuntimeError('gate')),patch.object(b_more.S,'storage_start') as start:
   with self.assertRaisesRegex(RuntimeError,'gate'):b_more.compatibility()
   start.assert_not_called()
 def test_destructive_sql_refused_before_exec(self):
  for query in ['DELETE FROM auth.users;','DELETE FROM public.profiles;','TRUNCATE public.missions;']:
   with patch.object(L,'require_preflight'),patch.object(L.C,'owned'),patch.object(L.C,'docker') as docker:
    with self.assertRaises(RuntimeError):L.sql(L.OWNER+'-a-pg',query,write=True)
    docker.assert_not_called()
 def test_read_only_sql_is_wrapped_and_no_write_escalation(self):
  with patch.object(L,'require_preflight'),patch.object(L.C,'owned'),patch.object(L.C,'docker',return_value=Mock(stdout='1')) as docker:
   L.sql(L.OWNER+'-a-pg','SELECT 1;');q=docker.call_args.kwargs['input']
   self.assertTrue(q.startswith('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;'));self.assertTrue(q.endswith('ROLLBACK;'))
if __name__=='__main__':unittest.main(verbosity=2)
