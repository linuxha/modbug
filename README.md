# modbug
My attempt at recreating Peter Stark's Humbug for the 6800

# Description

This is currently a work in progress. A work that combines a lot of
different 6800 code in attempt to get a working 6800 Humbug ROM. I
beleive a have a number of the larger bugs out of the way and I have
somewhat working code. I will put together a test program for the
MODBUG to Single Step through and make sure it can handle most of
the OP Codes correctly.

How is this different from my Humbug repos? This combines MIKBUG as
the base code and I've added funtionality from the 6801 Humbug and
Microcomputing articles. This causes some interesting difficulties
in that I'm not an expert 6800 assembly language programmer. And
Peter's code has segments from different version that have differnt
variable names. It can be quite confusing. The MODBUG code at the
moment is mostly working but quite messy with lots of debug code
writing to low memory (not code). While the code verion is 1.11.14
it's really Alpha code. I need to get this under a version control
system so I can keep track of the changes.
