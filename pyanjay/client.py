import threading
import logging
import sys

from pyanjay.anjay import Anjay
from pyanjay._dm import DM
from pyanjay.dm import *


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


class PyAnjay(Anjay):
    pass


@ID(4)
class Reboot(E):
    pass

@ID(15)
class Timezone(RW):
    pass

@ID(16)
class SupportedBindingAndModes(R):
    pass


@ID(3)
class Device(ObjectDef):

    reboot = Reboot(None)
    timezone = Timezone('FooBar')
    supported_binding_and_modes = SupportedBindingAndModes('U')


def run_client(ep, stop_event):
    a = PyAnjay(ep)
    a.attr_storage_install()
    a.register_security_object()
    a.register_server_object()
    a.register(Device)
    a.run(stop_event)
