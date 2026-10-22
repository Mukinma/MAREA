import unittest
from s0_sql_policy import validate_write
from e2a_isolation import IsolationError
DDL="BEGIN;CREATE TRIGGER aa_s0_truncate BEFORE TRUNCATE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION collaboration.s0_deny_mutation();COMMIT;\n"
class PolicyTests(unittest.TestCase):
 def test_exact_guard_and_rollback_accepted(self):
  self.assertTrue(validate_write(DDL,DDL));self.assertTrue(validate_write(DDL.rsplit('COMMIT;',1)[0]+'ROLLBACK;',DDL))
 def test_real_truncation_never_allowed(self):
  for q in ['TRUNCATE storage.objects;','BEGIN;truncate/**/auth.users;COMMIT;',DDL+'TRUNCATE public.profiles;',DDL.replace('CREATE TRIGGER aa_s0_truncate BEFORE TRUNCATE','TRUNCATE')]:
   with self.assertRaises(IsolationError):validate_write(q,DDL)
 def test_account_deletion_still_denied(self):
  for table in ['auth.users','public.profiles']:
   with self.assertRaises(IsolationError):validate_write('BEGIN; DELETE FROM '+table+';COMMIT;',DDL)
 def test_arbitrary_trigger_not_accepted(self):
  with self.assertRaises(IsolationError):validate_write(DDL.replace('storage.objects','auth.users'),DDL)
if __name__=='__main__':unittest.main(verbosity=2)
