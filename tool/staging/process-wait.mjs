export function settledExit(child){return child.exitCode!==null||child.signalCode!==null?Promise.resolve(child.exitCode):new Promise(r=>child.once('exit',r));}
