
# Built-in
import threading
import logging

# C
from cpython.exc cimport PyErr_CheckSignals

# Package
cimport pyanjay.dm

LOG = logging.getLogger(__name__)

cdef extern from "avsystem/commons/avs_log.h":
    ctypedef enum avs_log_level_t:
        AVS_LOG_TRACE,
        AVS_LOG_DEBUG,
        AVS_LOG_INFO,
        AVS_LOG_WARNING,
        AVS_LOG_ERROR,
        AVS_LOG_QUIET

    ctypedef void avs_log_handler_t(
        avs_log_level_t level,
        const char *module,
        const char *message)

    void avs_log_set_handler(avs_log_handler_t *log_handler)


cdef void python_log_handler(avs_log_level_t level,
              const char *module,
              const char *message):
    log = logging.getLogger(f'anjay.{module.decode()}')
    pylevel = log.debug
    if level == avs_log_level_t.AVS_LOG_INFO:
        pylevel = log.info
    elif level == avs_log_level_t.AVS_LOG_WARNING:
        pylevel = log.warning
    elif level == avs_log_level_t.AVS_LOG_ERROR:
        pylevel = log.error
    elif level == avs_log_level_t.AVS_LOG_QUIET:
        return
    pylevel(message.decode())


avs_log_set_handler(python_log_handler)


cdef class Anjay:

    def __cinit__(self, endpoint_name):

        cdef avs_net_socket_configuration_t socket_config
        socket_config.dscp = 0
        socket_config.priority = 0
        socket_config.reuse_addr = False
        socket_config.transparent = 0
        socket_config.interface_name = ""
        socket_config.preferred_endpoint = NULL
        socket_config.address_family = AVS_NET_AF_UNSPEC
        socket_config.forced_mtu = 0
        socket_config.preferred_family = AVS_NET_AF_UNSPEC
        cdef avs_net_socket_tls_ciphersuites_t default_tls_ciphersuites
        default_tls_ciphersuites.ids = NULL
        default_tls_ciphersuites.num_ids = 0
        cdef anjay_configuration_t cfg
        cfg.endpoint_name = endpoint_name
        cfg.udp_listen_port = 0
        cfg.dtls_version = AVS_NET_SSL_VERSION_DEFAULT
        cfg.in_buffer_size = 4000
        cfg.out_buffer_size = 4000
        cfg.msg_cache_size = 4000
        cfg.socket_config = socket_config
        cfg.udp_tx_params = NULL
        cfg.udp_dtls_hs_tx_params = NULL
        cfg.confirmable_notifications = False
        cfg.disable_legacy_server_initiated_bootstrap = False
        cfg.stored_notification_limit = 0
        cfg.prefer_hierarchical_formats = True
        cfg.use_connection_id = False
        cfg.default_tls_ciphersuites = default_tls_ciphersuites
        cfg.prng_ctx = NULL
        
        self.anjay = anjay_new(&cfg)
        if not self.anjay:
            raise RuntimeError('Could not create Anjay object')

        self.objects_lock = threading.Lock()
        self.objects = dict()

    def __dealloc__(self):
        if self.anjay != NULL:
            anjay_delete(self.anjay)

    def __init__(self, endpoint_name):
        # Add instance to lookup mapping in data model
        cdef void *p = <void*>self.anjay
        cdef long i = <long>p
        stored_anjay = pyanjay.dm.anjay_lookup.get(i)
        if isinstance(stored_anjay, self.__class__) and stored_anjay is not self:
            raise Exception(f'Different Anjay instances stored at {i}')
        pyanjay.dm.anjay_lookup[i] = self

        self.stop_event = threading.Event()
        self.run_lock = threading.Lock()

    def attr_storage_install(self):
        LOG.debug('Install storage module')
        if anjay_attr_storage_install(self.anjay):
            raise Exception('Failed to install attr storage')

    def register_security_object(self, url='coap://localhost:5683'):
        LOG.debug('Register security object')
        if anjay_security_object_install(self.anjay):
            raise Exception('Failed to install security object')
        self.__url = url.encode()
        cdef anjay_security_instance_t sec
        sec.ssid = 1
        sec.server_uri = self.__url
        sec.bootstrap_server = False
        sec.security_mode = ANJAY_SECURITY_NOSEC
        sec.client_holdoff_s = 0
        sec.bootstrap_timeout_s = 0
        sec.public_cert_or_psk_identity = NULL
        sec.public_cert_or_psk_identity_size = 0
        sec.private_cert_or_psk_key = NULL
        sec.private_cert_or_psk_key_size = 0
        sec.server_public_key = NULL
        sec.server_public_key_size = 0

        sec.sms_security_mode = ANJAY_SMS_SECURITY_NOSEC
        sec.sms_key_parameters = NULL
        sec.sms_key_parameters_size = 0
        sec.sms_secret_key = NULL
        sec.sms_secret_key_size = 0
        sec.server_sms_number = NULL

        cdef anjay_iid_t security_instance_id = ANJAY_ID_INVALID
        with self.objects_lock:
            if 0 in self.objects:
                raise Exception(f'Security object already registered')
            if anjay_security_object_add_instance(self.anjay, &sec, &security_instance_id):
                raise Exception('Failed to add security object instance')
            self.objects[0] = True

    def register_server_object(self):
        LOG.debug('Register server object')
        if anjay_server_object_install(self.anjay):
            raise Exception('Failed to install server object')
        cdef anjay_server_instance_t srv
        srv.ssid = 1
        srv.lifetime = 60
        srv.default_min_period = -1
        srv.default_max_period = -1
        srv.disable_timeout = -1
        srv.binding = "U"
        srv.notification_storing = False
        cdef anjay_iid_t server_instance_id = ANJAY_ID_INVALID
        with self.objects_lock:
            if 1 in self.objects:
                raise Exception(f'Server object already registered')
            if anjay_server_object_add_instance(self.anjay, &srv, &server_instance_id):
                raise Exception('Failed to add server object instance')
            self.objects[1] = True

    def register(self, objectdef, create_inst=True):
        LOG.debug('Regester %r ...', objectdef)
        cdef pyanjay.dm.DM dm
        with self.objects_lock:
            if objectdef.oid in self.objects:
                raise Exception(f'Object with id {objectdef.oid} already registered')
            dm = pyanjay.dm.DM(objectdef)
            if pyanjay.dm.anjay_register_object(self.anjay, &dm.objdef):
                raise Exception('Failed to register object', objectdef)
            self.objects[objectdef.oid] = dm
        LOG.debug('Registration done: %r', dm)

    def get_registered_objects(self):
        with self.objects_lock:
            return {oid: self.objects[oid]
                    for oid in sorted(self.objects)}

    def __getitem__(self, oid):
        with self.objects_lock:
            return <pyanjay.dm.DM?>self.objects[oid]

    def unregister(self, oid):
        LOG.debug('Unregester %r ...', oid)
        cdef pyanjay.dm.DM dm
        with self.objects_lock:
            dm = self.objects[oid]
            if pyanjay.dm.anjay_unregister_object(self.anjay, &dm.objdef):
                raise Exception('Failed to unregister object', dm)
            del self.objects[oid]
        LOG.debug('Unregistration done: %r', dm)

    def __delitem__(self, oid):
        self.unregister(oid)

    def __repr__(self):
        objs = self.get_registered_objects()
        return f'{self.__class__.__name__}{list(objs.values())}'

    def __len__(self):
        return len(self.get_registered_objects())

    def __contains__(self, key):
        try:
            self.objects[key]
        except KeyError:
            return False
        else:
            return True

    def stop(self):
        self.stop_event.set()

    def run(self, stop_event=None):
        LOG.debug('Starting client loop')
        locked = self.run_lock.acquire(blocking=False)
        if locked:
            if stop_event is None:
                stop_event = self.stop_event()
            stop_event.clear()
            while not stop_event.is_set():
                PyErr_CheckSignals()
                loop_iteration(self.anjay)
        else:
            raise RuntimeError('Already running in another thread')
        LOG.debug('Client loop stopped')
