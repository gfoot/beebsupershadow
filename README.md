# SuperShadow prototype for BBC Micro

The idea here is to design a much broader shadow RAM system for the BBC Micro
than those that were produces in the 80s, while hopefully still sticking to
technologies that were available and cheap at the time.

Most shadow RAM products focused on shadowing the BBC's existing RAM area and
increasing HIMEM to &8000.  Some provided sideways RAM in addition, that could
be paged in above &8000.  Generally OSHWM/PAGE was not lowered - often it was
in fact increased - as they did not shadow the paged ROM workspaces, until the
Master.

But what if we shadowed *everything*?  All 64K of the memory map.  Then the
RAM, ROM, and I/O on board the BBC Micro would be used only for OS
functionality, and user code would run in an entirely separate space with 64K
of RAM.

This is obviously inspired by the memory map you get when using the 6502 second
processor, and while in both cases it's necessary and valuable to have a stub
OS present, it should be possible to keep that OS small and provide almost all
of the 64K address space to the language and user code.

For more details on the initial idea and discussions and notes on development please see the StarDot thread:

https://stardot.org.uk/forums/viewtopic.php?f=3&t=26191

# Status

This is an early prototype.  This repository contains the Shadow OS code, as
part of a normal-mode executable that bootstraps it.  It installs various
routines in Shadow RAM, and runs some tests of the OS entry points.

Most things work pretty well at this stage, including interrupts, and it ought
to be able to run BASIC or HIBASIC now.

Obviously it also requires hardware support, it won't work on a stock BBC
Micro.  I've designed a small shadow RAM board that plugs into the processor
socket, providing the 64K of RAM through two 32K static RAM chips, with a PLD
and another glue logic IC to implement the simple bank switching protocol.
This is untested so far.

I've also patched BeebEm to add support for this mode, and that's what I've
been using to test the code so far.  If you have the tools to build it, you can get that here:
https://github.com/gfoot/beebem-windows/tree/supershadow


