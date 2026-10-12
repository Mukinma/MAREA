"""Loopback-only CORS server for non-secret, synthetic pilot visual artifacts."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--directory',type=Path,default=Path('output/tours-pilot'));parser.add_argument('--port',type=int,default=7369);args=parser.parse_args()
class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin','*')
        super().end_headers()
    def do_GET(self):
        name=self.path.split('?')[0]
        if name not in ('/published-view.json','/remote-panorama.jpg'):
            self.send_error(404);return
        super().do_GET()
ThreadingHTTPServer(('127.0.0.1',args.port),partial(Handler,directory=str(args.directory.resolve()))).serve_forever()
