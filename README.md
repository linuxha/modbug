# modbug
My attempt at recreating Peter Stark's Humbug for the 6800. The base
code is MIKBUG version 2. The Humbug code a combination of Tandy MC10
cassette Humbug and Peter's Microcomputing articles.

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

# History

April 24, 2024 - 1.11.17

Fixed a minor bug in D - ASCII/HEX Display. I've also cleaned up a
bunch of the debug code or ifdef'd it out. I'm noticing something
writing to Address $0000 in RAM but haven't found it yet. Stacks are
no longer getting clobbered. More testing needed and various bugs need
to be fised (like the Find command).

April 23, 2024

Finally got Single Step working. Added everything to Github.

# Requires software

srecord
ASL Macro assembler ( http://john.ccac.rwth-aachen.de:8000/as/ )

# Assemble

    VAR='_E000'
    asl -i . -D ${VAR} -L modbug.asm
    mv modbug.lst mb${VAR}.lst
    p2hex +5 -F Moto -r \$-\$ modbug.p mb${VAR}.s19
    srec_cat mb${VAR}.s19 -o hmb${VAR}.s19
    echo "hmb${VAR}.s19"
    memsim2 hmb${VAR}.s19

    VAR='_E000';asl -i . -D ${VAR} -L modbug.asm; mv modbug.lst mb${VAR}.lst;p2hex +5 -F Moto -r \$-\$ modbug.p mb${VAR}.s19
    srec_cat mb${VAR}.s19 -o hmb${VAR}.s19;echo "hmb${VAR}.s19";memsim2 hmb${VAR}.s19

**Note:** I'm currently using all of E000 thru FFFF. yes I'm being
sloppy but my EPROM emulator works nicely with this so I'll continue
this. My ACIA is at $E000 and the PIA at $E004(?) or $E008. Code
actually starts at $E100 and unused sections are filled with $FF.

# Test script

From minicom, type Ctrl-A G

```
         +-----------------------[Run a script]------------------------+
         |                                                             |
         | A -   Username        :                                     |
         | B -   Password        :                                     |
         | C -   Name of script  : /home/njc/dev/git/Humbug/script.sh  |
         |                                                             |
         |    Change which setting?     (Return to run, ESC to stop)   |
         +-------------------------------------------------------------+
```
