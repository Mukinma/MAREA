import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'publish_local_image.sh'

class PublishImageTests(unittest.TestCase):
    def test_changed_local_tag_cannot_publish_an_unverified_image(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            record = root / 'pilot-image.json'
            record.write_text(json.dumps({'image': 'sha256:validated'}))
            log = root / 'google-calls'
            docker = root / 'docker'
            docker.write_text('#!/bin/sh\ncase "$*" in\n*Architecture*) echo amd64;;\n*Id*) echo sha256:changed;;\nesac\n')
            google = root / 'gcloud'
            google.write_text(f'#!/bin/sh\necho called >> "{log}"\necho True\n')
            docker.chmod(0o700)
            google.chmod(0o700)
            result = subprocess.run(['bash', str(SCRIPT)], env={**os.environ,
                'PATH': str(root) + ':' + os.environ['PATH'],
                'TOUR_PILOT_RECORD': str(record)}, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('validated', result.stderr)
            self.assertFalse(log.exists(), 'Identity mismatch must stop before Google operations')

if __name__ == '__main__':
    unittest.main()
