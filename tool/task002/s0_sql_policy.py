"""Allow exact S0 guard DDL, while retaining all former destructive SQL denials."""
import re
from e2a_isolation import require

def validate_write(query,approved_guard_ddl):
 require(not re.search(r'(?is)\bdelete\s+from\s+(auth\.users|public\.profiles)\b',query),'Out-of-scope account/profile deletion')
 if re.search(r'(?i)\btruncate\b',query):
  require(approved_guard_ddl.startswith('BEGIN;') and approved_guard_ddl.rstrip().endswith('COMMIT;'),'Malformed guard DDL')
  rehearsal=approved_guard_ddl.rsplit('COMMIT;',1)[0]+'ROLLBACK;'
  require(query in [approved_guard_ddl,rehearsal],'Only byte-exact pinned CREATE TRIGGER DDL may mention TRUNCATE')
 return True
