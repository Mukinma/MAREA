"""A genuine DB-session grant expires by server time; fixture INSERT explicit."""
import json,uuid,time
import orgc_lab as L
from org0_cases import lit,write,call,deny,js,value

def run():
 out={}
 for a in ['a','b']:
  pg=f'{L.OWNER}-{a}-pg';f=json.loads((L.PRIVATE/(a+'-ORG0-active-fixture.json')).read_text());mid=str(uuid.uuid4());oid=lit(f['orgs']['last']);person=lit(f['users']['admin']['person']);owner=lit(f['users']['last']['person'])
  write(pg,'INSERT INTO collaboration.organization_memberships(id,organization_id,person_id,role,status,permissions,representative,invited_by,valid_until) VALUES('+lit(mid)+','+oid+','+person+",'editor','ACTIVE',ARRAY['mission.manage']::text[],true,"+owner+",clock_timestamp()+interval '2 seconds');")
  L.require(call(pg,'admin','SELECT collaboration.org_authorize('+oid+",'mission.manage');")['authorized'],'Before-deadline grant not working')
  L.sql(pg,"SELECT pg_sleep(greatest(0,extract(epoch FROM (valid_until-clock_timestamp())))+.02) FROM collaboration.organization_memberships WHERE id="+lit(mid)+';')
  deny(pg,'admin','SELECT collaboration.org_authorize('+oid+",'mission.manage');")
  before=L.capture(pg);original=value(write(pg,'SELECT collaboration.org_provision('+js(f['primary_manifest'])+');','marea_org_operator'));L.require(original['organization_id']==f['orgs']['primary'] and L.capture(pg)==before,'Provision replay changed state')
  changed=dict(f['primary_manifest']);changed['name']='Synthetic changed name';r=write(pg,'SELECT collaboration.org_provision('+js(changed)+');','marea_org_operator',check=False);L.require(r.returncode!=0 and '23505' in r.stderr,'Provision key content conflict hidden')
  r=write(pg,"INSERT INTO collaboration.organization_memberships(organization_id,person_id,role,status,permissions,invited_by) VALUES('00000000-0000-0000-0000-000000000099',"+person+",'member','INVITED',ARRAY['organization.view']::text[],"+owner+');',rollback=True,check=False);L.require(r.returncode!=0 and '23503' in r.stderr and L.capture(pg)==before,'Real organizational FK not enforced')
  out[a]={'result':'PASS','explicit_new_private_fixture_rows':1,'genuine_before_expiry_allowed_after_expiry_denied':True,'server_clock_without_extension':True,'provision_replay_no_delta':True,'provision_conflicting_key_23505':True,'real_membership_organization_FK_23503':True}
 L.save('08b-ORG0-expiry-integrity.json',{'result':'PASS','sources':out})
if __name__=='__main__':run()
