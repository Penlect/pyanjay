import threading
import logging
import sys

from pyanjay.anjay import Anjay
from pyanjay.dm import DM


FMT_PYANJAY = \
    '%(asctime)s %(threadName)s: %(module)s(%(lineno)d) '\
    '%(levelname)s [pyanjay]: %(message)s'
formatter = logging.Formatter(fmt=FMT_PYANJAY)
handler = logging.StreamHandler(stream=sys.stderr)
handler.setFormatter(formatter)
root = logging.getLogger()
root.addHandler(handler)

FMT_ANJAY = \
    '%(asctime)s %(threadName)s: %(module)s(%(lineno)d) %(message)s'
formatter = logging.Formatter(fmt=FMT_ANJAY)
handler = logging.StreamHandler(stream=sys.stderr)
handler.setFormatter(formatter)
logger_anjay = logging.getLogger('anjay')
logger_anjay.propagate = False
logger_anjay.addHandler(handler)


from pyanjay.data import *


class PyAnjay(Anjay):
    pass

def run_client(ep, stop_event):
    a = PyAnjay(ep)
    a.attr_storage_install()
    a.register_security_object()
    a.register_server_object()
    a.register(Device)
    a.run(stop_event)
