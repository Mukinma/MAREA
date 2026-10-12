"""Lease-bound Cloud Run Job. Never accepts a URL, PTO file or shell from a client."""
from __future__ import annotations
import argparse
import json
import hashlib
import hmac
import math
import os
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import time
import uuid
from pathlib import Path
from urllib.parse import quote, urlparse

import numpy as np
import requests
from PIL import Image

Image.MAX_IMAGE_PIXELS = 120_000_000
UUID_RE = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
TRANSIENT = {'network', 'storage_unavailable', 'timeout'}
ALLOWED_TOOLS = {'cpfind', 'cpclean', 'autooptimiser', 'pano_modify', 'nona', 'enblend'}

class TourError(Exception):
    def __init__(self, code):
        super().__init__(code)
        self.code = code

def valid_uuid(value):
    if not isinstance(value, str) or not UUID_RE.fullmatch(value):
        raise TourError('invalid_identifier')
    return str(uuid.UUID(value))

def finite_number(value, low, high):
    if isinstance(value, bool) or not isinstance(value, (float, int)) or not math.isfinite(value) or not low <= value <= high:
        raise TourError('invalid_manifest')

def validate_manifest(manifest, owner, capture, files=None):
    owner, capture = valid_uuid(owner), valid_uuid(capture)
    if not isinstance(manifest, dict) or manifest.get('mode') not in ('import', 'photos'):
        raise TourError('invalid_manifest')
    frames = manifest.get('frames')
    if not isinstance(frames, list) or not 1 <= len(frames) <= 96:
        raise TourError('invalid_manifest')
    if (manifest['mode'] == 'import' and len(frames) != 1) or (manifest['mode'] == 'photos' and len(frames) < 6):
        raise TourError('insufficient_frames')
    seen = set()
    for index, f in enumerate(frames):
        if not isinstance(f,dict):raise TourError('invalid_manifest')
        ident = valid_uuid(f.get('id'))
        if ident in seen or f.get('path') != f'{owner}/{capture}/{ident}.jpg':
            raise TourError('invalid_input_path')
        seen.add(ident)
        for field, low, high in [('width', 64, 24000), ('height', 64, 24000), ('yaw', -180, 179.999999), ('pitch', -90, 90), ('roll', -180, 180), ('hfov', 1, 360), ('vfov', 1, 180)]:
            finite_number(f.get(field), low, high)
        if not isinstance(f['width'], int) or not isinstance(f['height'], int) or f['width'] * f['height'] > 120_000_000:
            raise TourError('invalid_dimensions')
        if manifest['mode'] == 'photos' and (f['hfov'] >= 179 or f['vfov'] >= 179):
            raise TourError('invalid_lens_fov')
        if files is not None:
            try:
                with Image.open(files[index]) as im:
                    if im.format != 'JPEG' or im.size != (f['width'], f['height']):
                        raise TourError('image_dimensions_mismatch')
                    if im.getexif().get(274, 1) != 1:
                        raise TourError('image_orientation_not_normalized')
                    im.load()
            except (OSError, Image.DecompressionBombError, Image.DecompressionBombWarning):
                raise TourError('invalid_image')
    return frames

def validate_gpano(path):
    """A 2:1 aspect ratio alone never proves equirectangular projection."""
    try:
        with Image.open(path) as im:
            raw=im.info.get('xmp')
        if not raw or len(raw)>262144:raise TourError('gpano_full_sphere_required')
        root=ET.fromstring(raw)
    except (OSError, ET.ParseError):
        raise TourError('gpano_full_sphere_required')
    def value(name):
        key='{http://ns.google.com/photos/1.0/panorama/}'+name
        values=[node.attrib[key] for node in root.iter() if key in node.attrib]
        values += [node.text for node in root.iter(key)]
        if len(set(values))!=1 or values[0] is None:
            raise TourError('gpano_full_sphere_required')
        return values[0]
    try:
        if value('ProjectionType') != 'equirectangular':
            raise TourError('gpano_full_sphere_required')
        w, h = int(value('FullPanoWidthPixels')), int(value('FullPanoHeightPixels'))
        cropped = (int(value('CroppedAreaImageWidthPixels')), int(value('CroppedAreaImageHeightPixels')))
        left, top = int(value('CroppedAreaLeftPixels')), int(value('CroppedAreaTopPixels'))
        with Image.open(path) as im:
            if im.format != 'JPEG' or w != 2 * h or cropped != (w, h) or im.size != (w, h) or left != 0 or top != 0:
                raise TourError('gpano_full_sphere_required')
        return w, h
    except (ValueError, UnicodeError, OSError):
        raise TourError('gpano_full_sphere_required')

def connected_control_points(pto, count):
    graph = [set() for _ in range(count)]
    for line in pto.splitlines():
        if not line.startswith('c '):
            continue
        n, N = re.search(r'\bn(\d+)\b', line), re.search(r'\bN(\d+)\b', line)
        t = re.search(r'\bt(\d+)\b', line)
        if n and N and (not t or t[1] == '0'):
            a, b = int(n[1]), int(N[1])
            if a >= count or b >= count:
                raise TourError('invalid_control_points')
            if a != b:
                graph[a].add(b); graph[b].add(a)
    seen, todo = set(), [0]
    while todo:
        i = todo.pop()
        if i not in seen:
            seen.add(i); todo.extend(graph[i] - seen)
    if len(seen) != count:
        raise TourError('disconnected_control_points')

def validate_alpha_coverage(alphas):
    union = None
    for alpha in alphas:
        covered = np.asarray(alpha) >= 250
        if covered.ndim != 2:
            raise TourError('invalid_remapped_alpha')
        if union is None:
            union = covered.copy()
        elif union.shape != covered.shape:
            raise TourError('invalid_remapped_alpha')
        else:
            union |= covered
    # Full sphere must include poles and the longitude seam. A missing remapped
    # pixel is rejected; no black-fill fabrication is passed off as coverage.
    if union is None or not np.all(union):
        raise TourError('incomplete_sphere_coverage')

def gpano_xmp(width, height):
    return (f'<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
            f'<rdf:Description xmlns:GPano="http://ns.google.com/photos/1.0/panorama/" GPano:ProjectionType="equirectangular" '
            f'GPano:FullPanoWidthPixels="{width}" GPano:FullPanoHeightPixels="{height}" '
            f'GPano:CroppedAreaImageWidthPixels="{width}" GPano:CroppedAreaImageHeightPixels="{height}" '
            'GPano:CroppedAreaLeftPixels="0" GPano:CroppedAreaTopPixels="0"/></rdf:RDF></x:xmpmeta>').encode()

def command(args, cwd, deadline, check_current):
    if args[0] not in ALLOWED_TOOLS:
        raise TourError('invalid_processing_command')
    check_current()
    print(json.dumps({"component":"marea_tour_worker","event":"tool_started","tool":args[0]}),flush=True)
    # No shell, untrusted names or PTO text; command output is not logged.
    with tempfile.TemporaryFile() as log:
        proc = subprocess.Popen(args, cwd=cwd, stdout=log, stderr=log, env={**os.environ, 'OMP_NUM_THREADS': '4'})
        try:
            while proc.poll() is None:
                if time.monotonic() >= deadline:
                    raise TourError('timeout')
                check_current()
                time.sleep(1)
            if proc.returncode != 0:
                log.seek(0,2);length=log.tell();log.seek(max(0,length-2048))
                diagnostic=log.read().decode('utf-8',errors='replace')
                # Tools receive fixed numeric filenames, never tokens or URLs.
                print(json.dumps({'component':'marea_tour_worker','event':'tool_failed','tool':args[0],'exit_code':proc.returncode,'diagnostic':diagnostic}),flush=True)
                raise TourError('stitch_failed')
        finally:
            if proc.poll() is None:
                proc.terminate()
                try: proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    proc.kill(); proc.wait()

def stitch_photos(frames, files, directory, deadline, check_current):
    # Fixed names and numeric values only. Each lens FOV is independent: phones
    # may change focal length, but accepted inputs must be rectilinear JPEGs.
    pto = directory / 'project.pto'
    lines = ['p f2 w4096 h2048 v360 n"TIFF_m c:LZW"', 'm g1 i0 f0 m2 p0.00784314']
    for index, (frame, file) in enumerate(zip(frames, files)):
        with Image.open(file) as source:
            source.thumbnail((2560,2560), Image.Resampling.LANCZOS)
            source.save(directory/f'frame{index:03d}.jpg', quality=95)
            w,h=source.size
        lines.append(f'i w{w} h{h} f0 v{frame["hfov"]:.8f} y{frame["yaw"]:.8f} p{frame["pitch"]:.8f} r{frame["roll"]:.8f} a0 b0 c0 d0 e0 n"frame{index:03d}.jpg"')
    lines.append('v ' + ' '.join(f'y{i} p{i} r{i}' for i in range(1,len(frames))))
    lines.append('v')
    pto.write_text('\n'.join(lines)+'\n')
    command(['cpfind','--multirow','-o','control.pto','project.pto'],directory,deadline,check_current)
    command(['cpclean','-o','clean.pto','control.pto'],directory,deadline,check_current)
    connected_control_points((directory/'clean.pto').read_text(),len(frames))
    command(['autooptimiser','-n','-m','-o','optimized.pto','clean.pto'],directory,deadline,check_current)
    command(['pano_modify','--projection=2','--fov=360x180','--canvas=4096x2048','--crop=0,4096,0,2048','-o','sphere.pto','optimized.pto'],directory,deadline,check_current)
    # Disable cropped TIFFs explicitly. Alpha masks must inhabit the complete
    # sphere canvas, not the bounding boxes of the remapped photographs.
    sphere=directory/'sphere.pto'
    text=sphere.read_text()
    text=re.sub(r'n"[^"]*"', 'n"TIFF_m c:LZW"',text,count=1)
    sphere.write_text(text)
    command(['nona','-m','TIFF_m','-o','remap','sphere.pto'],directory,deadline,check_current)
    remaps=sorted(directory.glob('remap[0-9][0-9][0-9][0-9].tif'))
    if len(remaps)!=len(frames):raise TourError('missing_remapped_images')
    def alpha_masks():
        for path in remaps:
            check_current()
            with Image.open(path) as remap:
                if remap.size!=(4096,2048) or 'A' not in remap.getbands():
                    raise TourError('invalid_remapped_alpha')
                yield np.asarray(remap.getchannel('A'))
    validate_alpha_coverage(alpha_masks())
    if sum(p.stat().st_size for p in directory.iterdir())>3_000_000_000:
        raise TourError('processing_resource_limit')
    # Enblend4.2 Dijkstra mask optimization segfaulted twice on verified
    # full-sphere remaps. Keep real multiband blending, disable that optimizer.
    command(['enblend','--no-optimize','--wrap=horizontal','-o','blend.tif',*[p.name for p in remaps]],directory,deadline,check_current)
    blend=directory/'blend.tif'
    with Image.open(blend) as image:
        if image.size!=(4096,2048):raise TourError('invalid_output_dimensions')
        if 'A' in image.getbands():validate_alpha_coverage([np.asarray(image.getchannel('A'))])
    return blend

def export_results(image_path, directory):
    with Image.open(image_path) as image:
        image=image.convert('RGB')
        for name, size in [('panorama',(4096,2048)),('preview',(2048,1024)),('thumbnail',(512,256))]:
            image.resize(size,Image.Resampling.LANCZOS).save(directory/f'{name}.jpg',quality=90,xmp=gpano_xmp(*size))
    return [directory/f'{name}.jpg' for name in ('panorama','preview','thumbnail')]

class Backend:
    def __init__(self, url, key):
        parsed=urlparse(url)
        if parsed.scheme!='https' or not parsed.hostname or parsed.username or parsed.path not in ('','/'):
            raise TourError('invalid_backend_config')
        self.url=url.rstrip('/')
        self.session=requests.Session()
        self.session.headers.update({'Authorization':f'Bearer {key}','apikey':key})
    def request(self, method, path, **kwargs):
        try:
            response=self.session.request(method,self.url+path,timeout=(5,25),**kwargs)
            if response.status_code in (408,429) or response.status_code>=500:raise TourError('storage_unavailable')
            if not response.ok:raise TourError('backend_rejected')
            return response
        except requests.RequestException:raise TourError('network')
    def rpc(self, name, payload):
        response=self.request('POST','/rest/v1/rpc/'+name,json=payload)
        return response.json() if response.content else None
    def current(self, job, lease):return self.rpc('tours_job_is_current',{'p_job':job,'p_lease':lease})
    def download(self, path, local):
        response=self.request('GET','/storage/v1/object/authenticated/tour-inputs/'+quote(path,safe='/'),stream=True)
        count=0
        try:
            with local.open('wb') as stream:
                for chunk in response.iter_content(65536):
                    count+=len(chunk)
                    if count>33554432:raise TourError('input_too_large')
                    stream.write(chunk)
        except requests.RequestException:
            raise TourError('network')
        finally:response.close()
    def begin_write(self, job,lease):return self.rpc('tours_begin_output_write',{'p_job':job,'p_lease':lease})
    def end_write(self,job,lease):self.rpc('tours_end_output_write',{'p_job':job,'p_lease':lease})
    def upload(self,path,file):
        with file.open('rb') as stream:
            self.request('POST','/storage/v1/object/tour-assets/'+quote(path,safe='/'),headers={'Content-Type':'image/jpeg','x-upsert':'false'},data=stream)
    def remove(self, paths):
        if paths:self.request('DELETE','/storage/v1/object/tour-assets',json={'prefixes':paths})
    def receipt(self,job,lease):
        return self.rpc('tours_completion_receipt',{'p_job':job,'p_lease':lease})
    def finish(self,job,lease,state,result=None,error=None):
        return self.rpc('tours_finish_job',{'p_job':job,'p_lease':lease,'p_state':state,'p_result':result,'p_error':error})

def process_job(job, backend):
    ident,lease=valid_uuid(job['id']),valid_uuid(job['lease_id'])
    if not backend.current(ident,lease):return False
    deadline=time.monotonic()+840
    uploaded=[];writing=False
    started=time.monotonic()
    def log(event,**details):
        print(json.dumps({'component':'marea_tour_worker','event':event,'job_id':ident,'elapsed_seconds':round(time.monotonic()-started,3),**details}),flush=True)
    log('started')
    def check():
        if time.monotonic()>=deadline:raise TourError('timeout')
        if not backend.current(ident,lease):raise TourError('cancelled')
    try:
        owner,capture=valid_uuid(job['owner_id']),valid_uuid(job['capture_id'])
        frames=validate_manifest(job['manifest'],owner,capture)
        with tempfile.TemporaryDirectory(prefix='marea-tour-') as temp:
            directory=Path(temp);files=[]
            for index,frame in enumerate(frames):
                check();local=directory/f'input{index:03d}.jpg';backend.download(frame['path'],local);files.append(local)
            validate_manifest(job['manifest'],owner,capture,files)
            if job['manifest']['mode']=='import':validate_gpano(files[0]);source=files[0]
            else:source=stitch_photos(frames,files,directory,deadline,check)
            exports=export_results(source,directory)
            check()
            if not backend.begin_write(ident,lease):return False
            writing=True
            # A reclaimed job can have residue from an interrupted old execution.
            # Only the new current lease holds the output write guard now.
            prefix=f'{owner}/jobs/{ident}'
            expected=[f'{prefix}/{file.name}' for file in exports]
            check();backend.remove(expected)
            for path,file in zip(expected,exports):
                if not backend.begin_write(ident,lease):raise TourError('cancelled')
                check()
                # Register before the request: a timeout may occur after Storage
                # accepted bytes and must still trigger cleanup.
                uploaded.append(path);backend.upload(path,file);check()
            result=dict(zip(('panorama_path','preview_path','thumbnail_path'),expected))
            try:
                accepted=backend.finish(ident,lease,'succeeded',result)
            except TourError:
                # The DB may have committed before the response was lost. Until
                # a durable receipt resolves it, these outputs must be retained.
                try:receipt=backend.receipt(ident,lease)
                except TourError:log('completion_unresolved');return False
                if receipt and receipt.get('committed') and receipt.get('result')==result:
                    uploaded=[];log('ready',reconciled=True);return True
                # A confirmed non-commit leaves the normal lease recovery/cleanup
                # responsible for residue; it cannot remove a newer lease's files.
                log('completion_unresolved');return False
            if not accepted:
                backend.remove(uploaded);return False
            uploaded=[]
            log('ready',frames=len(frames),output_width=4096,output_height=2048)
            return True
    except TourError as error:
        log('cancelled' if error.code=='cancelled' else 'failed',error_code=error.code)
        if uploaded:backend.remove(uploaded);uploaded=[]
        if error.code!='cancelled':backend.finish(ident,lease,'retry' if error.code in TRANSIENT else 'failed',error=error.code)
        return False
    except (OSError,ValueError,KeyError,Image.DecompressionBombError):
        log('failed',error_code='invalid_image')
        if uploaded:backend.remove(uploaded);uploaded=[]
        backend.finish(ident,lease,'failed',error='invalid_image')
        return False
    finally:
        # Keep guard through cleanup, otherwise a newer execution could upload
        # canonical outputs while this execution is still deleting its residue.
        if writing:backend.end_write(ident,lease)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--job',required=True);parser.add_argument('--lease',required=True);parser.add_argument('--proof',required=True)
    args=parser.parse_args();ident,lease=valid_uuid(args.job),valid_uuid(args.lease)
    secret=os.environ.get('TOUR_WORKER_SECRET','')
    if len(secret)<32 or not hmac.compare_digest(args.proof,hmac.new(secret.encode(),f'{ident}:{lease}'.encode(),hashlib.sha256).hexdigest()):
        raise TourError('unauthorized_dispatch')
    backend=Backend(os.environ['SUPABASE_URL'],os.environ['SUPABASE_SERVICE_ROLE_KEY'])
    job=backend.rpc('tours_job_context',{'p_job':ident,'p_lease':lease})
    if job:process_job(job,backend)

if __name__=='__main__':main()
