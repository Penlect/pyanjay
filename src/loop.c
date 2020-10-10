#include <anjay/anjay.h>
#include <avsystem/commons/avs_log.h>

#include <poll.h>

#include "Python.h"

int loop_iteration(anjay_t *anjay) {
    // Obtain all network data sources
    AVS_LIST(avs_net_socket_t *const) sockets = anjay_get_sockets(anjay);

    // Prepare to poll() on them
    size_t numsocks = AVS_LIST_SIZE(sockets);
    struct pollfd pollfds[numsocks];
    size_t i = 0;
    AVS_LIST(avs_net_socket_t *const) sock;
    AVS_LIST_FOREACH(sock, sockets) {
	pollfds[i].fd = *(const int *) avs_net_socket_get_system(*sock);
	pollfds[i].events = POLLIN;
	pollfds[i].revents = 0;
	++i;
    }

    const int max_wait_time_ms = 100;
    // Determine the expected time to the next job in milliseconds.
    // If there is no job we will wait till something arrives for
    // at most 100 ms (i.e. max_wait_time_ms).
    int wait_ms =
	anjay_sched_calculate_wait_time_ms(anjay, max_wait_time_ms);

    int event = 0;
    // Release the GIL, so that other threads can safely access Python
    // objects while we wait on the poll.
    Py_BEGIN_ALLOW_THREADS
    event = poll(pollfds, numsocks, wait_ms);
    Py_END_ALLOW_THREADS
    // Wait for the events if necessary, and handle them.
    if (event > 0) {
	int socket_id = 0;
	AVS_LIST(avs_net_socket_t *const) socket = NULL;
	AVS_LIST_FOREACH(socket, sockets) {
	    if (pollfds[socket_id].revents) {
		if (anjay_serve(anjay, *socket)) {
		    avs_log(tutorial, ERROR, "anjay_serve failed");
		}
	    }
	    ++socket_id;
	}
    }
    return 0;
}
