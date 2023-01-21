# Shadow mode code

This code all gets uploaded to shadow RAM and executed from there.  It's mostly
comprised of Shadow OS code that resides above $F800 in shadow RAM, including
providing the CPU's reset and interrupt vectors, as well as all the standard OS
entry points, interrupt handlers, routines to marshall data for sending to
normal RAM, and routines for executing commands sent from normal mode (e.g.
initialisation, executing code at a certain address).

