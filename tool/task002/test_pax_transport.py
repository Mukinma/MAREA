import unittest
from pax_transport import ns_text,text_ns,compare,IntegrityError,safe_members
import io,tarfile
class PaxTests(unittest.TestCase):
 def test_nanoseconds_roundtrip_without_float(self):
  for n in [1700000000123456789,1699999900765432101,1000000001]:self.assertEqual(text_ns(ns_text(n)),n)
 def test_every_required_integrity_field_is_checked(self):
  original=[{'path':'data/a','kind':'file','size':1,'mode':0o640,'uid':1000,'gid':1000,'mtime_ns':1700000000123456789,'atime_ns':1699999900765432101,'sha256':'abc'}]
  for field,value in [('path','data/b'),('kind','dir'),('size',2),('mode',0o600),('uid',1001),('gid',1001),('mtime_ns',1700000000000000000),('atime_ns',1699999900000000000),('sha256','def')]:
   with self.subTest(field=field):
    altered=[{**original[0],field:value}]
    with self.assertRaises(IntegrityError):compare(original,altered)
  with self.assertRaises(IntegrityError):compare(original,[])
 def test_unsafe_link_or_path_rejected(self):
  for name,kind,target in [('data/../escape',tarfile.REGTYPE,''),('data/link',tarfile.SYMTYPE,'../../escape'),('data/link',tarfile.SYMTYPE,'/etc/passwd'),('data/link',tarfile.LNKTYPE,'other/a')]:
   t=tarfile.TarInfo(name);t.type=kind;t.linkname=target
   with self.assertRaises(IntegrityError):safe_members([t])
if __name__=='__main__':unittest.main(verbosity=2)
