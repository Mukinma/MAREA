"""Read-only empty-lab probe; local kernel queries only, no IP connections."""

import socket,os,json,pathlib,subprocess,sys
def read(p):
 try:return pathlib.Path(p).read_text()
 except OSError as e:return {'error':str(e)}
def command(args):
 try:
  r=subprocess.run(args,capture_output=True,text=True)
  return {'argv':args,'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr}
 except OSError as e:return {'argv':args,'error':str(e)}
names=socket.if_nameindex()
paths=['/proc/net/dev','/proc/net/route','/proc/net/ipv6_route','/proc/net/if_inet6','/proc/net/fib_trie','/proc/net/tcp','/proc/net/tcp6','/proc/net/udp','/proc/net/udp6','/proc/self/status','/proc/sys/net/ipv4/ip_forward','/proc/sys/net/ipv6/conf/all/forwarding']
out={'python':sys.version,'socket_file':socket.__file__,'if_nameindex_module':socket.if_nameindex.__module__,'if_nameindex':names,'legacy_predicate':[x[1] for x in names]==['lo'],'netns':os.readlink('/proc/self/ns/net'),'netns_inode':os.stat('/proc/self/ns/net').st_ino,'pid1_netns':os.readlink('/proc/1/ns/net'),'proc':{p:read(p) for p in paths},'sysfs':{}}
for p in sorted(pathlib.Path('/sys/class/net').iterdir()):
 out['sysfs'][p.name]=({'symlink':os.readlink(p),**{f:read(str(p/f)) for f in ['ifindex','iflink','address','flags','operstate','type','mtu']}} if p.is_symlink() else {'control_entry':read(str(p))})
out['commands']=[command(a) for a in [['ip','link','show'],['ip','-4','addr','show'],['ip','-6','addr','show'],['ip','-4','route','show','table','all'],['ip','-6','route','show','table','all'],['ip','-4','rule','show'],['ip','-6','rule','show']]]
kernel=out

"""Read-only kernel netlink dumps, no IP connections or configuration mutations."""
import socket, struct, json, pathlib, os

def attrs(data):
    out={}
    while data:
        if len(data)<4: raise ValueError('truncated attribute')
        n,t=struct.unpack_from('HH',data)
        if n<4 or n>len(data): raise ValueError('invalid attribute length')
        key=str(t & 0x3fff)
        if key in out: raise ValueError('duplicate attribute')
        out[key]=data[4:n].hex();data=data[(n+3)&~3:]
    return out

def dump(kind,body):
    s=socket.socket(socket.AF_NETLINK,socket.SOCK_RAW,socket.NETLINK_ROUTE)
    s.settimeout(3);s.bind((0,0));seq=713
    s.send(struct.pack('IHHII',16+len(body),kind,0x301,seq,0)+body)
    out=[]
    try:
        while True:
            packet=s.recv(1048576)
            while packet:
                if len(packet)<16:raise ValueError('truncated message')
                n,t,flags,rseq,pid=struct.unpack_from('IHHII',packet)
                if n<16 or n>len(packet) or rseq!=seq or flags&0x10:raise ValueError('incomplete dump')
                payload=packet[16:n];packet=packet[(n+3)&~3:]
                if t==3:return out
                if t==2:raise ValueError('kernel netlink error '+payload.hex())
                out.append({'type':t,'payload':payload.hex()})
    finally:s.close()

links=[]
for m in dump(18,struct.pack('BBHiII',0,0,0,0,0,0)):
    b=bytes.fromhex(m['payload']);family,pad,typ,index,flags,change=struct.unpack_from('BBHiII',b)
    a=attrs(b[16:]);li=attrs(bytes.fromhex(a['18'])) if '18' in a else {}
    links.append({'index':index,'type':typ,'flags':flags,'attrs':a,'linkinfo':li,'kind':bytes.fromhex(li['1']).rstrip(b'\0').decode() if '1'in li else None,'name':bytes.fromhex(a['3']).rstrip(b'\0').decode()})
addresses=[]
for m in dump(22,struct.pack('BBBBI',0,0,0,0,0)):
    b=bytes.fromhex(m['payload']);fam,prefix,flags,scope,index=struct.unpack_from('BBBBI',b)
    addresses.append({'family':fam,'prefix':prefix,'flags':flags,'scope':scope,'index':index,'attrs':attrs(b[8:])})
routes=[]
for m in dump(26,struct.pack('BBBBBBBBI',0,0,0,0,0,0,0,0,0)):
    b=bytes.fromhex(m['payload']);fam,dst,src,tos,table,proto,scope,typ,flags=struct.unpack_from('BBBBBBBBI',b)
    routes.append({'family':fam,'dst_len':dst,'src_len':src,'table':table,'protocol':proto,'scope':scope,'type':typ,'flags':flags,'attrs':attrs(b[12:])})
rules=[]
for m in dump(34,struct.pack('BBBBBBBBI',0,0,0,0,0,0,0,0,0)):
    b=bytes.fromhex(m['payload']);fam,dst,src,tos,table,res1,res2,action,flags=struct.unpack_from('BBBBBBBBI',b)
    rules.append({'family':fam,'dst_len':dst,'src_len':src,'table':table,'action':action,'flags':flags,'attrs':attrs(b[12:])})
netlink={'links':links,'addresses':addresses,'routes':routes,'rules':rules,'netns':os.readlink('/proc/self/ns/net'),'modules':pathlib.Path('/proc/modules').read_text()}
print(json.dumps({'kernel':kernel,'netlink':netlink},sort_keys=True))
