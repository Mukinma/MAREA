import unittest
from unittest.mock import patch
import subprocess
from pathlib import Path
from local_runner import docker_arguments, verify_result, container_stopped, cycle

JOB={'id':'11111111-1111-4111-8111-111111111111','lease_id':'22222222-2222-4222-8222-222222222222'}
class RunnerTests(unittest.TestCase):
    def test_container_zero_does_not_imply_ready(self):
        class DB:
            def receipt(self,*args):return {'committed':False,'result':None}
            def current(self,*args):return False
        self.assertEqual(verify_result(DB(),JOB,0)['state'],'not_ready')
    def test_database_receipt_confirms_result_even_with_lost_process_response(self):
        class DB:
            def receipt(self,*args):return {'committed':True,'result':{'panorama_path':'confirmed.jpg'}}
        self.assertEqual(verify_result(DB(),JOB,137)['state'],'ready')
    def test_daemon_failure_does_not_prove_container_stopped(self):
        with patch('local_runner.subprocess.run',return_value=subprocess.CompletedProcess([],1,'','Cannot connect to Docker daemon')):
            self.assertFalse(container_stopped('own-container'))
    def test_removed_container_is_safe_to_requeue(self):
        with patch('local_runner.subprocess.run',return_value=subprocess.CompletedProcess([],1,'','Error: No such object: own-container')):
            self.assertTrue(container_stopped('own-container'))
    def test_still_running_container_is_not_safe_to_requeue(self):
        with patch('local_runner.subprocess.run',return_value=subprocess.CompletedProcess([],0,'true\n','')):
            self.assertFalse(container_stopped('own-container'))
    def test_expired_cleanup_entry_cannot_delete_new_ready_outputs(self):
        class DB:
            removed=[]
            def rpc(self,name,payload):
                if name=='tours_claim_cleanup':return [{'id':'old-a','lease_id':'lease-a','paths':['old-a.jpg']},{'id':'new-ready','lease_id':'expired','paths':['ready.jpg']}]
                if name=='tours_renew_cleanup':return payload['p_job']=='old-a'
                if name=='tours_finish_cleanup':return True
                if name=='tours_claim_jobs':return []
                raise AssertionError(name)
            def remove(self,paths):self.removed.extend(paths)
        backend=DB()
        with patch('local_runner.Backend',return_value=backend):
            cycle(Path('/private/test.env'),'image',{'SUPABASE_URL':'https://test.supabase.co','SUPABASE_SERVICE_ROLE_KEY':'test'})
        self.assertEqual(backend.removed,['old-a.jpg'])
    def test_failed_cleanup_finalization_prevents_processing_claim(self):
        class DB:
            def rpc(self,name,payload):
                if name=='tours_claim_cleanup':return [{'id':'old','lease_id':'lease','paths':['old.jpg']}]
                if name=='tours_renew_cleanup':return True
                if name=='tours_finish_cleanup':return False
                if name=='tours_claim_jobs':raise AssertionError('claimed after lost cleanup lease')
            def remove(self,_):pass
        from worker import TourError
        with patch('local_runner.Backend',return_value=DB()):
            with self.assertRaises(TourError):
                cycle(Path('/private/test.env'),'image',{'SUPABASE_URL':'https://test.supabase.co','SUPABASE_SERVICE_ROLE_KEY':'test'})
    def test_production_container_limits_and_credentials_are_file_only(self):
        args=docker_arguments(JOB,Path('/private/test.env'),'image@sha256:abc','x'*40,'unique')
        self.assertIn('linux/amd64',args)
        self.assertEqual(args[args.index('--cpus')+1],'4')
        self.assertEqual(args[args.index('--memory')+1],'8g')
        self.assertNotIn('x'*40,' '.join(args))
        self.assertIn('/private/test.env',args)
if __name__=='__main__':unittest.main()
