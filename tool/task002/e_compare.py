"""Strict logical comparison: normalize only documented PostgreSQL catalog identities/order."""
import copy,json,re

def canonical_catalog(value):
 c=copy.deepcopy(value)
 columns={}
 for x in c['columns']:columns.setdefault((x['table_schema'],x['table_name']),[]).append(x)
 for group in columns.values():
  for position,x in enumerate(sorted(group,key=lambda x:x['ordinal_position']),1):
   x['ordinal_position']=position;x.pop('dtd_identifier',None)
 for collection in ['tables','routines']:
  for x in c[collection]:
   if x.get('acl') is not None:
    # Pinned fixture role names contain no commas/quotes; never broaden grants.
    acl=x['acl'];assert '"' not in acl;x['acl']=sorted(acl[1:-1].split(','))
 if c.get('database',{}).get('acl') is not None:
  acl=c['database']['acl'];assert '"' not in acl;c['database']['acl']=sorted(acl[1:-1].split(','))
 for x in c['triggers']:
  if x['internal']:
   for key in ['name','definition']:x[key]=re.sub(r'RI_ConstraintTrigger_([ac])_[0-9]+',r'RI_ConstraintTrigger_\1_INTERNAL_OID',x[key])
 for x in c['settings']:x.pop('source',None)
 for key,value in c.items():
  if isinstance(value,list):c[key]=sorted(value,key=lambda x:json.dumps(x,sort_keys=True,separators=(',',':')))
 return c
