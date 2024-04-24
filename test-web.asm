;*
;* test-web.asm
;*
;* Uses http://www.8bit-era.cz/ as a quick and dirty assembler
;*
;* Purpose add every OP Code so I can single step and check that every OP works
;*
PC      =       $A048
SP      =       $A008
DSTACK  =       $D083
NXTCMD  =       $E17F
WARMST  =       $E160
OUT2H   =       $E2EE
PDATA   =       $E337
CRLF    =       $E328

AVAL    =       $1234
BVAL    =       $ABCD

*=$0FF0
        .DATA   "abcdefghijkl1000"
        .DATA   "0123456789ABCDEF"
        .DATA   "* =============="
        .DATA   "*               "
        .DATA   "* Neil was here "
        .DATA   "*               "
        .DATA   "* =============="
PCSTR   .data   $0A, $0D, "PC = "
        .DATA   $04
SPSTR   .data   $0A, $0D, "SP = "
        .DATA   $04
A       .data   $41
B       .data   $42
CD      .data   $43,$44
USAVEX  .DATA   $01,$02
;*

*=$2000
START   nop
        nop
        nop
        nop
        nop
        ;rts
        ;lds        $0FFF
        ldaa    #$41    ;
        ldab    #$42
        psha
        ldx     #$4342
        pshb            ; SWI
        cpx     #$4344
        nop
        inx
        cpx     #$4344
        nop             ; SWI
        inx
        cpx     #$4344
        dex
        inx
        nop
        nop
        nop
        ldaa    #$01
        nop
        ldab    #$01
        nop
        nop
        pulb
        pula
;       jmp     $E1EE
        rts
