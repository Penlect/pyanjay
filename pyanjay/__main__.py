"""pyanjay CLI entrypoint"""

# Built-in
import argparse
import logging
import threading
import time

# Package
from pyanjay.client import run_client

# CLI
parser = argparse.ArgumentParser()
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


def main(args):
    e = threading.Event()
    threads = list()
    for i in range(args.n):
        name = f'urn:imei:{i:015}'.encode()
        t = threading.Thread(target=run_client, args=(name, e))
        t.start()
        threads.append(t)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print('Settings stop event ...')
        e.set()
    finally:
        for t in threads:
            t.join()
    print('Bye')

main(args)
