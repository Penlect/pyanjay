
from libc.stdint cimport (
    uint8_t, uint16_t, uint32_t, int32_t, int64_t)

cdef extern from "stdbool.h":
    ctypedef bint cbool "bool"

cdef extern from "anjay/anjay.h":
        
    ctypedef struct anjay_t

    ctypedef uint16_t anjay_ssid_t
    ctypedef uint16_t anjay_oid_t
    ctypedef uint16_t anjay_iid_t
    ctypedef uint16_t anjay_rid_t
    ctypedef uint16_t anjay_riid_t

    cdef struct anjay_dm_object_def_struct

    ctypedef anjay_dm_object_def_struct anjay_dm_object_def_t

    ctypedef struct anjay_dm_oi_attributes_t:
        int32_t min_period
        int32_t max_period
        int32_t min_eval_period
        int32_t max_eval_period
        
    ctypedef struct anjay_dm_r_attributes_t:
        anjay_dm_oi_attributes_t common
        double greater_than
        double less_than
        double step

    ctypedef int anjay_dm_object_read_default_attrs_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_ssid_t ssid,
        anjay_dm_oi_attributes_t *out)

    ctypedef int anjay_dm_object_write_default_attrs_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_ssid_t ssid,
        const anjay_dm_oi_attributes_t *attrs)
    
    ctypedef struct anjay_dm_list_ctx_t:
        pass

    cdef void anjay_dm_emit(anjay_dm_list_ctx_t *ctx, uint16_t id)

    ctypedef int anjay_dm_list_instances_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_dm_list_ctx_t *ctx)

    cdef int anjay_dm_list_instances_SINGLE(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_dm_list_ctx_t *ctx)
    
    ctypedef int anjay_dm_instance_reset_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid)

    ctypedef int anjay_dm_instance_create_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid)

    ctypedef int anjay_dm_instance_remove_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid)

    ctypedef int anjay_dm_instance_read_default_attrs_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_ssid_t ssid,
        anjay_dm_oi_attributes_t *out)

    ctypedef int anjay_dm_instance_write_default_attrs_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_ssid_t ssid,
        const anjay_dm_oi_attributes_t *attrs)

    ctypedef struct anjay_dm_resource_list_ctx_t:
        pass
    
    ctypedef int anjay_dm_list_resources_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_dm_resource_list_ctx_t *ctx)

    ctypedef struct anjay_output_ctx_t:
        pass

    ctypedef int anjay_dm_resource_read_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid,
        anjay_riid_t riid,
        anjay_output_ctx_t *ctx)

    ctypedef struct anjay_input_ctx_t:
        pass

    ctypedef int anjay_dm_resource_write_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid,
        anjay_riid_t riid,
        anjay_input_ctx_t *ctx)

    ctypedef struct anjay_execute_ctx_t:
        pass

    ctypedef int anjay_dm_resource_execute_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid,
        anjay_execute_ctx_t *ctx)

    ctypedef int anjay_dm_resource_reset_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid)

    ctypedef int anjay_dm_list_resource_instances_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid,
        anjay_dm_list_ctx_t *ctx)

    ctypedef int anjay_dm_resource_read_attrs_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid,
        anjay_ssid_t ssid,
        anjay_dm_r_attributes_t *out)

    ctypedef int anjay_dm_resource_write_attrs_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr,
        anjay_iid_t iid,
        anjay_rid_t rid,
        anjay_ssid_t ssid,
        const anjay_dm_r_attributes_t *attrs)

    ctypedef int anjay_dm_transaction_begin_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr)

    ctypedef int anjay_dm_transaction_validate_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr)

    ctypedef int anjay_dm_transaction_commit_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr)

    ctypedef int anjay_dm_transaction_rollback_t(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr)

    cdef int anjay_dm_transaction_NOOP(
        anjay_t *anjay,
        const anjay_dm_object_def_t *const *obj_ptr)

    ctypedef struct anjay_dm_handlers_t:
        anjay_dm_object_read_default_attrs_t *object_read_default_attrs
        anjay_dm_object_write_default_attrs_t *object_write_default_attrs
        
        anjay_dm_list_instances_t *list_instances
        anjay_dm_instance_reset_t *instance_reset
        anjay_dm_instance_create_t *instance_create
        anjay_dm_instance_remove_t *instance_remove
        anjay_dm_instance_read_default_attrs_t *instance_read_default_attrs
        anjay_dm_instance_write_default_attrs_t *instance_write_default_attrs
        
        anjay_dm_list_resources_t *list_resources
        anjay_dm_resource_read_t *resource_read
        anjay_dm_resource_write_t *resource_write
        anjay_dm_resource_execute_t *resource_execute
        anjay_dm_resource_reset_t *resource_reset
        anjay_dm_list_resource_instances_t *list_resource_instances
        anjay_dm_resource_read_attrs_t *resource_read_attrs
        anjay_dm_resource_write_attrs_t *resource_write_attrs
        
        anjay_dm_transaction_begin_t *transaction_begin
        anjay_dm_transaction_validate_t *transaction_validate
        anjay_dm_transaction_commit_t *transaction_commit
        anjay_dm_transaction_rollback_t *transaction_rollback


    struct anjay_dm_object_def_struct:
        anjay_oid_t oid
        char *version
        anjay_dm_handlers_t handlers

    cdef int anjay_register_object(anjay_t *anjay, const anjay_dm_object_def_t *const *def_ptr)
    cdef int anjay_unregister_object(anjay_t *anjay, const anjay_dm_object_def_t *const *def_ptr)
    
    ctypedef enum anjay_dm_resource_kind_t:
        ANJAY_DM_RES_R,
        ANJAY_DM_RES_W,
        ANJAY_DM_RES_RW,
        ANJAY_DM_RES_RM,
        ANJAY_DM_RES_WM,
        ANJAY_DM_RES_RWM,
        ANJAY_DM_RES_E,
        ANJAY_DM_RES_BS_RW

    ctypedef enum anjay_dm_resource_presence_t:
        ANJAY_DM_RES_ABSENT = 0,
        ANJAY_DM_RES_PRESENT = 1

    cdef void anjay_dm_emit_res(
        anjay_dm_resource_list_ctx_t *ctx,
        anjay_rid_t rid,
        anjay_dm_resource_kind_t kind,
        anjay_dm_resource_presence_t presence)

    cdef int anjay_ret_string(anjay_output_ctx_t *ctx, const char *value)
    cdef int anjay_ret_i64(anjay_output_ctx_t *ctx, int64_t value)
    cdef int anjay_ret_double(anjay_output_ctx_t *ctx, double value)
    cdef int anjay_ret_bool(anjay_output_ctx_t *ctx, cbool value)
    cdef int anjay_ret_objlnk(anjay_output_ctx_t *ctx, anjay_oid_t oid, anjay_iid_t iid)

    cdef int anjay_get_string(anjay_input_ctx_t *ctx, char *out_buf, size_t buf_size)
    cdef int anjay_get_i64(anjay_input_ctx_t *ctx, int64_t *out)
    cdef int anjay_get_double(anjay_input_ctx_t *ctx, double *out)
    cdef int anjay_get_bool(anjay_input_ctx_t *ctx, cbool *out)
    cdef int anjay_get_objlnk(anjay_input_ctx_t *ctx, anjay_oid_t *out_oid, anjay_iid_t *out_iid)

    cdef int anjay_execute_get_next_arg(anjay_execute_ctx_t *ctx,
                                        int *out_arg,
                                        cbool *out_has_value)
    cdef int anjay_execute_get_arg_value(anjay_execute_ctx_t *ctx,
                                         size_t *out_bytes_read,
                                         char *out_buf,
                                         size_t buf_size)
    cdef int ANJAY_EXECUTE_GET_ARG_END

    cdef int ANJAY_ERR_BAD_REQUEST
    cdef int ANJAY_ERR_UNAUTHORIZED
    cdef int ANJAY_ERR_BAD_OPTION
    cdef int ANJAY_ERR_FORBIDDEN
    cdef int ANJAY_ERR_NOT_FOUND
    cdef int ANJAY_ERR_METHOD_NOT_ALLOWED
    cdef int ANJAY_ERR_NOT_ACCEPTABLE
    cdef int ANJAY_ERR_REQUEST_ENTITY_INCOMPLETE
    cdef int ANJAY_ERR_UNSUPPORTED_CONTENT_FORMAT
    cdef int ANJAY_ERR_INTERNAL
    cdef int ANJAY_ERR_NOT_IMPLEMENTED
    cdef int ANJAY_ERR_SERVICE_UNAVAILABLE


# cdef class Resource:

#     cdef object instances_lock
#     cdef dict instances


cdef class ObjectDef:

    cdef object resources_lock
    cdef dict resources


cdef dict anjay_lookup


cdef class DM:

    cdef object instances_lock
    cdef dict instances
    cdef object factory

    cdef anjay_dm_object_def_t *objdef

    @staticmethod
    cdef object fetch(anjay_t *anjay=*,
                      const anjay_dm_object_def_t *const *obj_ptr=*,
                      iid=*,
                      rid=*,
                      riid=*)

    # Instance handlers

    @staticmethod
    cdef int list_instances(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_dm_list_ctx_t *ctx)
    @staticmethod
    cdef int instance_reset(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid)
    @staticmethod
    cdef int instance_create(anjay_t *anjay,
                             const anjay_dm_object_def_t *const *obj_ptr,
                             anjay_iid_t iid)
    @staticmethod
    cdef int instance_remove(anjay_t *anjay,
                             const anjay_dm_object_def_t *const *obj_ptr,
                             anjay_iid_t iid)

    # Resource handlers

    @staticmethod
    cdef int list_resources(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid,
                            anjay_dm_resource_list_ctx_t *ctx)

    @staticmethod
    cdef int resource_read(anjay_t *anjay,
                           const anjay_dm_object_def_t *const *obj_ptr,
                           anjay_iid_t iid,
                           anjay_rid_t rid,
                           anjay_riid_t riid,
                           anjay_output_ctx_t *ctx)
    @staticmethod
    cdef int resource_write(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid,
                            anjay_rid_t rid,
                            anjay_riid_t riid,
                            anjay_input_ctx_t *ctx)

    @staticmethod
    cdef int resource_execute(anjay_t *anjay,
                              const anjay_dm_object_def_t *const *obj_ptr,
                              anjay_iid_t iid,
                              anjay_rid_t rid,
                              anjay_execute_ctx_t *ctx)

    @staticmethod
    cdef int resource_reset(anjay_t *anjay,
                            const anjay_dm_object_def_t *const *obj_ptr,
                            anjay_iid_t iid,
                            anjay_rid_t rid)

    # Transatction handlers
    # Todo
