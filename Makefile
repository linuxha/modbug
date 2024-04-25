# Makefile for the Motorola 6801/6803 lilbug monitor
# ncherry@linuxha.com 2023/01/04

all:	mb_E000.s19

# ------------------------------------------------------------------------------
#

humbug: mb_E000.s19

humbug-mc.s19: humbug-mc.p
	p2hex +5 -F Moto -r \$$-\$$ humbug-mc.p humbug-mc.s19
	ls
	srec_info humbug-mc.s19

humbug-mc.lst: humbug-mc.asm humbug.inc motorola.inc
	asl -i . -L humbug-mc.asm

humbug-mc.p: humbug-mc.asm humbug.inc asl.inc  humbug.inc motorola.inc
	asl -i . -D NOMIKBUG -L humbug-mc.asm

mb_E000.s19:

mb_E000.s19: modbug.p
	p2hex +5 -F Moto -r \$$-\$$ modbug.p mb_E000.s19
	ls
	srec_info mb_E000.s19

mb_E000.lst: modbug.asm asl.inc
	asl -i . -L mb_E000.asm

mb_E000.p: mb_E000.asm humbug.inc asl.inc  humbug.inc motorola.inc
	asl -i . -D NOMIKBUG -L mb_E000.asm

other:
	asl -i . -D _E000 -L modbug.asm
	mv modbug.lst mb_E000.lst
	p2hex +5 -F Moto -r \$$-\$$ modbug.p mb_E000.s19
	srec_cat mb_E000.s19 -o hmb_E000.s19
	echo "hmb_E000.s19"
	memsim2 hmb_E000.s19

#    VAR='_E000';asl -i . -D ${VAR} -L modbug.asm; mv modbug.lst mb${VAR}.lst;p2hex +5 -F Moto -r \$-\$ modbug.p mb${VAR}.s19
#    srec_cat mb${VAR}.s19 -o hmb${VAR}.s19;echo "hmb${VAR}.s19";memsim2 hmb${VAR}.s19

# ------------------------------------------------------------------------------
#
clean:
	rm -f *.lst *.p foo bar *~ *.bin *.hex *.s19 dstfile.srec *.srec
	echo Done

#

.PHONY: mb

# -[ Fini ]---------------------------------------------------------------------
