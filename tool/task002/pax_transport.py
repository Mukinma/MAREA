"""Strict local PAX transport. Nanosecond mtime/atime; safe internal links only.
Inode ctime/birthtime and directory allocation size are filesystem-generated,
not restorable archive attributes. No floating point timestamp conversion.
"""
import hashlib,os,pathlib,posixpath,stat,tarfile
from decimal import Decimal,InvalidOperation
class IntegrityError(RuntimeError):pass
def need(ok,msg):
 if not ok:raise IntegrityError(msg)
def ns_text(n):
 need(isinstance(n,int) and n>=0,'Invalid timestamp');return f'{n//1000000000}.{n%1000000000:09d}'
def text_ns(text):
 try:
  d=Decimal(str(text));need(d.is_finite() and d>=0,'Invalid PAX time');n=d*1000000000;need(n==n.to_integral_value(),'Sub-nanosecond PAX time');return int(n)
 except (InvalidOperation,ValueError) as e:raise IntegrityError('Invalid PAX timestamp') from e
def compare(expected,actual):need(expected==actual,'Manifest mismatch: paths/bytes/types/size/mode/uid/gid/mtime_ns/atime_ns/links')
def opened(path,directory=False):
 need(hasattr(os,'O_NOATIME'),'O_NOATIME required in pinned Linux helper')
 return os.open(path,os.O_RDONLY|os.O_NOFOLLOW|os.O_NOATIME|(os.O_DIRECTORY if directory else 0))
def snapshot(root):
 root=pathlib.Path(root);rows=[];inodes={}
 def visit(path,arc):
  s=path.lstat();row={'path':arc,'mode':stat.S_IMODE(s.st_mode),'uid':s.st_uid,'gid':s.st_gid,'mtime_ns':s.st_mtime_ns,'atime_ns':s.st_atime_ns}
  if stat.S_ISDIR(s.st_mode):
   row['kind']='dir';rows.append(row);fd=opened(path,True)
   try:
    with os.scandir(fd) as it:names=sorted(e.name for e in it)
   finally:os.close(fd)
   for name in names:visit(path/name,arc+'/'+name)
  elif stat.S_ISREG(s.st_mode):
   h=hashlib.sha256();fd=opened(path)
   with os.fdopen(fd,'rb') as f:
    for block in iter(lambda:f.read(1048576),b''):h.update(block)
    end=os.fstat(f.fileno())
   need((s.st_size,s.st_mtime_ns,s.st_uid,s.st_gid,s.st_mode)==(end.st_size,end.st_mtime_ns,end.st_uid,end.st_gid,end.st_mode),'Source file changed')
   inode=(s.st_dev,s.st_ino);first=inodes.get(inode);row.update(kind='hardlink' if first else 'file',size=s.st_size,sha256=h.hexdigest())
   if first:row['linkname']=first
   else:inodes[inode]=arc
   rows.append(row)
  elif stat.S_ISLNK(s.st_mode):
   link=os.readlink(path)
   # readlink can update atime; restore it explicitly on this owned synthetic/clone inode.
   if path.lstat().st_atime_ns!=s.st_atime_ns:os.utime(path,ns=(s.st_atime_ns,s.st_mtime_ns),follow_symlinks=False)
   row.update(kind='symlink',linkname=link,size=len(os.fsencode(link)));rows.append(row)
  else:raise IntegrityError('Special files forbidden')
 visit(root,'data');return rows

def safe_members(members):
 seen={}
 for m in members:
  name=m.name.rstrip('/');parts=pathlib.PurePosixPath(name).parts
  need(name=='data' or name.startswith('data/'),'Archive outside data root')
  need(not name.startswith('/') and '..' not in parts and name not in seen,'Unsafe/duplicate path')
  need(all(seen.get('/'.join(parts[:i]),'dir')=='dir' for i in range(1,len(parts))),'Link/non-directory ancestor')
  need(m.isdir() or m.isfile() or m.issym() or m.islnk(),'Special archive entry forbidden')
  kind='dir' if m.isdir() else 'symlink' if m.issym() else 'hardlink' if m.islnk() else 'file'
  if m.issym():
   target=posixpath.normpath(posixpath.join(posixpath.dirname(name),m.linkname));need(not m.linkname.startswith('/') and (target=='data' or target.startswith('data/')),'Symlink escapes root')
  if m.islnk():need(m.linkname in seen and seen[m.linkname] in ['file','hardlink'],'Invalid/forward hardlink')
  seen[name]=kind
 return members

def export_archive(root,stream):
 root=pathlib.Path(root);before=snapshot(root)
 with tarfile.open(fileobj=stream,mode='w|',format=tarfile.PAX_FORMAT) as t:
  for r in before:
   m=tarfile.TarInfo(r['path']);m.mode=r['mode'];m.uid=r['uid'];m.gid=r['gid'];m.mtime=r['mtime_ns']//1000000000
   m.pax_headers={'mtime':ns_text(r['mtime_ns']),'atime':ns_text(r['atime_ns'])}
   kind=r['kind'];m.type={'dir':tarfile.DIRTYPE,'file':tarfile.REGTYPE,'symlink':tarfile.SYMTYPE,'hardlink':tarfile.LNKTYPE}[kind]
   if kind in ['symlink','hardlink']:m.linkname=r['linkname']
   if kind=='file':
    m.size=r['size'];path=root.joinpath(*pathlib.PurePosixPath(r['path']).parts[1:])
    with os.fdopen(opened(path),'rb') as f:t.addfile(m,f)
   else:t.addfile(m)
 compare(before,snapshot(root));return before

def archive_manifest(fileobj):
 rows=[];byname={}
 with tarfile.open(fileobj=fileobj,mode='r:*') as t:
  members=safe_members(t.getmembers())
  for m in members:
   need('mtime' in m.pax_headers and 'atime' in m.pax_headers,'Missing exact PAX times')
   row={'path':m.name.rstrip('/'),'mode':m.mode,'uid':m.uid,'gid':m.gid,'mtime_ns':text_ns(m.pax_headers['mtime']),'atime_ns':text_ns(m.pax_headers['atime'])}
   if m.isdir():row['kind']='dir'
   elif m.issym():row.update(kind='symlink',linkname=m.linkname,size=len(os.fsencode(m.linkname)))
   elif m.islnk():
    target=byname[m.linkname];row.update(kind='hardlink',linkname=m.linkname,size=target['size'],sha256=target['sha256'])
   else:
    h=hashlib.sha256()
    with t.extractfile(m) as f:
     for block in iter(lambda:f.read(1048576),b''):h.update(block)
    row.update(kind='file',size=m.size,sha256=h.hexdigest())
   rows.append(row);byname[row['path']]=row
 return rows

def restore_metadata(root,stream):
 """Final restore phase after validated archive materialization, no ownership fixes.
 Apply exact PAX atime/mtime with utimensat(ns). Validate all other attributes first.
 """
 root=pathlib.Path(root)
 with tarfile.open(fileobj=stream,mode='r|*') as t:
  members=[]
  for m in t:
   members.append(m)
  safe_members(members)
  exact={}
  for m in members:
   need('mtime' in m.pax_headers and 'atime' in m.pax_headers,'Missing exact time')
   path=root.joinpath(*pathlib.PurePosixPath(m.name).parts[1:]);s=path.lstat()
   need((s.st_uid,s.st_gid,stat.S_IMODE(s.st_mode))==(m.uid,m.gid,m.mode),'Restore uid/gid/mode mismatch')
   exact[m.name]=(text_ns(m.pax_headers['atime']),text_ns(m.pax_headers['mtime']))
  # Children first: directory traversal must not invalidate restored times.
  for m in reversed(members):
   path=root.joinpath(*pathlib.PurePosixPath(m.name).parts[1:]);os.utime(path,ns=exact[m.name],follow_symlinks=False)
