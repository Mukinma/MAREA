"""Fail-closed verifier for EMPTY disposable local containers. Does not start E2-A.
Only kernel-local queries; no IP connections. Unknown configurations fail.
"""
import hashlib, json, re
from pathlib import Path
HERE=Path(__file__).resolve().parent
IMAGE='sha256:c0d4530ddaae7a3295b5f8dbb8f60557884660bde2675df064cd67c9dd3b7983'
LINK_ATTRS={'1','2','3','4','5','6','10','16','17','18','27','28','37'}
class IsolationError(RuntimeError):pass

def require(condition,message):
    if not condition:raise IsolationError(message)

def policy():return json.loads((HERE/'e2a_isolation_policy.json').read_text())

def canonical_netlink(n):
    return {
        'links':[{**v,'attrs':{k:w for k,w in v['attrs'].items() if k in LINK_ATTRS}} for v in n['links']],
        'addresses':[{**v,'attrs':{k:w for k,w in v['attrs'].items() if k!='6'}} for v in n['addresses']],
        'routes':[{**v,'attrs':{k:w for k,w in v['attrs'].items() if k!='12'}} for v in n['routes']],
        'rules':n['rules']}

def validate_snapshot(s,mode):
    """Validate independent views and fixed inert templates, ONLY loopback routing.

    The profile contains complete LINKINFO tunnel configuration (no remote endpoint
    or underlying link), not a name-only exception. Templates are DOWN/unaddressed/
    unrouted, with no capabilities. Unknown/active interfaces or routes fail closed.
    """
    try:
        p=policy();c=s['inspect'];h=c['HostConfig'];k=s['kernel'];n=s['netlink'];proc=k['proc']
        require(mode=='none' or re.fullmatch(r'container:[a-f0-9]{64}',mode),'Invalid expected mode')
        require(h['NetworkMode']==mode,'Declared NetworkMode mismatch')
        require(c['Image']==IMAGE==p['image'] and c['Config']['User']=='1000:1000','Unexpected image/user')
        require(c['State']['Running'] and c['State']['Pid']>0,'Container not running')
        require(h['ReadonlyRootfs'] is True and h['Privileged'] is False,'Unsafe rootfs/privilege')
        require(h['CapDrop']==['ALL'] and not h.get('CapAdd'),'Capabilities not fully dropped')
        require(h['SecurityOpt']==['no-new-privileges'],'Missing no-new-privileges')
        require(not c['Mounts'] and not h.get('Binds') and not h.get('Devices') and not h.get('DeviceRequests'),'Mount/device forbidden')
        require(not h.get('PortBindings') and not h['PublishAllPorts'] and not c['NetworkSettings']['Ports'],'Published ports forbidden')
        require(not h.get('Links') and not h.get('ExtraHosts') and not h.get('Dns') and not h.get('DnsSearch'),'External resolution/link config')
        networks=c['NetworkSettings']['Networks']
        if mode=='none':
            require(set(networks)=={'none'},'Unexpected Docker network')
            net=networks['none']
            require(all(not net[key] for key in ['Gateway','IPAddress','MacAddress','IPv6Gateway','GlobalIPv6Address','IPPrefixLen','GlobalIPv6PrefixLen']),'Effective Docker address/gateway')
            require(not net['IPAMConfig'] and not net['Links'] and not net['Aliases'],'Unexpected endpoint config')
            require(h['Sysctls']=={'net.ipv4.ip_forward':'0','net.ipv6.conf.all.forwarding':'0'},'Forwarding configuration not explicit')
        else:require(not networks,'Shared container has independent endpoint')
        require(re.fullmatch(r'net:\[\d+\]',k['netns']) is not None,'Invalid namespace')
        require(k['netns']==k['pid1_netns']==n['netns']==f"net:[{k['netns_inode']}]",'Effective namespace inconsistent')
        status=dict(re.findall(r'^(Cap(?:Inh|Prm|Eff|Bnd|Amb)|NoNewPrivs):\s*(\S+)',proc['/proc/self/status'],re.M))
        require(set(status)=={'CapInh','CapPrm','CapEff','CapBnd','CapAmb','NoNewPrivs'},'Incomplete privileges')
        require(status['NoNewPrivs']=='1' and all(int(status[key],16)==0 for key in status if key!='NoNewPrivs'),'Effective privilege escalation possible')
        require(proc['/proc/sys/net/ipv4/ip_forward'].strip()=='0' and proc['/proc/sys/net/ipv6/conf/all/forwarding'].strip()=='0','Forwarding enabled')
        actual=canonical_netlink(n)
        for key in ['links','addresses','routes','rules']:require(actual[key]==p[key],'Unexpected/incomplete netlink '+key)
        expected=[[v['index'],v['name']] for v in n['links']]
        require(k['if_nameindex']==expected,'socket.if_nameindex mismatch')
        require(k['sysfs']==p['sysfs'],'Unexpected/inconsistent sysfs links')
        require(all(int(k['sysfs'][name]['ifindex'])==i for i,name in expected),'sysfs index mismatch')
        proc_names=[line.split(':')[0].strip() for line in proc['/proc/net/dev'].splitlines()[2:] if ':' in line]
        require(sorted(proc_names)==sorted(v[1] for v in expected),'proc interface mismatch')
        require(len(proc['/proc/net/route'].splitlines())==1 and proc['/proc/net/route'].startswith('Iface\tDestination'),'Unexpected/incomplete proc IPv4 routes')
        v6=[[v for i,v in enumerate(line.split()) if i not in [6,7]] for line in proc['/proc/net/ipv6_route'].splitlines()]
        require(v6==p['proc_ipv6_routes'],'Unexpected/incomplete proc IPv6 routes')
        require(proc['/proc/net/if_inet6'].split()==p['proc_inet6'],'Unexpected IPv6 address')
        for wanted in p['ip_commands']:
            matches=[v for v in k['commands'] if v['argv']==wanted['argv']]
            require(len(matches)==1,'Missing/duplicate ip command')
            got=matches[0]
            require(got['returncode']==0 and not got['stderr'] and ' '.join(got['stdout'].split())==wanted['stdout'],'ip view inconsistent/failed')
        for path in ['/proc/net/tcp','/proc/net/tcp6','/proc/net/udp','/proc/net/udp6']:
            require(len(proc[path].splitlines())==1,'Empty lab has unexpected sockets')
        return {'result':'PASS','mode':mode,'netns':k['netns'],'active_interfaces':['lo'],'inert_kernel_templates':len(n['links'])-1,'egress_routes':0,'published_ports':0,'policy_sha256':hashlib.sha256((HERE/'e2a_isolation_policy.json').read_bytes()).hexdigest()}
    except (KeyError,TypeError,ValueError,AttributeError,OSError) as e:
        raise IsolationError('Incomplete/inconsistent evidence: '+str(e)) from e

def validate_pair(anchor,shared):
    a=validate_snapshot(anchor,'none');b=validate_snapshot(shared,'container:'+anchor['inspect']['Id'])
    require(a['netns']==b['netns'],'Declared shared namespace differs from effective namespace')
    require(anchor['inspect']['Id']!=shared['inspect']['Id'],'Shared helper is not independent process/container')
    require(canonical_netlink(anchor['netlink'])==canonical_netlink(shared['netlink']),'Shared namespace views disagree')
    return {'result':'PASS','anchor':a,'shared':b}

def guarded_start(preflight,start):
    """Ordering primitive: callback is NEVER invoked without PASS first."""
    receipt=preflight()
    require(isinstance(receipt,dict) and receipt.get('result')=='PASS','Preflight did not prove isolation')
    return start()

def capture_empty(name,docker):
    """Logged local Docker invocation; reject incompatible metadata BEFORE exec."""
    c=json.loads(docker('inspect',name))[0]
    require(c['Image']==IMAGE and not c['Mounts'],'Probe requires empty pinned helper without mounts')
    require(c['HostConfig']['NetworkMode']=='none' or c['HostConfig']['NetworkMode'].startswith('container:'),'Probe refuses incompatible NetworkMode')
    data=json.loads(docker('exec',name,'python','-c',(HERE/'e2a_isolation_probe.py').read_text()))
    return {'inspect':c,**data}
