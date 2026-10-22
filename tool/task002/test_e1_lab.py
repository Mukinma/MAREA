"""Non-mutating guards for the narrowly authorized E1 executor."""
import unittest
from pathlib import Path
from unittest.mock import patch
import e1_lab as e

class E1Guards(unittest.TestCase):
    def test_original_volume_and_foreign_owner_refused(self):
        for name in ['supabase_db_marea-task001-d7522760bb90', 'task002-e-20261019t051800z-a-work-db', e.OWNER+'-c-db']:
            with self.assertRaises(AssertionError):e.destination(name)

    def test_exact_new_destinations_only(self):
        for a in ['a','b']:
            for kind in ['db','storage','postgres']:e.destination(f'{e.OWNER}-{a}-{kind}')

    def test_source_still_has_barrier_and_rollback(self):
        self.assertEqual(e.digest(e.PROPOSAL),e.PROPOSAL_SHA)
        s=e.PROPOSAL.read_text();self.assertIn(e.BARRIER,s);self.assertTrue(s.endswith('ROLLBACK;\n'))

    def test_separate_executable_is_transactional_and_checks_digest_before_commit(self):
        fixture={'rows':[{'table':'public.missions','rows':6,'sha256':'a'*64}]}
        s=e.executable(fixture)
        self.assertIn('BEGIN READ WRITE;',s);self.assertTrue(s.endswith('COMMIT;\n'))
        self.assertNotIn(e.BARRIER,s);self.assertIn('E1_LEGACY_DIGEST_CHANGED',s)
        self.assertLess(s.index('E1_LEGACY_DIGEST_CHANGED'),s.index('COMMIT;\n'))
        self.assertIn('CREATE TABLE collaboration.persons',s)
        for forbidden in ['ALTER TABLE public.missions','DROP CONSTRAINT','CREATE FUNCTION','CREATE OR REPLACE FUNCTION','CREATE POLICY']:
            self.assertNotIn(forbidden,s)

    def test_owned_operation_refuses_network_before_exec(self):
        fake={'Config':{'Labels':{e.LABEL:e.OWNER}},'Image':e.PG,'HostConfig':{'NetworkMode':'bridge'}}
        with patch.object(e,'inspect',return_value=fake):
            with self.assertRaises(AssertionError):e.owned(e.OWNER+'-a-postgres')

    def test_readonly_digest_order_explicit(self):
        s=e.row_query('public.missions','public.missions')
        self.assertIn('COLLATE "C"',s);self.assertIn('sha256',s)

    def test_helpers_refuse_original_before_running_any_docker(self):
        with patch.object(e,'docker',side_effect=RuntimeError('Must not run Docker')):
            with self.assertRaises(AssertionError):e.helper('pass','supabase_storage_marea-task001-d7522760bb90')

    def test_regclass_visible_auth_name_keeps_strict_comparison(self):
        import copy,json,types
        b={'catalog':{'tables':[],'constraints':[],'triggers':[]},'rows':[],'sequences':[],
           'extra':{'schemas':[],'indexes':[]}}
        a=copy.deepcopy(b)
        a['catalog']['triggers']=[{'relation':'users','internal':True,'name':'new1'},
                                  {'relation':'users','internal':True,'name':'new2'}]
        a['extra']['indexes']=[{'schemaname':'collaboration'},{'schemaname':'collaboration'}]
        answer={'relation':'users','names':['new1','new2']}
        with patch.object(e,'sql',return_value=types.SimpleNamespace(stdout=json.dumps(answer))):
            self.assertTrue(e.legacy_equal(b,a,'fixture')['all_old_catalog_and_extra_definitions_equal'])
            a['catalog']['triggers'].append({'relation':'users','internal':False,'name':'unexpected'})
            with self.assertRaises(AssertionError):e.legacy_equal(b,a,'fixture')

if __name__=='__main__':unittest.main(verbosity=2)
