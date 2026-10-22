"""Isolation regression tests; negative fixtures never configure unsafe networks."""
import copy, json, unittest
from pathlib import Path
from unittest.mock import Mock
from e2a_isolation import IsolationError, validate_snapshot, validate_pair, guarded_start

RUN=Path(__file__).resolve().parents[2]/'docs/evidence/2026-10-19/task002/run-20261019T133800Z-isolation'

class IsolationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((RUN/'05-config-corrected-capture.json').read_text())

    def test_original_predicate_reproduced(self):
        for s in self.data.values():self.assertFalse(s['kernel']['legacy_predicate'])

    def test_isolated_shared_namespace_positive(self):
        self.assertEqual(validate_pair(self.data['anchor'],self.data['shared'])['result'],'PASS')

    def test_independent_namespace_positive(self):
        self.assertEqual(validate_snapshot(self.data['independent'],'none')['result'],'PASS')
        self.assertNotEqual(self.data['anchor']['kernel']['netns'],self.data['independent']['kernel']['netns'])

    def reject(self,label,mutation):
        with self.subTest(case=label):
            s=copy.deepcopy(self.data['anchor']);mutation(s)
            with self.assertRaises(IsolationError):validate_snapshot(s,'none')

    def test_unexpected_interfaces(self):
        self.reject('new eth0',lambda s:s['kernel']['if_nameindex'].append([11,'eth0']))
        self.reject('hidden netlink interface',lambda s:s['netlink']['links'].append(copy.deepcopy(s['netlink']['links'][1])))
        self.reject('renamed template',lambda s:s['netlink']['links'][1].update(name='eth0'))
        self.reject('active template',lambda s:s['netlink']['links'][1].update(flags=129))
        self.reject('configured tunnel remote',lambda s:s['netlink']['links'][1]['linkinfo'].update({'2':'080003000a000001'}))
        self.reject('sysfs interface up',lambda s:s['kernel']['sysfs']['gre0'].update(flags='0x81\n'))
        self.reject('proc-only interface',lambda s:s['kernel']['proc'].update({'/proc/net/dev':s['kernel']['proc']['/proc/net/dev']+' eth0: 0 0\n'}))

    def test_unexpected_routes_and_addresses(self):
        for family in [2,10]:
            def mutate(s,family=family):
                r=copy.deepcopy(next(r for r in s['netlink']['routes'] if r['family']==family))
                r.update(dst_len=0,type=1,table=254);r['attrs']['5']='0a000001' if family==2 else '20010000000000000000000000000001';s['netlink']['routes'].append(r)
            self.reject('default route '+str(family),mutate)
        self.reject('non-main table route',lambda s:s['netlink']['routes'][0].update(table=100))
        self.reject('extra address',lambda s:s['netlink']['addresses'][0]['attrs'].update({'1':'0a000001'}))
        self.reject('multipath route',lambda s:s['netlink']['routes'][0]['attrs'].update({'9':'01000000'}))
        self.reject('proc IPv4 route',lambda s:s['kernel']['proc'].update({'/proc/net/route':'Iface Destination\neth0 00000000 0100000A\n'}))
        self.reject('proc IPv6 route',lambda s:s['kernel']['proc'].update({'/proc/net/ipv6_route':'0 00 0 00 0 0 0 0 0 eth0\n'}))
        self.reject('routing rule',lambda s:s['netlink']['rules'][0].update(table=100))

    def test_incompatible_docker_config(self):
        for mode in ['host','bridge','default','container:other']:
            self.reject('NetworkMode '+mode,lambda s,mode=mode:s['inspect']['HostConfig'].update(NetworkMode=mode))
        self.reject('published port',lambda s:s['inspect']['HostConfig'].update(PortBindings={'9999/tcp':[{'HostPort':'9999'}]}))
        self.reject('effective port',lambda s:s['inspect']['NetworkSettings'].update(Ports={'80/tcp':[{}]}))
        self.reject('extra network',lambda s:s['inspect']['NetworkSettings']['Networks'].update(bridge={}))
        self.reject('effective IP',lambda s:s['inspect']['NetworkSettings']['Networks']['none'].update(IPAddress='10.0.0.2'))
        self.reject('privileged',lambda s:s['inspect']['HostConfig'].update(Privileged=True))
        self.reject('NET_ADMIN',lambda s:s['inspect']['HostConfig'].update(CapAdd=['NET_ADMIN']))
        self.reject('cap drop lost',lambda s:s['inspect']['HostConfig'].update(CapDrop=[]))
        self.reject('volume',lambda s:s['inspect'].update(Mounts=[{'Type':'volume','Name':'x'}]))
        self.reject('forwarding',lambda s:s['kernel']['proc'].update({'/proc/sys/net/ipv4/ip_forward':'1\n'}))
        self.reject('effective capabilities',lambda s:s['kernel']['proc'].update({'/proc/self/status':s['kernel']['proc']['/proc/self/status'].replace('CapEff:\t0000000000000000','CapEff:\t0000000000001000')}))
        self.reject('unexpected listener',lambda s:s['kernel']['proc'].update({'/proc/net/tcp':s['kernel']['proc']['/proc/net/tcp']+'0: 00000000:270F 00000000:0000 0A\n'}))

    def test_namespace_mismatch(self):
        with self.assertRaises(IsolationError):validate_pair(self.data['anchor'],self.data['independent'])
        shared=copy.deepcopy(self.data['shared']);shared['inspect']['HostConfig']['NetworkMode']='container:'+self.data['independent']['inspect']['Id']
        with self.assertRaises(IsolationError):validate_pair(self.data['anchor'],shared)
        shared=copy.deepcopy(self.data['shared'])
        for key in ['netns','netns_inode','pid1_netns']:shared['kernel'][key]=self.data['independent']['kernel'][key]
        shared['netlink']['netns']=shared['kernel']['netns']
        with self.assertRaisesRegex(IsolationError,'Declared shared namespace'):validate_pair(self.data['anchor'],shared)
        self.reject('netlink namespace',lambda s:s['netlink'].update(netns='net:[999]'))
        self.reject('PID1 namespace',lambda s:s['kernel'].update(pid1_netns='net:[999]'))
        self.reject('namespace inode',lambda s:s['kernel'].update(netns_inode=999))

    def test_incomplete_inconsistent_evidence_fails_closed(self):
        for key in ['inspect','kernel','netlink']:
            self.reject('missing '+key,lambda s,key=key:s.pop(key))
        for key in ['links','addresses','routes','rules']:
            self.reject('missing netlink '+key,lambda s,key=key:s['netlink'].pop(key))
            self.reject('empty netlink '+key,lambda s,key=key:s['netlink'].update({key:[]}))
        self.reject('sysfs index',lambda s:s['kernel']['sysfs']['lo'].update(ifindex='999\n'))
        self.reject('sysfs missing',lambda s:s['kernel'].update(sysfs={}))
        self.reject('proc missing',lambda s:s['kernel']['proc'].pop('/proc/net/route'))
        self.reject('command failure',lambda s:s['kernel']['commands'][3].update(returncode=1))
        self.reject('command missing',lambda s:s['kernel'].update(commands=[]))
        self.reject('incomplete privilege evidence',lambda s:s['kernel']['proc'].update({'/proc/self/status':'NoNewPrivs:\t1\n'}))
        self.reject('proc sockets missing',lambda s:s['kernel']['proc'].pop('/proc/net/tcp'))

    def test_preflight_precedes_service_callback(self):
        events=[]
        def preflight():events.append('preflight');return {'result':'PASS'}
        def service():events.append('empty_service_callback');return 1
        self.assertEqual(guarded_start(preflight,service),1)
        self.assertEqual(events,['preflight','empty_service_callback'])

    def test_preflight_failure_never_starts_service(self):
        service=Mock()
        for value in [None,{}, {'result':'FAIL'}]:
            with self.assertRaises(IsolationError):guarded_start(lambda:value,service)
        def failed():raise IsolationError('unproven')
        with self.assertRaises(IsolationError):guarded_start(failed,service)
        service.assert_not_called()

    def test_archived_E2A_entrypoints_cannot_resume(self):
        import e2a_lab
        from unittest.mock import patch
        with patch.object(e2a_lab,'docker') as docker:
            for call in [e2a_lab.bootstrap,e2a_lab.red,lambda:e2a_lab.boot('a'),lambda:e2a_lab.auth_start('a')]:
                with self.assertRaisesRegex(RuntimeError,'new specific human approval'):call()
            docker.assert_not_called()

    def test_archived_Docker_dispatch_is_blocked(self):
        import e2a_lab
        from unittest.mock import patch
        with patch.object(e2a_lab.subprocess,'run') as run:
            with self.assertRaisesRegex(RuntimeError,'new specific human approval'):e2a_lab.docker('ps')
            run.assert_not_called()

if __name__=='__main__':unittest.main(verbosity=2)
