
# Built-in
import threading
import logging

# C
from cpython.exc cimport PyErr_CheckSignals

# Package
cimport pyanjay._dm
from pyanjay.dm import W, RW

LOG = logging.getLogger(__name__)

# Set the anjay log handler to a Python logger

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
    if level == avs_log_level_t.AVS_LOG_QUIET:
        return
    log = logging.getLogger(f'anjay.{module.decode()}')
    pylevel = log.debug
    if level == avs_log_level_t.AVS_LOG_INFO:
        pylevel = log.info
    elif level == avs_log_level_t.AVS_LOG_WARNING:
        pylevel = log.warning
    elif level == avs_log_level_t.AVS_LOG_ERROR:
        pylevel = log.error
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
        self.known_iids = dict()

    def __dealloc__(self):
        if self.anjay != NULL:
            anjay_delete(self.anjay)

    def __init__(self, endpoint_name):
        # Add instance to lookup mapping in data model
        cdef void *p = <void*>self.anjay
        cdef long i = <long>p
        stored_anjay = pyanjay._dm.anjay_lookup.get(i)
        if isinstance(stored_anjay, self.__class__) and stored_anjay is not self:
            raise Exception(f'Different Anjay instances stored at {i}')
        pyanjay._dm.anjay_lookup[i] = self

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

        security_object_id = 0
        cdef anjay_iid_t security_instance_id = ANJAY_ID_INVALID
        with self.objects_lock:
            if security_object_id in self.objects:
                raise Exception(f'Security object already registered')
            if anjay_security_object_add_instance(self.anjay, &sec, &security_instance_id):
                raise Exception('Failed to add security object instance')
            self.objects[security_object_id] = True

    def register_server_object(  # Todo: More sanity checks and verification
            self, short_server_id=1, lifetime=60,
            default_min_period=None, default_max_period=None,
            disable_timeout=None, binding='U', notification_storing=False
    ) -> int:
        """Add Server Object instance and return created instance id.

        :param short_server_id: Used as link to associate server Object
            Instance, defaults to 1. Range: 1-65535.
        :param lifetime: Specify the lifetime of the registration in
            seconds, defaults to 60 seconds.
        :param default_min_period: The default value the LwM2M Client
            should use for the Minimum Period of an Observation in the
            absence of pmin attribute. Seconds. Disabled by default
            (None).
        :param default_max_period: The default value the LwM2M Client
            should use for the Maximum Period of an Observation in the
            absence of pmin attribute. Seconds. Disabled by default
            (None).
        :param disable_timeout: A period in seconds to disable the
            Server. After this period, the LwM2M Client MUST perform
            registration process to the Server. Disabled by default
            (None).
        :param binding: This Resource defines the transport binding
            configured for the LwM2M Client.
        :param notification_storing: Whether the client should save
            notifications while `disable_timeout` is active or not.
            Defaults to False.

        :return: Instance id of server object.
        :rtype: int
        """
        LOG.debug('Register server object')
        if anjay_server_object_install(self.anjay):
            raise Exception('Failed to install server object')
        cdef anjay_server_instance_t srv
        if not (0 < short_server_id < 65536):
            raise ValueError('Bad short server id: {short_server_id}')
        srv.ssid = short_server_id
        srv.lifetime = lifetime
        if default_min_period is None:
            default_min_period = -1
        srv.default_min_period = default_min_period
        if default_max_period is None:
            default_max_period = -1
        srv.default_max_period = default_max_period
        if disable_timeout is None:
            disable_timeout = -1
        srv.disable_timeout = disable_timeout
        # Safe because anjay makes a deep copy of all fields.
        binding_bytes = binding.encode()
        srv.binding = binding_bytes
        srv.notification_storing = notification_storing
        server_object_id = 1
        cdef anjay_iid_t server_instance_id = ANJAY_ID_INVALID
        with self.objects_lock:
            if server_object_id in self.objects:
                raise Exception(f'Server object already registered')
            if anjay_server_object_add_instance(self.anjay, &srv, &server_instance_id):
                raise Exception('Failed to add server object instance')
            self.objects[server_object_id] = True

    def register(self, objectdef, create_inst=True):
        LOG.debug('Regester %r ...', objectdef)
        cdef pyanjay._dm.DM dm
        with self.objects_lock:
            if objectdef.oid in self.objects:
                raise Exception(f'Object with id {objectdef.oid} already registered')
            dm = pyanjay._dm.DM(objectdef)
            if pyanjay._dm.anjay_register_object(self.anjay, &dm.objdef):
                raise Exception('Failed to register object', objectdef)
            self.objects[objectdef.oid] = dm
        LOG.debug('Registration done: %r', dm)

    def get_registered_objects(self):
        with self.objects_lock:
            return {oid: self.objects[oid]
                    for oid in sorted(self.objects)}

    def __getitem__(self, oid):
        with self.objects_lock:
            return <pyanjay._dm.DM?>self.objects[oid]

    def unregister(self, oid):
        LOG.debug('Unregester %r ...', oid)
        cdef pyanjay._dm.DM dm
        with self.objects_lock:
            dm = self.objects[oid]
            if pyanjay._dm.anjay_unregister_object(self.anjay, &dm.objdef):
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
            with self.objects_lock:
                for obj in self.objects.values():
                    if not isinstance(obj, pyanjay._dm.DM):
                        continue
                    self.known_iids[obj.oid] = set(obj.instances)
            while not stop_event.is_set():
                PyErr_CheckSignals()
                loop_iteration(self.anjay)
                self._notify_instances_changed()
                self._notify_changed()
                anjay_sched_run(self.anjay)
        else:
            raise RuntimeError('Already running in another thread')
        LOG.debug('Client loop stopped')

    cdef _notify_instances_changed(self):
        """Notify one or more Object Instances were created/removed"""
        with self.objects_lock:
            for obj in self.objects.values():
                if not isinstance(obj, pyanjay._dm.DM):
                    continue
                prev_iids = self.known_iids[obj.oid]
                iids = set(obj.instances)
                for i in iids ^ prev_iids:
                    LOG.info('Notify instance changed: %d', i)
                    anjay_notify_instances_changed(self.anjay, i)
                self.known_iids[obj.oid] = iids

    cdef _notify_changed(self):
        """Notify changed resources (W/RW and numeric)"""
        changed = list()
        with self.objects_lock:
            for obj in self.objects.values():
                if not isinstance(obj, pyanjay._dm.DM):
                    continue
                for inst in obj.instances.values():
                    for res in inst.resources.values():
                        if isinstance(res, (W, RW)) and \
                                isinstance(res.value, (int, float)) and \
                                getattr(res, 'changed', False):
                            res.changed = False
                            changed.append((obj, inst, res))
        for obj, inst, res in changed:
            LOG.debug('Notify resource changed: %r', res)
            if anjay_notify_changed(
                    self.anjay, obj.oid, inst.iid, res.rid):
                raise Exception('Failed to notify changed on %r', res)

