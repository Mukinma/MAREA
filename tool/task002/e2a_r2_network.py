"""Runtime counterpart of the adopted empty verifier; only explicit loopback TCP."""
import re
from e2a_isolation import require,canonical_netlink,policy,IsolationError

def validate_runtime(snapshot,anchor,ports):
 try:
  c=snapshot['inspect'];k=snapshot['kernel'];n=snapshot['netlink'];p=policy();h=c['HostConfig']
  require(h['NetworkMode']=='container:'+anchor['Id'],'Runtime namespace target')
  require(c['Image']==p['image'] and c['Config']['User']=='1000:1000' and not c['Mounts'],'Runtime probe identity/mounts')
  require(h['ReadonlyRootfs'] and not h['Privileged'] and h['CapDrop']==['ALL'] and not h.get('CapAdd') and h['SecurityOpt']==['no-new-privileges'],'Runtime probe privileges')
  require(not h.get('PortBindings') and not c['NetworkSettings']['Ports'] and not c['NetworkSettings']['Networks'],'Runtime probe endpoints')
  require(k['netns']==n['netns']==k['pid1_netns']==f"net:[{k['netns_inode']}]",'Runtime namespace inconsistent')
  expected=canonical_netlink(n)
  for key in ['links','addresses','routes','rules']:require(expected[key]==p[key],'Runtime network drift: '+key)
  require(k['sysfs']==p['sysfs'] and k['if_nameindex']==[[v['index'],v['name']] for v in n['links']],'Runtime interfaces inconsistent')
  proc=k['proc'];names=[line.split(':')[0].strip() for line in proc['/proc/net/dev'].splitlines()[2:] if ':' in line]
  require(sorted(names)==sorted(v['name'] for v in n['links']),'Runtime proc interfaces')
  require(len(proc['/proc/net/route'].splitlines())==1 and proc['/proc/net/route'].startswith('Iface\tDestination'),'Runtime IPv4 proc routes')
  require([[v for i,v in enumerate(line.split()) if i not in [6,7]] for line in proc['/proc/net/ipv6_route'].splitlines()]==p['proc_ipv6_routes'],'Runtime IPv6 proc routes')
  require(proc['/proc/net/if_inet6'].split()==p['proc_inet6'],'Runtime IPv6 addresses')
  require(proc['/proc/sys/net/ipv4/ip_forward'].strip()==proc['/proc/sys/net/ipv6/conf/all/forwarding'].strip()=='0','Runtime forwarding')
  status=dict(re.findall(r'^(Cap(?:Inh|Prm|Eff|Bnd|Amb)|NoNewPrivs):\s*(\S+)',proc['/proc/self/status'],re.M))
  require(set(status)=={'CapInh','CapPrm','CapEff','CapBnd','CapAmb','NoNewPrivs'} and status['NoNewPrivs']=='1' and all(int(v,16)==0 for k,v in status.items() if k!='NoNewPrivs'),'Runtime capabilities')
  for wanted in p['ip_commands']:
   got=[v for v in k['commands'] if v['argv']==wanted['argv']]
   require(len(got)==1 and got[0]['returncode']==0 and not got[0]['stderr'] and ' '.join(got[0]['stdout'].split())==wanted['stdout'],'Runtime tool mismatch')
  listeners=[]
  for path in ['/proc/net/tcp','/proc/net/tcp6','/proc/net/udp','/proc/net/udp6']:
   lines=proc[path].splitlines();require(bool(lines) and 'local_address' in lines[0],'Incomplete socket table')
   for line in lines[1:]:
    parts=line.split();local,remote,state=parts[1:4]
    require(path=='/proc/net/tcp','Unexpected UDP/IPv6 socket')
    address,port=local.split(':');peer,peer_port=remote.split(':')
    require(address.endswith('7F') and (peer.endswith('7F') or (peer=='00000000' and state=='0A')),'Non-loopback socket')
    if state=='0A':require(int(port,16) in ports,'Unexpected loopback listener');listeners.append(int(port,16))
  return {'result':'PASS','netns':k['netns'],'listeners':sorted(listeners),'egress_routes':0,'forwarding':False}
 except (KeyError,ValueError,TypeError,IndexError) as e:raise IsolationError('Runtime evidence incomplete: '+str(e)) from e
