"""Local synthetic test inputs exercise validation; they are not real panoramas."""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

import check_pilot_media as checker
from worker import gpano_xmp


class PilotMediaTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.file = Path(self.directory.name) / 'private-location-secret.jpg'

    def jpeg(self, xmp=True, orientation=None):
        options = {'xmp': gpano_xmp(256, 128)} if xmp else {}
        if orientation is not None:
            exif = Image.Exif()
            exif[274] = orientation
            options['exif'] = exif
        Image.new('RGB', (256, 128), (120, 80, 40)).save(self.file, **options)

    def rejected(self, code):
        with self.assertRaises(checker.PilotMediaError) as error:
            checker.validate_local_media(self.file)
        self.assertEqual(error.exception.code, code)

    def test_full_gpano_is_decoded_without_backend_or_job_processing(self):
        self.jpeg()
        with patch('worker.Backend', side_effect=AssertionError('backend forbidden')), \
                patch('worker.process_job', side_effect=AssertionError('jobs forbidden')):
            result = checker.validate_local_media(self.file)
        self.assertEqual(result['width'], 256)
        self.assertEqual(result['height'], 128)
        self.assertTrue(result['xmp_validated'])
        self.assertEqual(result['format'], 'JPEG')

    def test_plain_two_to_one_jpeg_is_rejected(self):
        self.jpeg(xmp=False)
        self.rejected('gpano_full_sphere_required')

    def test_png_disguised_as_jpeg_is_rejected(self):
        Image.new('RGB', (256, 128)).save(self.file, format='PNG')
        self.rejected('invalid_jpeg')

    def test_cropped_gpano_is_rejected_by_worker(self):
        xmp = gpano_xmp(512, 256).replace(
            b'CroppedAreaImageWidthPixels="512"', b'CroppedAreaImageWidthPixels="256"')
        Image.new('RGB', (256, 128)).save(self.file, xmp=xmp)
        self.rejected('gpano_full_sphere_required')

    def test_corrupt_xmp_is_rejected_by_worker(self):
        Image.new('RGB', (256, 128)).save(self.file, xmp=b'<broken')
        self.rejected('gpano_full_sphere_required')

    def test_truncated_jpeg_with_gpano_header_is_rejected(self):
        self.jpeg()
        self.file.write_bytes(self.file.read_bytes()[:-40])
        self.rejected('invalid_jpeg')

    def test_exif_rotation_requires_normalization(self):
        self.jpeg(orientation=6)
        self.rejected('image_orientation_not_normalized')

    def test_missing_file_is_reported_without_echoing_its_path(self):
        self.rejected('file_not_found')
        with contextlib.redirect_stdout(io.StringIO()) as stdout:
            code = checker.main(['--file', str(self.file)])
        report = json.loads(stdout.getvalue())
        self.assertEqual(code, 2)
        self.assertEqual(report['error_code'], 'file_not_found')
        self.assertNotIn(str(self.file), stdout.getvalue())
        self.assertNotIn(self.file.name, stdout.getvalue())

    def test_success_json_does_not_claim_optical_quality_or_expose_image_metadata(self):
        self.jpeg()
        with contextlib.redirect_stdout(io.StringIO()) as stdout:
            code = checker.main(['--file', str(self.file)])
        report = json.loads(stdout.getvalue())
        self.assertEqual(code, 0)
        self.assertEqual(report['status'], 'valid_gpano')
        self.assertFalse(report['network_used'])
        self.assertEqual(report['optical_quality'], 'not_evaluated')
        self.assertNotIn(str(self.file), stdout.getvalue())
        self.assertNotIn(self.file.name, stdout.getvalue())
        self.assertNotIn('rdf:', stdout.getvalue())

    def test_missing_dependencies_are_reported_without_importing_validator(self):
        dependencies = {
            'import_dependencies_available': False,
            'missing_python_dependencies': ['Pillow', 'numpy', 'requests'],
        }
        with patch.object(checker, 'dependency_report', return_value=dependencies), \
                patch.object(checker, 'validate_local_media', side_effect=AssertionError), \
                contextlib.redirect_stdout(io.StringIO()) as stdout:
            code = checker.main(['--file', str(self.file)])
        report = json.loads(stdout.getvalue())
        self.assertEqual(code, 2)
        self.assertEqual(report['error_code'], 'missing_dependencies')
        self.assertEqual(report['missing_python_dependencies'], ['Pillow', 'numpy', 'requests'])
        self.assertFalse(report['network_used'])

    def test_missing_photo_tools_do_not_block_gpano_dependencies(self):
        with patch.object(checker.shutil, 'which', return_value=None), \
                contextlib.redirect_stdout(io.StringIO()) as stdout:
            code = checker.main(['--check-dependencies'])
        report = json.loads(stdout.getvalue())
        self.assertEqual(code, 0)
        self.assertTrue(report['import_dependencies_available'])
        self.assertFalse(report['photo_tools_available'])
        self.assertEqual(set(report['photo_tools']), set(checker.PHOTO_TOOLS))
        self.assertTrue(all(not state for state in report['photo_tools'].values()))


if __name__ == '__main__':
    unittest.main()
