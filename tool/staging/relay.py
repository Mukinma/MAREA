"""Fixed-destination TCP relay. No HTTP proxy, credentials, or business logic."""
import asyncio,json,ipaddress
from pathlib import Path
ROUTES=Path('/config/routes.json')
async def copy(reader,writer):
    try:
        while data:=await asyncio.wait_for(reader.read(65536),120):
            writer.write(data);await writer.drain()
    finally:
        writer.close()
async def handle(reader,writer,port):
    upstream=None
    try:
        config=json.loads(ROUTES.read_text())
        target=config['routes'][str(port)]
        address=ipaddress.ip_address(target['ip'])
        if address not in ipaddress.ip_network(config['internal_subnet']) or target['port'] not in (5432,8000,8025):raise ValueError('Unapproved upstream')
        ur,upstream=await asyncio.wait_for(asyncio.open_connection(str(address),target['port']),5)
        await asyncio.gather(copy(reader,upstream),copy(ur,writer))
    except (OSError,ValueError,KeyError,asyncio.TimeoutError):pass
    finally:
        writer.close()
        if upstream:upstream.close()
async def main():
    # The process cannot listen until the namespace firewall has been installed.
    while not Path('/config/firewall-ready').exists():await asyncio.sleep(.1)
    servers=[]
    for port in (61001,61002,61004):
        servers.append(await asyncio.start_server(lambda r,w,p=port:handle(r,w,p),'0.0.0.0',port,limit=65536))
    await asyncio.gather(*(s.serve_forever() for s in servers))
asyncio.run(main())
