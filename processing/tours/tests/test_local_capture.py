"""Offline capture processing boundaries; no credentials or Supabase calls."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import uuid

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from process_local_capture import capture_inputs, process_capture, control_point_groups
from worker import TourError, stitch_photos


def capture(photos, count=6):
    frames=[]
    for i in range(count):
        ident=str(uuid.uuid4())
        Image.new('RGB',(64,64),(30+i,70,100)).save(photos/(ident+'.jpg'))
        frames.append({'id':ident,'local_path':'/phone/private/'+ident+'.jpg',
            'width':64,'height':64,'sensor_yaw':10+i,'pitch':0,'roll':1,
            'hfov':70,'vfov':70,'pose_status':'needs_reference','pose_session':f'session-{i//3}',
            'cube_guide_version':1,'cube_guide_step':'not-a-measured-angle'})
    return {'frames':frames,'mode':'photos'}


class LocalCaptureTests(unittest.TestCase):
    def test_all_selection_keeps_extra_photos_after_the_guide_without_inventing_poses(self):
        with tempfile.TemporaryDirectory() as d:
            directory=Path(d);record=capture(directory)
            extra=record['frames'][-1]
            extra.pop('cube_guide_version');extra.pop('cube_guide_step')
            with self.assertRaises(TourError):capture_inputs(record,directory,'guide')
            manifest,files,_=capture_inputs(record,directory,'all')
            self.assertEqual(len(files),6)
            self.assertEqual(manifest['frames'][-1]['yaw'],extra['sensor_yaw'])
            extra['sensor_yaw']=None
            with self.assertRaises(TourError):capture_inputs(record,directory,'all')

    def test_diagnostic_counts_only_real_image_matches(self):
        with tempfile.TemporaryDirectory() as d:
            project=Path(d)/'clean.pto'
            project.write_text('c n0 N1 x1 y1 X2 Y2 t0\nc n1 N2 x1 y1 X2 Y2 t1\n')
            self.assertEqual(control_point_groups(project,3),
                             {'groups':[[1,2],[3]],'unmatched_photos':[3]})
    def test_resumed_native_sessions_initialize_from_real_samples_not_guide_squares(self):
        with tempfile.TemporaryDirectory() as d:
            directory=Path(d); record=capture(directory)
            manifest,files,provenance=capture_inputs(record,directory)
            self.assertEqual([f['yaw'] for f in manifest['frames']],[10,11,12,13,14,15])
            self.assertTrue(all(f.exists() for f in files))
            self.assertEqual(len({p['motion_session'] for p in provenance}),2)
            self.assertTrue(all(p['yaw_initialization']=='native_session_relative' for p in provenance))
            self.assertTrue(all('yaw' not in f for f in record['frames']))
            self.assertTrue(all('cube_guide_step' not in f for f in manifest['frames']))

    def test_no_pose_or_camera_geometry_is_fabricated(self):
        with tempfile.TemporaryDirectory() as d:
            directory=Path(d); record=capture(directory)
            for change in [{'sensor_yaw':None},{'pose_status':'unavailable'},
                           {'pose_session':None},{'hfov':None}]:
                with self.subTest(change=change):
                    modified=json.loads(json.dumps(record))
                    modified['frames'][0].update(change)
                    with self.assertRaises(TourError):capture_inputs(modified,directory)

    def test_paths_and_original_dimensions_are_checked_before_tools_run(self):
        with tempfile.TemporaryDirectory() as d:
            directory=Path(d); record=capture(directory)
            for change in [{'local_path':'https://example.org/file.jpg'},
                           {'id':'../../outside'},{'width':128}]:
                with self.subTest(change=change):
                    modified=json.loads(json.dumps(record));modified['frames'][0].update(change)
                    with self.assertRaises(TourError):capture_inputs(modified,directory)

    def test_existing_output_and_original_folders_are_never_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            directory=Path(d); photos=directory/'photos';photos.mkdir()
            record=capture(photos);source=photos/'session.json';source.write_text(json.dumps(record))
            existing=directory/'existing';existing.mkdir();sentinel=existing/'keep';sentinel.write_text('unchanged')
            for output in [existing,photos,photos/'nested',directory]:
                with self.assertRaises(TourError):process_capture(source,output)
            self.assertEqual(sentinel.read_text(),'unchanged')

    def test_offline_alignment_is_explicit_and_default_pipeline_keeps_measured_mode(self):
        with tempfile.TemporaryDirectory() as d:
            directory=Path(d); record=capture(directory)
            manifest,files,_=capture_inputs(record,directory)
            for feature_alignment in [False,True]:
                commands=[]
                def command(args,cwd,deadline,check):
                    commands.append(args)
                    if args[0]=='cpclean':
                        (cwd/'clean.pto').write_text('\n'.join(f'c n{i} N{i+1} x1 y1 X2 Y2 t0' for i in range(5)))
                    if args[0]=='autooptimiser' and '-p' in args:
                        (cwd/'pairwise.pto').write_text('pairwise initialization')
                    elif args[0]=='autooptimiser':raise TourError('stop_test_after_alignment_selection')
                with patch('worker.command',side_effect=command):
                    with self.assertRaises(TourError):
                        stitch_photos(manifest['frames'],files,directory,float('inf'),lambda:None,
                                      feature_alignment=feature_alignment)
                self.assertIn('--allpairs' if feature_alignment else '--multirow',commands[0])
                self.assertEqual('--fullscale' in commands[0],feature_alignment)
                self.assertIn('-n',commands[-1])
                self.assertEqual(any(c[0]=='autooptimiser' and '-p' in c for c in commands),feature_alignment)


if __name__=='__main__':unittest.main()
