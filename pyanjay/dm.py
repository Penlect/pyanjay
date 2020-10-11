import functools
import threading

# Todo: Create: The LwM2M Client MUST ignore optional resources it
# does not support in the payload. If the LwM2M Client supports
# optional resources not present in the payload, it MUST NOT
# instantiate these optional resources.

from pyanjay._dm import R, W, RW, E, ObjectDef


class ID:

    seen = set()

    def __init__(self, id):
        self.id = id
        # if id in self.seen:
        #     raise Exception(f'Duplicated ID: {id}')
        self.seen.add(id)

    def __call__(self, entity):
        if issubclass(entity, (R, W, RW, E)):
            entity.rid = self.id
        elif issubclass(entity, ObjectDef):
            entity.oid = self.id
        else:
            raise TypeError(f'Can\'t assign ID to {entity}')
        return entity
