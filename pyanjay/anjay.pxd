
from libc.stdint cimport (
    uint8_t, uint16_t, uint32_t, int32_t)

cdef extern from "stdbool.h":
    ctypedef bint cbool "bool"

cdef extern from "anjay/anjay.h":

    ctypedef struct anjay_t

    ctypedef uint16_t anjay_oid_t
    ctypedef uint16_t anjay_iid_t
    ctypedef uint16_t anjay_rid_t
    ctypedef uint16_t anjay_riid_t

    ctypedef uint16_t anjay_ssid_t

    cdef uint16_t ANJAY_ID_INVALID


    ctypedef enum avs_net_ssl_version_t:
        AVS_NET_SSL_VERSION_DEFAULT = 0,
        AVS_NET_SSL_VERSION_SSLv2_OR_3,
        AVS_NET_SSL_VERSION_SSLv2,
        AVS_NET_SSL_VERSION_SSLv3,
        AVS_NET_SSL_VERSION_TLSv1,
        AVS_NET_SSL_VERSION_TLSv1_1,
        AVS_NET_SSL_VERSION_TLSv1_2


    cdef int IF_NAMESIZE
    ctypedef char avs_net_socket_interface_name_t[16]

    ctypedef struct avs_net_resolved_endpoint_t:
        pass
        # uint8_t size
        # char buf[128];

    ctypedef enum avs_net_af_t:
        AVS_NET_AF_UNSPEC,
        AVS_NET_AF_INET4,
        AVS_NET_AF_INET6

    ctypedef struct avs_net_socket_configuration_t:
        uint8_t dscp
        uint8_t priority
        uint8_t reuse_addr
        uint8_t transparent
        avs_net_socket_interface_name_t interface_name
        avs_net_resolved_endpoint_t *preferred_endpoint
        avs_net_af_t address_family
        int forced_mtu
        avs_net_af_t preferred_family

    # Configuration
    ctypedef struct avs_coap_udp_tx_params_t
    ctypedef struct avs_net_dtls_handshake_timeouts_t

    ctypedef struct avs_net_socket_tls_ciphersuites_t:
        uint32_t *ids;
        size_t num_ids;

    ctypedef unsigned int avs_rand_seed_t
    ctypedef struct avs_crypto_prng_ctx_t:
        avs_rand_seed_t seed;

    ctypedef struct anjay_configuration_t:
        const char *endpoint_name
        uint16_t udp_listen_port
        avs_net_ssl_version_t dtls_version
        size_t in_buffer_size
        size_t out_buffer_size
        size_t msg_cache_size
        avs_net_socket_configuration_t socket_config
        const avs_coap_udp_tx_params_t *udp_tx_params
        const avs_net_dtls_handshake_timeouts_t *udp_dtls_hs_tx_params
        cbool confirmable_notifications
        cbool disable_legacy_server_initiated_bootstrap
        size_t stored_notification_limit
        cbool prefer_hierarchical_formats
        cbool use_connection_id
        avs_net_socket_tls_ciphersuites_t default_tls_ciphersuites
        avs_crypto_prng_ctx_t *prng_ctx

    cdef anjay_t *anjay_new(const anjay_configuration_t *config)
    cdef void anjay_delete(anjay_t *anjay)

    cdef void anjay_sched_run(anjay_t *anjay)
    cdef int anjay_notify_instances_changed(anjay_t *anjay, anjay_oid_t oid)
    cdef int anjay_notify_changed(anjay_t *anjay,
                                  anjay_oid_t oid,
                                  anjay_iid_t iid,
                                  anjay_rid_t rid)


cdef extern from "anjay/attr_storage.h":
    int anjay_attr_storage_install(anjay_t *anjay)


cdef extern from "anjay/security.h":

    ctypedef enum anjay_security_mode_t:
        ANJAY_SECURITY_PSK = 0,
        ANJAY_SECURITY_RPK = 1,
        ANJAY_SECURITY_CERTIFICATE = 2,
        ANJAY_SECURITY_NOSEC = 3,
        ANJAY_SECURITY_EST = 4

    ctypedef enum anjay_sms_security_mode_t:
        ANJAY_SMS_SECURITY_DTLS_PSK = 1,
        ANJAY_SMS_SECURITY_SECURE_PACKET = 2,
        ANJAY_SMS_SECURITY_NOSEC = 3

    ctypedef struct anjay_security_instance_t:
        anjay_ssid_t ssid
        const char *server_uri
        cbool bootstrap_server
        anjay_security_mode_t security_mode
        int32_t client_holdoff_s
        int32_t bootstrap_timeout_s
        const uint8_t *public_cert_or_psk_identity
        size_t public_cert_or_psk_identity_size
        const uint8_t *private_cert_or_psk_key
        size_t private_cert_or_psk_key_size
        const uint8_t *server_public_key
        size_t server_public_key_size
        anjay_sms_security_mode_t sms_security_mode
        const uint8_t *sms_key_parameters
        size_t sms_key_parameters_size
        const uint8_t *sms_secret_key
        size_t sms_secret_key_size
        const char *server_sms_number

    cdef:
        int anjay_security_object_install(anjay_t *anjay)
        int anjay_security_object_add_instance(anjay_t *anjay, const anjay_security_instance_t *instance, anjay_iid_t *inout_iid)


cdef extern from "anjay/server.h":
    ctypedef struct anjay_server_instance_t:
        anjay_ssid_t ssid
        int32_t lifetime
        int32_t default_min_period
        int32_t default_max_period
        int32_t disable_timeout
        const char *binding
        cbool notification_storing

    cdef:
        int anjay_server_object_install(anjay_t *anjay)
        int anjay_server_object_add_instance(anjay_t *anjay, const anjay_server_instance_t *instance, anjay_iid_t *inout_iid)


cdef extern from "loop.h":
    cdef int loop_iteration(anjay_t *anjay)


cdef class Anjay:
    cdef dict __dict__
    cdef object objects_lock
    cdef dict objects
    cdef dict known_iids
    cdef bytes _interface_name
    cdef anjay_t *anjay
    cdef _notify_instances_changed(self)
    cdef _notify_changed(self)
