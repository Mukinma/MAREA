"""Laboratory isolation verifier (legacy predicate, before regression fix)."""
class IsolationError(RuntimeError):pass

def validate_snapshot(snapshot,mode):
    if [x[1] for x in snapshot['kernel']['if_nameindex']] != ['lo']:
        raise IsolationError('Non-loopback interface')
    return {'result':'PASS'}

def validate_pair(anchor,shared):
    validate_snapshot(anchor,'none')
    return validate_snapshot(shared,'container:'+anchor['inspect']['Id'])

def guarded_start(preflight,start):
    if preflight() != {'result':'PASS'}:raise IsolationError('Preflight failed')
    return start()
