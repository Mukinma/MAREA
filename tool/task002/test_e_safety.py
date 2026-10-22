import copy,unittest,json
import e_diagnostics as e
from e_compare import canonical_catalog

def fixture():return {'columns':[{'table_schema':'public','table_name':'m','column_name':'a','ordinal_position':1,'dtd_identifier':'1'},{'table_schema':'public','table_name':'m','column_name':'b','ordinal_position':3,'dtd_identifier':'3'}],'tables':[{'acl':'{anon=r/owner,owner=arwd/owner}','owner':'owner'}],'routines':[],'triggers':[{'name':'RI_ConstraintTrigger_c_123','definition':'RI_ConstraintTrigger_c_123 ON public.m','internal':True}],'settings':[{'name':'default_transaction_read_only','setting':'on','source':'command line'}],'database':{'acl':None}}
class EChecks(unittest.TestCase):
 def test_acl_order_does_not_change_grants(self):
  a=fixture();b=copy.deepcopy(a);b['tables'][0]['acl']='{owner=arwd/owner,anon=r/owner}';self.assertEqual(canonical_catalog(a),canonical_catalog(b))
 def test_privilege_expansion_is_detected(self):
  a=fixture();b=copy.deepcopy(a);b['tables'][0]['acl']='{owner=arwd/owner,anon=arwd/owner}';self.assertNotEqual(canonical_catalog(a),canonical_catalog(b))
 def test_column_holes_normalized_but_visible_reorder_detected(self):
  a=fixture();b=copy.deepcopy(a);b['columns'][1]['ordinal_position']=2;b['columns'][1]['dtd_identifier']='2';self.assertEqual(canonical_catalog(a),canonical_catalog(b));b['columns'][0]['ordinal_position']=3;self.assertNotEqual(canonical_catalog(a),canonical_catalog(b))
 def test_internal_ids_only_not_user_trigger_names(self):
  a=fixture();b=copy.deepcopy(a);b['triggers'][0]['name']='RI_ConstraintTrigger_c_999';b['triggers'][0]['definition']='RI_ConstraintTrigger_c_999 ON public.m';self.assertEqual(canonical_catalog(a),canonical_catalog(b));a['triggers'][0]['internal']=False;b['triggers'][0]['internal']=False;self.assertNotEqual(canonical_catalog(a),canonical_catalog(b))
 def test_real_setting_drift_not_erased(self):
  a=fixture();b=copy.deepcopy(a);b['settings'][0]['setting']='off';self.assertNotEqual(canonical_catalog(a),canonical_catalog(b))
 def test_wrong_digest_refused_before_restoration(self):
  c=json.loads((e.RUN/'04-cold-backup-restore.json').read_text());good=c['sources']['a']['db']['backup']['archive_sha256'];self.assertEqual(e.verify_archive('a-db-cold.tar',good),good)
  with self.assertRaises(ValueError):e.restore_volume('a-db-cold.tar',e.OWNER+'-negative-archive-check','0'*64)
  self.assertNotEqual(e.docker('volume','inspect',e.OWNER+'-negative-archive-check',check=False).returncode,0)
 def test_original_namespace_not_a_destination(self):
  c=json.loads((e.RUN/'04-cold-backup-restore.json').read_text());good=c['sources']['a']['db']['backup']['archive_sha256']
  with self.assertRaises(AssertionError):e.restore_volume('a-db-cold.tar','supabase_db_marea-task001-d7522760bb90',good)
 def test_no_boot_for_unapproved_stage(self):
  with self.assertRaises(AssertionError):e.start_db('a','source')
if __name__=='__main__':unittest.main(verbosity=2)
