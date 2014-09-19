#include <czmq.h>

int handle_pipe(zloop_t *loop, zsock_t *root, void *arg) {
  zmsg_t *msg = zmsg_recv (root);
  zframe_t *frame = zmsg_first (msg);
  while (frame) {

    frame = zmsg_next (msg);
  }
  assert (msg);
  zmsg_destroy (&msg);
  return 0;
}

int main (void) {
  zsys_set_ipv6 (1);

  int rc = 0;

  rc = zsys_daemonize (NULL);
  assert (rc == 0);

  zactor_t *root = zactor_new (zgossip, "root");
  assert (root);

  rc = zstr_sendx (root, "BIND", "tcp://*:5670", NULL);
  assert (rc == 0);

  zloop_t *reactor = zloop_new ();
  assert (reactor);

  rc = zloop_reader (reactor, root, handle_pipe, NULL);
  assert (rc == 0);

  zloop_start (reactor);

  zloop_destroy (&reactor);
  zactor_destroy (&root);

  return 0;
}
