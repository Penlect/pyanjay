import functools
import threading

# Todo: Create: The LwM2M Client MUST ignore optional resources it
# does not support in the payload. If the LwM2M Client supports
# optional resources not present in the payload, it MUST NOT
# instantiate these optional resources.

class Resource:

    rid = None

    def __init__(self, value, present=True):
        """Initialization of Resource"""
        self.present = present
        self.value = value
        self.changed = False  # TODO: NOT SAFE
        self.name = ''
        self.lock = threading.Lock()

    def __get__(self, instance, owner=None):
        return self.value

    def __set__(self, instance, value, notify=True):
        with self.lock:
            if notify and self.value != value:
                self.changed = True
            self.value = value

    def __set_name__(self, owner, name):
        self.name = name

    def __repr__(self):
        return f'{self.name}<{self.rid}>'

    def reset(self):
        pass

    def attributes(self):
        pass


class R(Resource):
    """Read-only Resource"""

    def __set__(self, instance, value):
        raise AttributeError("can't write read-only resource")


class W(Resource):
    """Write-only Resource"""

    def __get__(self, instance, owner=None):
        raise AttributeError("can't read write-only resource")


class RW(Resource):
    """Read/Write Resource"""


class E(Resource):
    """Executable Resource"""

    def __get__(self, instance, owner=None):
        if callable(self.value):
            call = self.value
        else:
            call = self.__call__
        return functools.partial(call, instance, owner)

    def __call__(self, instance, owner=None, argument=''):
        print(self, instance, owner, argument)


class ObjectDef: # ABC Mapping ?

    oid = None

    def __init__(self):
        """Initialization of ObjectDef"""
        self.iid = None
        self.resources = dict()
        for item in vars(self.__class__).values():
            if isinstance(item, (R, W, RW, E)):
                self.resources[item.rid] = item

    def __repr__(self):
        res = [v for k, v in sorted(self.resources.items())]
        return f'{self.__class__.__name__}<{self.oid}/{self.iid}>{res}'

    def __getitem__(self, rid):
        rid = int(rid)
        return self.resources[rid]

    def __iter__(self):
        return iter(self.resources.values())

    def reset(self):
        pass

    def attributes(self):
        pass


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
