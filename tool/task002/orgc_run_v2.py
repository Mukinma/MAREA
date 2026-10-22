"""Explicit v2 dispatch: new adapter identity, reused cases and PAX primitives."""
import sys,runpy
import orgc_lab_v2 as L
sys.modules['orgc_lab']=L
allowed={'org0_cases','org0_more','org0_expiry','org0_verify','orgc_install','orgc_recovery','c_cases','c_more','c_verify','c_owner_guard','c_concurrency','orgc_review_cases','orgc_preserve'}
name=sys.argv[1];args=sys.argv[2:];L.require(name in allowed,'Unapproved stage module')
if name.startswith('c_') or (name in {'orgc_install','orgc_recovery'} and args==['C']):
 from orgc_gate import validate_org0_gate
 import json
 validate_org0_gate(L.RUN,json.loads((L.RUN/'12-ORG0-ACCEPTANCE.json').read_text()))
sys.argv=sys.argv[1:];runpy.run_module(name,run_name='__main__')
