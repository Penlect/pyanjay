"""Default implementations of built-in objects"""

# Project
from pyanjay.dm import *

__all__ = [
    'Device'
]

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
