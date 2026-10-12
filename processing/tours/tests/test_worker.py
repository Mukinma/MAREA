import unittest
import tempfile
from pathlib import Path
from PIL import Image
import numpy as np
from worker import TourError, validate_manifest, validate_gpano, connected_control_points, validate_alpha_coverage, process_job

OWNER='11111111-1111-4111-8111-111111111111'
CAP='22222222-2222-4222-8222-222222222222'
FRAME='33333333-3333-4333-8333-333333333333'
def manifest():
    return {'mode':'import','frames':[{'id':FRAME,'path':f'{OWNER}/{CAP}/{FRAME}.jpg','width':4096,'height':2048,'yaw':0,'pitch':0,'roll':0,'hfov':360,'vfov':180}]}
class WorkerTests(unittest.TestCase):
    def test_arbitrary_input_path_is_rejected(self):
        m=manifest();m['frames'][0]['path']='../../secret.jpg'
        with self.assertRaises(TourError):validate_manifest(m,OWNER,CAP)
    def test_real_dimensions_must_match_manifest(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'image.jpg';Image.new('RGB',(128,64)).save(p)
            with self.assertRaises(TourError):validate_manifest(manifest(),OWNER,CAP,[p])
    def test_two_to_one_jpeg_does_not_prove_gpano(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'image.jpg';Image.new('RGB',(128,64)).save(p)
            with self.assertRaises(TourError):validate_gpano(p)
    def test_fake_gpano_outside_xmp_is_rejected(self):
        metadata=b'GPano:ProjectionType="equirectangular" GPano:FullPanoWidthPixels="128" GPano:FullPanoHeightPixels="64" GPano:CroppedAreaImageWidthPixels="128" GPano:CroppedAreaImageHeightPixels="64" GPano:CroppedAreaLeftPixels="0" GPano:CroppedAreaTopPixels="0"'
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'image.jpg';Image.new('RGB',(128,64)).save(p)
            with p.open('ab') as file:file.write(metadata)
            with self.assertRaises(TourError):validate_gpano(p)
    def test_cropped_gpano_is_rejected(self):
        xmp=b'<rdf:Description xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:GPano="http://ns.google.com/photos/1.0/panorama/" GPano:ProjectionType="equirectangular" GPano:FullPanoWidthPixels="128" GPano:FullPanoHeightPixels="64" GPano:CroppedAreaImageWidthPixels="64" GPano:CroppedAreaImageHeightPixels="64" GPano:CroppedAreaLeftPixels="0" GPano:CroppedAreaTopPixels="0"/>'
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'image.jpg';Image.new('RGB',(64,64)).save(p,xmp=xmp)
            with self.assertRaises(TourError):validate_gpano(p)
    def test_full_gpano_is_accepted(self):
        xmp=b'<rdf:Description xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:GPano="http://ns.google.com/photos/1.0/panorama/" GPano:ProjectionType="equirectangular" GPano:FullPanoWidthPixels="128" GPano:FullPanoHeightPixels="64" GPano:CroppedAreaImageWidthPixels="128" GPano:CroppedAreaImageHeightPixels="64" GPano:CroppedAreaLeftPixels="0" GPano:CroppedAreaTopPixels="0"/>'
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'image.jpg';Image.new('RGB',(128,64)).save(p,xmp=xmp)
            self.assertEqual(validate_gpano(p),(128,64))
    def test_disconnected_control_point_graph_is_rejected(self):
        with self.assertRaises(TourError):connected_control_points('c n0 N1 x2 y3 X4 Y5 t0\n',3)
        connected_control_points('c n0 N1 x2 y3 X4 Y5 t0\nc n1 N2 x2 y3 X4 Y5 t0\n',3)
    def test_actual_remapped_alpha_hole_is_rejected(self):
        alpha=np.ones((180,360),dtype=np.uint8)*255;alpha[50:90,100:150]=0
        with self.assertRaises(TourError):validate_alpha_coverage([alpha])
    def test_union_of_remapped_alpha_covers_sphere(self):
        a=np.zeros((180,360),dtype=np.uint8);b=a.copy();a[:,:180]=255;b[:,180:]=255
        validate_alpha_coverage([a,b])
    def test_cancellation_before_write_never_uploads(self):
        class Backend:
            def current(self,*_):return False
            def upload(self,*_):raise AssertionError('cancelled write')
        self.assertFalse(process_job({'id':FRAME,'lease_id':CAP,'owner_id':OWNER,'capture_id':CAP,'manifest':manifest()},Backend()))

class ImportPipelineTests(unittest.TestCase):
    """Executes actual JPEG decoding, GPano validation, resizing and serialization.
    Only external Supabase I/O is substituted; this does not exercise Hugin."""
    def backend(self, input_file, cancel_after_upload=False):
        import shutil
        class LocalStorage:
            def __init__(self):self.assets={};self.active=True;self.result=None;self.error=None;self.guard=False
            def current(self,*_):return self.active
            def download(self,path,local):shutil.copyfile(input_file,local)
            def begin_write(self,*_):self.guard=self.active;return self.active
            def end_write(self,*_):self.guard=False
            def upload(self,path,file):
                self.assets[path]=file.read_bytes()
                if cancel_after_upload:self.active=False
            def remove(self,paths):
                for path in paths:self.assets.pop(path,None)
            def finish(self,job,lease,state,result=None,error=None):
                if not self.active:return False
                self.result=result;self.error=error;return True
        return LocalStorage()
    def fixture(self,directory):
        path=Path(directory)/'input.jpg'
        xmp=b'<rdf:Description xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:GPano="http://ns.google.com/photos/1.0/panorama/" GPano:ProjectionType="equirectangular" GPano:FullPanoWidthPixels="512" GPano:FullPanoHeightPixels="256" GPano:CroppedAreaImageWidthPixels="512" GPano:CroppedAreaImageHeightPixels="256" GPano:CroppedAreaLeftPixels="0" GPano:CroppedAreaTopPixels="0"/>'
        Image.new('RGB',(512,256),(120,80,40)).save(path,xmp=xmp)
        m=manifest();m['frames'][0].update(width=512,height=256)
        return path,{'id':FRAME,'lease_id':CAP,'owner_id':OWNER,'capture_id':CAP,'manifest':m}
    def test_import_generates_full_gpano_outputs_with_bound_owner_job_paths(self):
        with tempfile.TemporaryDirectory() as d:
            path,job=self.fixture(d);backend=self.backend(path)
            self.assertTrue(process_job(job,backend))
            self.assertEqual(set(backend.assets),{f'{OWNER}/jobs/{FRAME}/{name}.jpg' for name in ['panorama','preview','thumbnail']})
            for name,size in [('panorama',(4096,2048)),('preview',(2048,1024)),('thumbnail',(512,256))]:
                output=Path(d)/f'{name}.jpg';output.write_bytes(backend.assets[f'{OWNER}/jobs/{FRAME}/{name}.jpg'])
                self.assertEqual(validate_gpano(output),size)
            self.assertFalse(backend.guard)
    def test_lost_committed_finish_response_retains_ready_media(self):
        with tempfile.TemporaryDirectory() as d:
            path,job=self.fixture(d);backend=self.backend(path)
            original=backend.finish
            def lost(job,lease,state,result=None,error=None):
                original(job,lease,state,result,error)
                if state=='succeeded':raise TourError('network')
                return True
            backend.finish=lost
            backend.receipt=lambda *args: {'committed':True,'result':backend.result}
            self.assertTrue(process_job(job,backend))
            self.assertEqual(len(backend.assets),3)
            self.assertIsNotNone(backend.result)
    def test_unknown_finish_receipt_never_deletes_possibly_committed_media(self):
        with tempfile.TemporaryDirectory() as d:
            path,job=self.fixture(d);backend=self.backend(path)
            def lost(*args,**kwargs):raise TourError('network')
            backend.finish=lost;backend.receipt=lost
            self.assertFalse(process_job(job,backend))
            self.assertEqual(len(backend.assets),3)
    def test_cancellation_during_upload_removes_all_partial_assets(self):
        with tempfile.TemporaryDirectory() as d:
            path,job=self.fixture(d);backend=self.backend(path,True)
            self.assertFalse(process_job(job,backend));self.assertEqual(backend.assets,{})
            self.assertIsNone(backend.result);self.assertFalse(backend.guard)


class HostedVoidRpcTests(unittest.TestCase):
    def test_storage_guard_void_response_is_not_decoded_as_json(self):
        import requests
        from worker import Backend
        response=requests.Response();response.status_code=204;response._content=b''
        backend=Backend('https://test.supabase.co','test-key')
        backend.request=lambda *args,**kwargs:response
        self.assertIsNone(backend.rpc('tours_end_output_write',{'p_job':FRAME,'p_lease':CAP}))

class StreamingFailureTests(unittest.TestCase):
    def test_interrupted_partial_download_is_transient_and_response_closed(self):
        import requests
        from worker import Backend
        class Interrupted:
            closed=False
            def iter_content(self,_):
                yield b'partial JPEG bytes'
                raise requests.ConnectionError('interrupted stream')
            def close(self):self.closed=True
        response=Interrupted();backend=Backend('https://test.supabase.co','test-key')
        backend.request=lambda *args,**kwargs:response
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(TourError) as error:
                backend.download('owner/capture/frame.jpg',Path(d)/'input.jpg')
            self.assertEqual(error.exception.code,'network')
        self.assertTrue(response.closed)

if __name__=='__main__':unittest.main()
