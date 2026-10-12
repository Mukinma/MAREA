"""Run actual production Hugin tools, including rejection cases, inside Docker."""
import argparse
import json
from pathlib import Path
import tempfile
import time
from worker import TourError,stitch_photos,export_results,validate_gpano

parser=argparse.ArgumentParser();parser.add_argument('fixture',type=Path);parser.add_argument('output',type=Path);parser.add_argument('--case',choices=['complete','incomplete','blank'],required=True);args=parser.parse_args()
frames=json.loads((args.fixture/'fixture.json').read_text())['frames']
if args.case=='incomplete':frames=[f for f in frames if f['pitch']<=0]
if args.case=='blank':frames=frames[:6]
files=[args.fixture/('blank.jpg' if args.case=='blank' else f['file']) for f in frames]
args.output.mkdir(parents=True,exist_ok=True)
started=time.monotonic()
# Preserve PTO/remaps only on failures for root-cause investigation.
try:
    source=stitch_photos(frames,files,args.output,time.monotonic()+840,lambda:None)
    if args.case!='complete':raise AssertionError('Incomplete/no-feature fixture unexpectedly accepted')
    outputs=export_results(source,args.output)
    sizes=[validate_gpano(p) for p in outputs]
    assert sizes==[(4096,2048),(2048,1024),(512,256)]
    result={'case':args.case,'passed':True,'sizes':sizes}
except TourError as error:
    result={'case':args.case,'passed':args.case!='complete' and error.code in ('incomplete_sphere_coverage','disconnected_control_points'),'error':error.code}
result['seconds']=round(time.monotonic()-started,3)
(args.output/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result),flush=True)
raise SystemExit(0 if result['passed'] else 1)
