
# Built-in
import threading
import logging

from libc.stdint cimport (
    uint8_t, uint16_t, uint32_t, int32_t)
from libc.string cimport strcpy
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from pyanjay.data import R, W, RW, E

LOG = logging.getLogger('pyanjay.datamodel')

class AnjayErrorWithCoapStatus(Exception):
    pass

class ErrMethodNotAllowed(AnjayErrorWithCoapStatus):
    COAP_STATUS = ANJAY_ERR_METHOD_NOT_ALLOWED

class ErrInternal(AnjayErrorWithCoapStatus):
    COAP_STATUS = ANJAY_ERR_INTERNAL

class ErrNotFound(AnjayErrorWithCoapStatus):
    COAP_STATUS = ANJAY_ERR_NOT_FOUND

class ErrNotImplemented(AnjayErrorWithCoapStatus):
    COAP_STATUS = ANJAY_ERR_NOT_IMPLEMENTED


cdef dict anjay_lookup = dict()

cdef extern from "stdbool.h":
    ctypedef bint cbool "bool"


cdef class DM:

    def __cinit__(self, factory, version=None):
        self.objdef = <anjay_dm_object_def_t *> PyMem_Malloc(sizeof(anjay_dm_object_def_t))
        if not self.objdef:
            raise MemoryError('Object definition')
        self.objdef.oid = factory.oid
        self.objdef.version = NULL
        self.objdef.handlers.object_read_default_attrs = NULL
        self.objdef.handlers.object_write_default_attrs = NULL

        self.objdef.handlers.list_instances = self.list_instances
        self.objdef.handlers.instance_reset = self.instance_reset
        self.objdef.handlers.instance_create = NULL
        self.objdef.handlers.instance_remove = NULL
        self.objdef.handlers.instance_read_default_attrs = NULL
        self.objdef.handlers.instance_write_default_attrs = NULL

        self.objdef.handlers.list_resources = self.list_resources
        self.objdef.handlers.resource_read = self.resource_read
        self.objdef.handlers.resource_write = self.resource_write
        self.objdef.handlers.resource_execute = self.resource_execute
        self.objdef.handlers.resource_reset = self.resource_reset
        self.objdef.handlers.list_resource_instances = NULL
        self.objdef.handlers.resource_read_attrs = NULL
        self.objdef.handlers.resource_write_attrs = NULL

        self.objdef.handlers.transaction_begin = anjay_dm_transaction_NOOP
        self.objdef.handlers.transaction_validate = anjay_dm_transaction_NOOP
        self.objdef.handlers.transaction_commit = anjay_dm_transaction_NOOP
        self.objdef.handlers.transaction_rollback = anjay_dm_transaction_NOOP

        self.factory = factory
        self.instances_lock = threading.Lock()
        self.instances = dict()

    def __dealloc__(self):
        if self.objdef != NULL:
            PyMem_Free(self.objdef)

    def __init__(self, factory):
        self.instances[0] = factory()
        LOG.debug('init done')

    @staticmethod
    cdef object fetch(anjay_t *anjay=NULL,
                      const anjay_dm_object_def_t *const *obj_ptr=NULL,
                      iid=None, rid=None, riid=None):
        if anjay == NULL:
            return ()

        # Anjay instance
        cdef void *p = <void*>anjay
        cdef long i = <long>p
        try:
            py_anjay = anjay_lookup[i]
        except KeyError as error:
            raise ErrInternal(
                'Failed to find anjay instance %r in '
                'lookup mapping', i) from error
        if obj_ptr == NULL:
            return (py_anjay,)

        # Object definition
        cdef DM self
        try:
            self = py_anjay[obj_ptr[0][0].oid]
        except KeyError as error:
            raise ErrNotFound('Failed to find DM instance %r',
                              obj_ptr[0][0].oid) from error
        if iid is None:
            return (py_anjay, self)

        # Object instance
        try:
            inst = self.instances[iid]
        except KeyError:
            LOG.exception('Failed to get instance %d of %r', iid, self)
            return ErrNotFound.COAP_STATUS
        if rid is None:
            return (py_anjay, self, inst)

        # Resource
        try:
            res = inst.resources[rid]
        except KeyError:
            LOG.exception('Failed to get resource %d of %r', rid, inst)
            return ErrNotFound.COAP_STATUS
        if riid is None:
            return (py_anjay, self, inst, res)

        # Resource instance
        try:
            value = res.instances[riid]
        except KeyError:
            LOG.exception('Failed to get resource instance %d of %r', riid, res)
            return ErrNotFound.COAP_STATUS
        return (py_anjay, self, inst, res, value)

    def __repr__(self):
        return f'{self.__class__.__name__}({self.factory!r})'

    @property
    def oid(self):
        return self.objdef.oid

    @property
    def version(self):
        if self.objdef.version == NULL:
            return None
        return self.objdef.version

    @staticmethod
    cdef int list_instances(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_dm_list_ctx_t *ctx):
        LOG.debug('list_instances handler called')
        cdef DM self
        try:
            _, self = DM.fetch(anjay, obj_ptr)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS
        with self.instances_lock:
            for iid, inst in self.instances.items():
                LOG.debug('list_instances %r', inst)
                anjay_dm_emit(ctx, iid)
        return 0

    @staticmethod
    cdef int instance_reset(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid):
        LOG.debug('instance_reset handler called')
        try:
            _, _, inst = DM.fetch(anjay, obj_ptr, iid)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS
        try:
            inst.reset()
        except Exception:
            LOG.exception('Failed to reset instance %r', inst)
            return ErrInternal.COAP_STATUS
        return 0

    @staticmethod
    cdef int list_resources(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid,
                            anjay_dm_resource_list_ctx_t *ctx):
        LOG.debug('list_resources handler called')
        try:
            _, _, inst = DM.fetch(anjay, obj_ptr, iid)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS
        cdef anjay_dm_resource_kind_t kind
        cdef anjay_dm_resource_presence_t presence
        # Todo: threadsafe
        for rid, res in inst.resources.items():
            if getattr(res, 'present', True):
                presence = ANJAY_DM_RES_PRESENT
            else:
                presence = ANJAY_DM_RES_ABSENT
            if isinstance(res, R):
                kind = ANJAY_DM_RES_R
            elif isinstance(res, W):
                kind = ANJAY_DM_RES_W
            elif isinstance(res, RW):
                kind = ANJAY_DM_RES_RW
            elif isinstance(res, E):
                kind = ANJAY_DM_RES_E
            else:
                return ErrNotImplemented.COAP_STATUS
            LOG.debug('list_resources %r kind=%d, presence=%d', res, kind, presence)
            anjay_dm_emit_res(ctx, rid, kind, presence)
        return 0

    @staticmethod
    cdef int resource_read(anjay_t *anjay,
                           const anjay_dm_object_def_t *const *obj_ptr,
                           anjay_iid_t iid,
                           anjay_rid_t rid,
                           anjay_riid_t riid,
                           anjay_output_ctx_t *ctx):
        LOG.debug('resource_read handler called')
        try:
            _, _, inst, res = DM.fetch(anjay, obj_ptr, iid, rid)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS
        try:
            value = getattr(inst, res.name)
        except Exception:
            LOG.exception('Failed to get value of resource %r', res)
            return ErrInternal.COAP_STATUS
        LOG.debug('resource_read %r -> %r', res, value)
        if isinstance(value, (bytes, bytearray)):
            return anjay_ret_string(ctx, value)
        if isinstance(value, str):
            return anjay_ret_string(ctx, value.encode())
        if isinstance(value, int):
            return anjay_ret_i64(ctx, value)
        if isinstance(value, float):
            return anjay_ret_double(ctx, value)
        if isinstance(value, bool):
            return anjay_ret_bool(ctx, value)
        return ANJAY_ERR_NOT_IMPLEMENTED

    @staticmethod
    cdef int resource_write(anjay_t *anjay,
                        const anjay_dm_object_def_t *const *obj_ptr,
                        anjay_iid_t iid,
                        anjay_rid_t rid,
                        anjay_riid_t riid,
                        anjay_input_ctx_t *ctx):
        LOG.debug('resource_write handler called')
        try:
            _, _, inst, res = DM.fetch(anjay, obj_ptr, iid, rid)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS

        # Candidates
        cdef int64_t i
        cdef double f
        cdef cbool b
        cdef char *s = NULL

        # Todo: notification

        LOG.debug('resource_write %r value has type %r', res,
                  res.value.__class__.__name__)
        if isinstance(res.value, bool):  # Must be before int
            if anjay_get_bool(ctx, &b):
                LOG.error('Failed to interpret input value as a bool')
                return ErrInternal.COAP_STATUS
            value = bool(<int>b)
        elif isinstance(res.value, int):
            if anjay_get_i64(ctx, &i):
                LOG.error('Failed to interpret input value as an int64')
                return ErrInternal.COAP_STATUS
            value = i
        elif isinstance(res.value, float):
            if anjay_get_double(ctx, &f):
                LOG.error('Failed to interpret input value as a double')
                return ErrInternal.COAP_STATUS
            value = f
        else:
            s = <char *> PyMem_Malloc(256)
            if not s:
                return ErrInternal.COAP_STATUS
            try:
                if anjay_get_string(ctx, s, 256):
                    LOG.error('Failed to interpret input value as a string')
                    return ErrInternal.COAP_STATUS
                value = s
            finally:
                PyMem_Free(s)

        if isinstance(res.value, str):
            value = value.decode()
        LOG.debug('resource_write %r <- %r', res, value)
        try:
            setattr(inst, res.name, value)
        except Exception:
            LOG.exception('Failed to set value %r to resource %r', value, res)
            return ErrInternal.COAP_STATUS

    @staticmethod
    cdef int resource_execute(anjay_t *anjay,
                              const anjay_dm_object_def_t *const *obj_ptr,
                              anjay_iid_t iid,
                              anjay_rid_t rid,
                              anjay_execute_ctx_t *ctx):
        LOG.debug('resource_execute handler called')
        cdef DM self
        try:
            _, self, inst, res = DM.fetch(anjay, obj_ptr, iid, rid)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS
        LOG.debug('resource_execute %r, args=""', res) # TODO
        return 0

    @staticmethod
    cdef int resource_reset(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid,
                            anjay_rid_t rid):
        LOG.debug('resource_reset handler called')
        cdef DM self
        try:
            _, self, inst, res = DM.fetch(anjay, obj_ptr, iid, rid)
        except AnjayErrorWithCoapStatus as error:
            return error.COAP_STATUS
        LOG.debug('resource_reset %r', res) # TODO
        return 0