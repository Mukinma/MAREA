"""Process a private COPY of phone photos, without Supabase, queues or uploads.

Resumed native motion sessions have independent yaw origins. Their measured
angles only initialize Hugin; all-pairs control points and visual alignment must
recover the common geometry. Guide squares are never used as measured poses.
"""
from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import shutil
import time
import uuid

from PIL import Image
from worker import (ALLOWED_TOOLS, TourError, export_results, stitch_photos,
                    validate_gpano, validate_manifest)


def capture_inputs(capture, photos, selection='guide'):
    """Resolve only local UUID JPEG basenames, never Android paths or URLs."""
    if not isinstance(capture, dict) or not isinstance(capture.get('frames'), list):
        raise TourError('invalid_capture')
    frames = capture['frames']
    if selection == 'guide':
        frames = [f for f in frames if isinstance(f, dict) and f.get('cube_guide_version') == 1]
    elif selection == 'latest-session':
        sessions = [f.get('pose_session') for f in frames if isinstance(f, dict) and f.get('pose_session')]
        if not sessions:
            raise TourError('motion_session_required')
        frames = [f for f in frames if isinstance(f, dict) and f.get('pose_session') == sessions[-1]]
    elif selection == 'ready':
        frames = [f for f in frames if isinstance(f, dict) and f.get('pose_status', 'ready') == 'ready']
    elif selection == 'all':
        if not all(isinstance(frame, dict) for frame in frames):
            raise TourError('invalid_capture')
    else:
        raise TourError('invalid_selection')
    if not 6 <= len(frames) <= 96:
        raise TourError('insufficient_frames')
    owner, run = str(uuid.uuid4()), str(uuid.uuid4())
    prepared, files, provenance = [], [], []
    photos = photos.resolve(strict=True)
    for frame in frames:
        raw_path = frame.get('local_path')
        if not isinstance(raw_path, str) or '\\' in raw_path or '://' in raw_path:
            raise TourError('invalid_input_path')
        name = raw_path.rsplit('/', 1)[-1]
        try:
            if name != str(uuid.UUID(frame['id'])) + '.jpg':
                raise ValueError()
        except (KeyError, ValueError, TypeError):
            raise TourError('invalid_input_path')
        image = (photos / name).resolve(strict=True)
        if image.parent != photos or not image.is_file():
            raise TourError('invalid_input_path')
        if frame.get('pose_status') not in (None, 'ready', 'needs_reference'):
            raise TourError('measured_pose_required')
        relative = frame.get('pose_status') == 'needs_reference'
        yaw = frame.get('sensor_yaw') if relative else frame.get('yaw')
        if relative and not frame.get('pose_session'):
            raise TourError('motion_session_required')
        if not isinstance(yaw, (int, float)) or isinstance(yaw, bool) or not math.isfinite(yaw):
            raise TourError('measured_pose_required')
        initial = {key: frame.get(key) for key in ('id', 'width', 'height', 'pitch', 'roll', 'hfov', 'vfov')}
        initial.update(yaw=(yaw + 180) % 360 - 180, path=f'{owner}/{run}/{frame["id"]}.jpg')
        prepared.append(initial)
        files.append(image)
        provenance.append({'id': frame['id'], 'motion_session': frame.get('pose_session'),
                           'yaw_initialization': 'native_session_relative' if relative else 'saved_measured_pose'})
    manifest = {'mode': 'photos', 'frames': prepared}
    validate_manifest(manifest, owner, run, files)
    return manifest, files, provenance


def configure_tools(directory=None):
    if directory is not None:
        directory = Path(directory).resolve(strict=True)
        os.environ['PATH'] = str(directory) + os.pathsep + os.environ.get('PATH', '')
    missing = sorted(tool for tool in ALLOWED_TOOLS if not shutil.which(tool))
    if missing:
        raise TourError('missing_tools:' + ','.join(missing))


def process_capture(capture_file, output, *, photos=None, tools=None, selection='guide', timeout=840):
    capture_file = Path(capture_file).resolve(strict=True)
    photos = Path(photos or capture_file.parent).resolve(strict=True)
    output = Path(output).resolve()
    # Never reuse or overwrite originals, previous attempts, or existing results.
    if output == photos or output in photos.parents or photos in output.parents or output.exists():
        raise TourError('new_output_directory_required')
    capture = json.loads(capture_file.read_text(encoding='utf-8-sig'))
    manifest, files, provenance = capture_inputs(capture, photos, selection)
    configure_tools(tools)
    output.mkdir(parents=True, exist_ok=False)
    (output / 'initialization.json').write_text(json.dumps({
        'scope': 'offline_local_copy', 'selection': selection,
        'orientation_role': 'initial_guess; visual control points establish common geometry',
        'frames': provenance, 'manifest': manifest,
    }, indent=2), encoding='utf-8')
    started = time.monotonic()
    report = {'scope': 'offline_local_copy', 'frames': len(files), 'ready': False,
              'uploaded': False, 'published': False, 'visual_alignment': True}
    try:
        source = stitch_photos(manifest['frames'], files, output,
                               started + timeout, lambda: None, feature_alignment=True)
        exports = export_results(source, output)
        dimensions = [validate_gpano(path) for path in exports]
        report.update(ready=True, outputs=[p.name for p in exports], dimensions=dimensions)
    except TourError as error:
        report['error'] = error.code
        if error.code == 'disconnected_control_points':
            report['connections'] = control_point_groups(output / 'clean.pto', len(files))
    except (OSError, ValueError) as error:
        report['error'] = type(error).__name__
    finally:
        report['seconds'] = round(time.monotonic() - started, 2)
        (output / 'result.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report


def control_point_groups(project, count):
    import re
    graph = [set() for _ in range(count)]
    for line in project.read_text(encoding='utf-8', errors='replace').splitlines():
        if not line.startswith('c '):
            continue
        a, b = re.search(r'\bn(\d+)\b', line), re.search(r'\bN(\d+)\b', line)
        kind = re.search(r'\bt(\d+)\b', line)
        if not a or not b or (kind and kind[1] != '0'):
            continue
        a, b = int(a[1]), int(b[1])
        if a >= count or b >= count:
            continue
        graph[a].add(b); graph[b].add(a)
    visited, groups = set(), []
    for first in range(count):
        if first in visited:
            continue
        group, pending = set(), [first]
        while pending:
            node = pending.pop()
            if node in group:
                continue
            group.add(node); visited.add(node); pending.extend(graph[node] - group)
        groups.append(sorted(i + 1 for i in group))
    return {'groups': sorted(groups, key=len, reverse=True),
            'unmatched_photos': [i + 1 for i, edges in enumerate(graph) if not edges]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--photos', type=Path)
    parser.add_argument('--tools', type=Path)
    parser.add_argument('--selection', choices=('guide', 'latest-session', 'ready', 'all'), default='guide')
    args = parser.parse_args()
    try:
        result = process_capture(args.capture, args.output, photos=args.photos,
                                 tools=args.tools, selection=args.selection)
    except (TourError, OSError, ValueError) as error:
        result = {'ready': False, 'uploaded': False, 'published': False,
                  'error': error.code if isinstance(error, TourError) else type(error).__name__}
    print(json.dumps(result), flush=True)
    return 0 if result['ready'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
