"""Color-fit timeouts must preserve geometry, cancellation and job deadlines."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from worker import TourError, optimize_project


class PhotoOptimizationTests(unittest.TestCase):
    def run_fit(self, directory, color_error=None, check=lambda: None,
                deadline=1000, fov=39):
        calls = []
        geometry = f'i w720 h1280 v{fov} y0 p0 r0 Eev0\n'
        def command(args, cwd, tool_deadline, _check):
            calls.append((args,tool_deadline))
            if '-n' in args:
                (cwd/'geometry.pto').write_text(geometry)
            else:
                (cwd/'optimized.pto').write_text('partial result' if color_error else geometry.replace('Eev0','Eev1'))
                if color_error:raise TourError(color_error)
        with patch('worker.command',side_effect=command), patch('worker.time.monotonic',return_value=100):
            result=optimize_project([{'hfov':39}],directory,deadline,check)
        return result,calls,geometry

    def test_success_keeps_completed_color_fit(self):
        with tempfile.TemporaryDirectory() as d:
            result,calls,_=self.run_fit(Path(d))
            self.assertTrue(result)
            self.assertIn('Eev1',(Path(d)/'optimized.pto').read_text())
            self.assertEqual(calls[0][1],1000)
            self.assertEqual(calls[1][1],145)

    def test_color_budget_timeout_uses_intact_validated_geometry(self):
        with tempfile.TemporaryDirectory() as d:
            result,_,geometry=self.run_fit(Path(d),'timeout')
            self.assertFalse(result)
            self.assertEqual((Path(d)/'optimized.pto').read_text(),geometry)

    def test_expired_job_does_not_continue_after_color_timeout(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(TourError,'timeout'):
                self.run_fit(Path(d),'timeout',deadline=90)
            self.assertEqual((Path(d)/'optimized.pto').read_text(),'partial result')

    def test_cancellation_during_color_timeout_prevents_fallback(self):
        def cancelled():raise TourError('cancelled')
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(TourError,'cancelled'):
                self.run_fit(Path(d),'timeout',check=cancelled)
            self.assertEqual((Path(d)/'optimized.pto').read_text(),'partial result')

    def test_tool_failures_are_not_treated_as_optional_timeouts(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(TourError,'stitch_failed'):
                self.run_fit(Path(d),'stitch_failed')

    def test_changed_lens_is_rejected_before_color_fitting(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(TourError,'inconsistent_camera_geometry'):
                self.run_fit(Path(d),fov=180)
            self.assertFalse((Path(d)/'optimized.pto').exists())
