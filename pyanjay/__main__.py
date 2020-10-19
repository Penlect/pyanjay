"""pyanjay CLI entrypoint"""

# Built-in
import argparse
import logging
import sys
import threading
import time
import inspect
import pkg_resources

# Package
import pyanjay.builtinobj
from pyanjay.anjay import Anjay
from pyanjay.dm import ObjectDef


FMT_PYANJAY = \
    '%(asctime)s %(threadName)s: %(module)s(%(lineno)d) '\
    '%(levelname)s [pyanjay]: %(message)s'
formatter = logging.Formatter(fmt=FMT_PYANJAY)
handler = logging.StreamHandler(stream=sys.stderr)
handler.setFormatter(formatter)
logger_pyanjay = logging.getLogger('pyanjay')
logger_pyanjay.propagate = False
logger_pyanjay.addHandler(handler)

FMT_ANJAY = \
    '%(asctime)s %(threadName)s: %(module)s(%(lineno)d) %(message)s'
formatter = logging.Formatter(fmt=FMT_ANJAY)
handler = logging.StreamHandler(stream=sys.stderr)
handler.setFormatter(formatter)
logger_anjay = logging.getLogger('anjay')
logger_anjay.propagate = False
logger_anjay.addHandler(handler)


# CLI
parser = argparse.ArgumentParser()
parser.add_argument(
    '--server-uri', '-u',
    type=str,
    default='coap://localhost:5683',
)
parser.add_argument(
    '-n',
    type=int,
    default=1,
    help='Nr of clients')
parser.add_argument(
    "-l", "--log-level",
    choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
    default='WARNING',
    help="Set the logging level")
args = parser.parse_args()

# Setup logging
root = logging.getLogger()
root.setLevel(args.log_level)
logger_anjay = logging.getLogger('anjay')
logger_anjay.setLevel(args.log_level)

entry_points = pkg_resources.iter_entry_points(group='pyanjay.objects')
for ep in entry_points:
    print(ep)


def run_client(ep, stop_event):
    a = Anjay(ep)
    a.attr_storage_install()
    a.register_security_object(server_uri=args.server_uri)
    a.register_server_object()
    for key in pyanjay.builtinobj.__all__:
        obj = pyanjay.builtinobj.__dict__[key]
        if inspect.isclass(obj) and issubclass(obj, ObjectDef):
            a.register(obj)
    a.run(stop_event)


def main(args):
    stop_event = threading.Event()
    threads = list()
    for i in range(args.n):
        name = f'urn:imei:{i:015}'.encode()
        t = threading.Thread(target=run_client, args=(name, stop_event))
        t.start()
        threads.append(t)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print('Settings stop event ...')
        stop_event.set()
    finally:
        for t in threads:
            t.join()
    print('Bye')


main(args)
