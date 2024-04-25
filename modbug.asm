        MACEXP  off
        CPU     6800            ; That's what asl has
        include "asl.inc"       ;

        NAM    MIKBUG
;*      REV 009
;*      COPYRIGHT 1974 BY MOTOROLA INC
;*
;*      MODBUG - Upgraded MIKBUG (TM)
;*
;*      L  LOAD
;*      G  GO TO TARGET PROGRAM
;*      M  MEMORY CHANGE
;*      P  PRINT/PUNCH DUMP
;*      R  DISPLAY CONTENTS OF TARGET STACK
;*              CC   B   A   X   P   S
;*
;*      U  User command
;*      D  Hex/ASCII dump
;*      X  Dessemble
;*      B  Set/Clear Break points
;*      b  print Break Point info
;*      F  Fill memory
;*      J  Jump to , gets addr from the console
;*      *  Cold start
;*      T  Start trace (SS)                     <- Doesn't work yet
;*      S  Continue SS                          <- WIP
;*      W  Find 1,2,3 bytes in memory           <- Doesn't work
;*      ?  Help
;*
;*      ADDRESS
        IFDEF _E000
ACIACS  EQU     $E000
ACIADA  EQU     $E001
        ELSE
ACIACS  EQU     $8018
ACIADA  EQU     $8019
        ENDIF
;
;VAR    EQU     $1F00
;*
;        ORG    VAR
        IFDEF _E000
        org     $A000           ;* $0080
        ELSE
        ORG     $1F00
        ENDIF

IOV     RMB    2         ;* A000 - IO INTERRUPT POINTER
BEGA    RMB    2         ;* A002 - BEGINING ADDR PRINT/PUNCH
ENDA    RMB    2         ;* A004 - ENDING ADDR PRINT/PUNCH
NIO     RMB    2         ;* A006 - NMI INTERRUPT POINTER
SP      RMB    2         ;* A008 - S-HIGH
;       RMB    0         ;* A009 - S-LOW
CKSM    RMB    1         ;* A00A - CHECKSUM

BYTECT  RMB    1         ;* A00B - BYTE COUNT
BADDRH
XHI     RMB    1         ;* A00C - XREG HIGH
XLOW    RMB    1         ;* A00D - XREG LOW
TEMP    RMB    1         ;* A00E - CHAR COUNT (INADD)
TW      RMB    2         ;* A00F - TEMP
MCONT   RMB    1         ;* A011 - TEMP
XTEMP   RMB    2         ;* A012 - X-REG TEMP STORAGE
;        RMB    46
ASTACK  equ     $AFFF    ;* A049 - STACK POINTER (usually)

;* =============================================================================

        org     $D000
USRV    rmb     2        ;* D002
SWIJMP                   ;*   rmb     2
SWIV    rmb     2        ;*
OUTEXR  rmb     2        ;*
INEXR   rmb     2        ;*
SAVEX   rmb     2        ;*
TEMP1   rmb     2        ;*

COUNT   rmb     1

; BP/BR
BRTMP   rmb     2
BKTAB   rmb     12
TMPSTR  rmb     8
PC      rmb     2
WHAT
NEXT    rmb     2
SAVINST rmb     1
BRANCH  rmb     2
INST    rmb     1
FINDNO
NBYTES  rmb     1

DSTACK  equ     $DFFF    ;*

_SWI    equ     $3F
	
;* =============================================================================

;*
;*      OPT     MEMORY
        IFDEF _E000
        ;;
        ;; MIKBUG normally starts at $E000 but I have the serial ports there
        ;; I could move it up to $F000
        ;; 
        ORG     $E000           ; EPROM Fill
; 
        ;; Fill up to FFD0 with FF
        dc.b [(*+($E100-*))&$E100-*]$ff
;
        ORG     $E100
        ELSE
        ORG     $E000
        ENDIF
;* -----------------------------------------------------------------------------
;*
SWIH    ldx     SWIV
        jmp     0,X
;* -----------------------------------------------------------------------------
;*
;*      USER service routine
USER    LDX     USRV
        jsr     0,X             ;* User code needs a rts to return
        ldx     #DONE
        jsr     PDATA1
        jmp     CONTRL

DONE    fcc     '\n\rDone!\4'
;* -----------------------------------------------------------------------------
;*
;*      I/O INTERRUPT SEQUENCE
IO      LDX     IOV
        JMP     0,X             ;* Needs rti (?)
;* -----------------------------------------------------------------------------
;*
;*      NMI SEQUENCE
POWDWN  LDX     NIO             ;* GET NMI VECTOR
        JMP     ,X              ;* Needs rti (?)
;*
;*      L COMMAND
;*
LOAD    EQU     *
        LDAA    #$0D
        BSR     OUTCH
        NOP
        LDAA    #$0A
        BSR     OUTCH
;*
;*      CHECK TYPE
;*
LOAD3   BSR     INCH
        CMPA    #'S'
        BNE     LOAD3   ;* 1ST CHAR NOT (S)
        BSR     INCH    ;* READ CHAR
        CMPA    #'9'
        BEQ     LOAD21  ;* START ADDRESS
        CMPA    #'1'
        BNE     LOAD3   ;* 2ND CHAR NOT (1)
        CLR     CKSM    ;* ZERO CHECKSUM
        BSR     BYTE    ;* READ BYTE
        SUBA    #2
        STAA    BYTECT  ;* BYTE COUNT
;*
;*      BUILD ADDRESS
;*
        BSR     BADDR
;*
;*      STORE DATA
;*
LOAD11  BSR     BYTE
        DEC     BYTECT
        BEQ     LOAD15  ;* ZERO BYTE COUNT
        STAA    ,X      ;* STORE DATA
        INX
        BRA     LOAD11
;*
;*      ZERO BYTE COUNT
;*
LOAD15  INC     CKSM
        BEQ     LOAD3
LOAD19  LDAA    #'?'    ;* PRINT QUESTION MARK
        BSR     OUTCH
LOAD21  EQU     *
C1      JMP     CONTRL

;*
;*      BUILD ADDRESS
;*
BADDR   BSR     BYTE    ;* READ 2 FRAMES
        STAA    XHI
        BSR     BYTE
        STAA    XLOW
        LDX     XHI     ;* (X) ADDRESS WE BUILT
        RTS
;*
;*      INPUT BYTE (TWO FRAMES)
;*
BYTE    BSR     INHEX   ;* GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR     INHEX
        ABA
        TAB
        ADDB    CKSM
        STAB    CKSM
        RTS
;*
;*      OUT HEX BCD DIGIT
;*
OUTHL   LSRA            ;* OUT HEX LEFT BCD DIGIT
        LSRA
        LSRA
        LSRA
OUTHR   ANDA    #$F     ;* OUT HEX RIGHT BCD DIGIT
        ADDA    #$30
        CMPA    #$39
        BLS     OUTCH
        ADDA    #$7
;*
;*      OUTPUT ONE CHAR
OUTCH   JMP     OUTEEE
INCH    JMP     INEEE
;*
;*      PRINT DATA POINTED AT BY X-REG
PDATA2  BSR     OUTCH
        INX
PDATA1  LDAA    ,X
        CMPA    #4
        BNE     PDATA2
        RTS             ;* STOP ON EOT
;*
;*      CHANGE MENORY (M AAAA DD NN)
CHANGE  BSR     BADDR   ;* BUILD ADDRESS
CHA51   LDX     #MCL
        BSR     PDATA1  ;* C/R L/F
        LDX     #XHI
        BSR     OUT4HS  ;* PRINT ADDRESS
        LDX     XHI
        BSR     OUT2HS  ;* PRINT DATA (OLD)
        STX     XHI     ;* SAVE DATA ADDRESS
        BSR     INCH    ;* INPUT ONE CHAR
        CMPA    #$20
        BNE     CHA51   ;* NOT SPACE
        BSR     BYTE    ;* INPUT NEW DATA
        DEX
        STAA    ,X      ;* CHANGE MEMORY
        CMPA    ,X
        BEQ     CHA51   ;* DID CHANGE
        BRA     LOAD19  ;* NOT CHANGED
;*
;*      INPUT HEX CHAR
INHEX   BSR     INCH
        SUBA    #$30
        BMI     C1      ;* NOT HEX
        CMPA    #$09
        BLE     IN1HG
        CMPA    #$11
        BMI     C1      ;* NOT HEX
        CMPA    #$16
        BGT     C1      ;* NOT HEX
        SUBA    #7
IN1HG   RTS
;*
;*      OUTPUT 2 HEX CHAR
OUT2H   LDAA    0,X     ;* OUTPUT 2 HEX CHAR
OUT2HA  BSR     OUTHL   ;* OUT LEFT HEX CHAR
        LDAA    0,X
        INX
        BRA     OUTHR   ;* OUTPUT RIGHT HEX CHAR AND R
;*
;*      OUTPUT 2-4 HEX CHAR + SPACE
OUT4HS  BSR     OUT2H   ;* OUTPUT 4 HEX CHAR + SPACE
OUT2HS  BSR     OUT2H   ;* OUTPUT 2 HEX CHAR + SPACE
;*
;*      OUTPUT SPACE
OUTS    LDAA    #$20    ;* SPACE
        BRA     OUTCH   ;* (BSR & RTS)
;*
;*      ENTER POWER  ON SEQUENCE
START   EQU     *
;* Clean up RAM 0000-DFFF
	ldx     #$00
        lda     #$FF
FFILL   sta     0,X
        inx
        cmpx    #$DFFF
        bne     FFILL
;* -----------------------------------------------------------------------------
	ldx     #SFE
        stx     SWIV            ;*

        LDS     #DSTACK
        STS     SP      ;* INZ TARGET'S STACK PNTR

        ldx     #CONTRL
        stx     USRV
;*
;*      ACIA INITIALIZE
;*
        LDAA    #$03    ;* RESET CODE
        STAA    ACIACS
        NOP
        NOP
        NOP
        LDAA    #$15    ;* 8N1 NON-INTERRUPT
        STAA    ACIACS
;*
        ldx     #HELLOST
        jsr     PDATA1
;*
;*      COMMAND CONTROL
;*
CONTRL  LDS     #ASTACK ;* SET CONTRL STACK POINTER
        LDX     #MCL
        jsr     PDATA1  ;* PRINT DATA STRING
        jsr     INCH    ;* READ CHARACTER
        TAB
        BSR     OUTS    ;* PRINT SPACE
        ;;
        ;;  Note: These are all bra or jmp, no jsr
        ;; 
        CMPB    #'L'
        BEQ     LOADV
;
        CMPB    #'M'
        BEQ     CHANGEV
;
        CMPB    #'R'
        BEQ     PRINTV          ;* STACK
;
        CMPB    #'P'
        BEQ     PUNCHV          ;* PRINT/PUNCH
;
        CMPB    #'U'
        BEQ     USERV           ;* User command
;
        CMPB    #'D'
        BEQ     DISPLYV         ;* Hex/ASCII Display
;
        CMPB    #'X'
        BEQ     DESSMV          ;* Dessemble
;
	CMPB	#'B'
	BEQ	BRINSTV         ;* Break set/clear
;
	CMPB	#'b'
	BEQ	BPINSTV         ;* Break print
;
	CMPB	#'F'
	BEQ	FMINSTV         ;* Fill memory
;
	CMPB	#'J'
	BEQ	JUINSTV         ;* Jump 
;
	CMPB	#'*'
	BEQ	RSTINTV         ;* Cold start
;
	CMPB	#'S'
	BEQ	SSINSTV         ;* Single Step
;
	CMPB	#'T'
	BEQ	STINSTV         ;* Trace (start single step)
;
	CMPB	#'W'
	BEQ	FIINSTV         ;* where (Find)
;
	CMPB	#'?'
	BEQ	HELP            ;* Help
;
        CMPB    #'G'            ;* Continue
        BNE     CONTRL
;
        LDS     SP      ;* RESTORE PGM'S STACK PTR
        RTI             ;* GO
;       FCB     1,1,1,1,1,1,1,1 ;* GRUE
;* -----------------------------------------------------------------------------
HELP    ldx     #HELPST
        jsr     PDATA1
        jmp     CONTRL
;* -----------------------------------------------------------------------------
LOADV   jmp     LOAD            ;* L
CHANGEV jmp     CHANGE          ;* M
PRINTV  jmp     PRINT           ;* R
PUNCHV  jmp     PUNCH           ;* P
DISPLYV jmp     ADINST          ;* D
USERV   jmp     USER            ;* U
DESSMV  jmp     DEINST          ;* X
BPINSTV jmp     BPINST          ;* b
FMINSTV jmp     FMINST          ;* F
JUINSTV jmp     JUINST          ;* J
SSINSTV jmp     SSINST          ;* S
STINSTV jmp     STINST          ;* T
FIINSTV jmp     FIINST          ;* W

RSTINTV jmp     START           ;* *
BRINSTV jsr     BRINST          ;* B uses a rts to return
        jmp     CONTRL

CONTRLV jmp     CONTRL
;* -----------------------------------------------------------------------------
HELPST  FCB     '\n\rL M R P U D X B b F J * # S t W ? G\4'
REMSG:  fcc     "\n\rhinzvc b  a  x    pc   sp\n\r\4"
;* -[ SWI Handler ]-------------------------------------------------------------
;*
;* SWI Handler 
;*
;* Stack order (pushed)
;* 
;* [[SP]] ← [PC(LO)],           ; PC Lo                      ; DFFF
;* [[SP] - 1] ← [PC(HI)],       ; PC Hi                      ; DFFE
;* [[SP] - 2] ← [X(LO)],        ;  X Lo                      ; DFFD
;* [[SP] - 3] ← [X(HI)],        ;  X Hi                      ; DFFC
;* [[SP] - 4] ← [A],            ;  A                         ; DFFB
;* [[SP] - 5] ← [B],            ;  B                         ; DFFA
;* [[SP] - 6] ← [SR,]           ; CC                         ; DFF9
;* [SP] ← [SP] - 7,             ; unknown (consider it junk) ; DFF8
;* [PC(HI)] ← [$FFFA],
;* [PC(LO)] ← [$FFFB]
;* 
;* 
;* |------+-------+-------+-------+-----|
;* | Addr | value | SP    | Notes | SWI |
;* |------+-------+-------+-------+-----|
;* | DFF8 |       | <- SP | X     |     |
;* | DFF9 | CCR   |       | 1,X   | 0,X |
;* | DFFA | Acc B |       | 2,X   | 1,X |
;* | DFFB | Acc A |       | 3,X   | 2,X |
;* | DFFC | X Hi  |       | 4,X   | 3,X |
;* | DFFD | X Lo  |       | 5,X   | 4,X |
;* | DFFE | PC Hi |       | 6,X   | 5,X |
;* | DFFF | PC Lo |       | 7,X   | 6,X |
;* |------+-------+-------+-------+-----|
;* 
; ===========================================================================
;*
;*      ENTER FROM SOFTWARE INTERRUPT
;*
SFE     STS     SP              ;* SAVE TARGET'S STACK POINTER
        TSX
;*
;*      DECREMENT P-COUNTER to point to the SWI
;*
        TST     6,X             ;* Test PCLO
        BNE     PCLO            ;* *+4
        DEC     5,X             ;* Borrow from PCHI
PCLO    DEC     6,X             ;* Dec PCLO
        

    ifdef NADA
        psha                    ;* 0000 FF42414344201BFF
        ldaa    0,X
        staa    0               ;* 0000 CC = FF
        ldaa    1,X
        staa    1               ;* 0001 B  = 42
        ldaa    2,X
        staa    2               ;* 0002 A  = 41
        ldaa    3,X
        staa    3               ;* 0003 X  = 4344
        ldaa    4,X
        staa    4
        ldaa    5,X
        staa    5               ;* 0005 PC = 201B
        staa    PC
        ldaa    6,X
        staa    6
        staa    PC+1
        pula
    endif
;*
;*      PRINT Addr and OP
;*
	ldx     5,X             ;* 5,X is PC
	stx	SAVEX           ;* SAVEX  (temp, X gets clobbered by PRNTOP, expect PC is in X)
        ;stx     $20             ;* (njc)
	jsr	PRNTOP          ;* Print Address and Instruction
        tsx
;*
;*      PRINT CONTENTS OF STACK
;*
PRINT   jsr     CC              ;* OUT2HS  ;* CONDITION CODES
        jsr     OUT2HS          ;* ACC-B
        jsr     OUT2HS          ;* ACC-A
        jsr     OUT4HS          ;* X-REG
        jsr     OUT4HS          ;* P-COUNTER
        ldx     #SP
        jsr     OUT4HS          ;* STACK POINTER Address
C2      jmp     CONTRL          ;* was BRA

;
; Loop to print CC as bits
;
CC	ldx	#REMSG          ;* Register string
	jsr	PDATA1          ;*
        ldx     SP              ;* Get the user stack
        ldab    1,X             ;* Get CC Register
        aslb                    ;*
        aslb                    ;* Ready for shifting into carry
        ldx     #$06            ;* Get Counter
RELOOP  aslb                    ;* Move next bit into carry
        ldaa    #$30            ;*
        adca    #$00            ;* Convery to ASCII
        jsr     OUTEEE          ;* Print it
        dex                     ;* Bump counter
        bne     RELOOP          ;* Print next bit
        jsr     OUTS            ;* Print space
        ;;
        ;;  Clean up where X points
        ;; 
        ldx     SP              ;* Restore X
        inx                     ;* past current address
        inx                     ;* past CC

        rts

;* -----------------------------------------------------------------------------
;*
;*      PUNCH DUMP
;*      PUNCH FROM BEGINING ADDRESS (BEGA) THRU ENDI
;*      ADDRESS (ENDA)
;*
MTAPE1  FCB     '\r\nS1\4'      ;* PUNCH FORMAT
;       FCB     1,1,1,1 ;* GRUE
PUNCH   EQU     *
        LDX     BEGA
        STX     TW      ;* TEMP BEGINING ADDRESS
PUN11   LDAA    ENDA+1
        SUBA    TW+1
        LDAB    ENDA
        SBCB    TW
        BNE     PUN22
        CMPA    #16
        BCS     PUN23
PUN22   LDAA    #15
PUN23   ADDA    #4
        STAA    MCONT   ;* FRAME COUNT THIS RECORD
        SUBA    #3
        STAA    TEMP    ;* BYTE COUNT THIS RECORD
;*
;*      PUNCH C/R,L/F,NULL,S,1
;*
        LDX     #MTAPE1
        JSR     PDATA1
        CLRB            ;* ZERO CHECKSUM
;*
;*      PUNCH FRAME COUNT
;*
        LDX     #MCONT
        BSR     PUNT2   ;* PUNCH 2 HEX CHAR
;*
;*      PUNCH ADDRESS
;*
        LDX     #TW
        BSR     PUNT2
        BSR     PUNT2
;*
;*      PUNCH DATA
;*
        LDX     TW
PUN32   BSR     PUNT2   ;* PUNCH ONE BYTE (2 FRAMES)
        DEC     TEMP    ;* DEC BYTE COUNT
        BNE     PUN32
        STX     TW
        COMB
        PSHB
        TSX
        BSR     PUNT2   ;* PUNCH CHECKSUM
        PULB            ;* RESTORE STACK
        LDX     TW
        DEX
        CPX     ENDA
        BNE     PUN11
        jmp     CONTRL
;*      BRA     C2      ;* JMP TO CONTRL
;*
;*      PUNCH 2 HEX CHAR UPDATE CHECKSUM
;*
PUNT2   ADDB    0,X     ;* UPDATE CHECKSUM
        JMP     OUT2H   ;* OUTPUT TWO HEX CHAR AND RTS
;*
;* -----------------------------------------------------------------------------
;*
;       FCB     1,1,1,1,1,1     ;* GRUE
MCL     fcc     '\r\n* \4'
;       FCB     1,1,1,1 ;* GRUE
;*
;*      SAVE X REGISTER
SAV     STX     XTEMP
        RTS
;       FCB     1,1,1   ;* GRUE
;*
;*      INPUT ONE CHAR INTO A-REGISTER
INEEE
        BSR     SAV
IN1     LDAA    ACIACS
        ASRA
        BCC     IN1     ;* RECEIVE NOT READY
        LDAA    ACIADA  ;* INPUT CHARACTER
        ANDA    #$7F    ;* RESET PARITY BIT
        CMPA    #$7F
        BEQ     IN1     ;* IF RUBOUT, GET NEXT CHAR
        BSR     OUTEEE
        RTS
;       FCB     1,1,1,1,1,1,1,1 ;* GRUE
;       FCB     1,1,1,1,1,1,1,1 ;* GRUE
;       FCB     1       ;* GRUE
;*
;*      OUTPUT ONE CHAR 
OUTEEE  PSH     A
OUTEEE1 LDAA    ACIACS
        ASRA
        ASRA
        BCC     OUTEEE1
        PULA
        STAA    ACIADA
        RTS
;* -----------------------------------------------------------------------------
; 
FMINST  jsr	FROMTO          ;* Get From/To (BEGA/ENDA)
	ldx	#WITHST         ;*
	jsr	PDATA1
	jsr	BYTE            ;* Get What to fill with
	ldx	BEGA            ;*
	dex
FM1	inx
	staa	0,X
	cpx	ENDA            ;*
	bne	FM1
        jmp     CONTRL

WITHST  fcc     "WITH? \4"
;* -[ Jump ]--------------------------------------------------------------------
;
        ;;
        ;; JU - JUMP to user program
        ;; 
JUINST  ;jsr     CRLF
	ldx     #ADDRST
        jsr     PDATA1
        jsr	BADDR           ;* Get the address and put it in X (L 768A)

        ;jsr     OUTS            ;
        jsr     CRLF
	
        ;ldx     #BADDRH         ;* njc
        ;jsr     OUT4HS
        ;ldx     BADDRH          ;* njc - live dangerously?
	
	;lds	SP              ;*
	lds	#DSTACK         ;*
	
	jsr	0,X		;* JUMP to the User program (INFO: index jump)
        ldx     #DONE           ;*
        jsr     PDATA1
	jmp	CONTRL          ;*

;* -[ Start SS ]----------------------------------------------------------------
; 
SFRMST  fcc     "START FROM ADDRESS: \4"
;*
;* 
;*
;* Okay in oder to single step what do we need?
;* 1. Starting address in the PC
;* 2. decode of the instruction so we can save and add an SWI after
;* 3. The SWI inserted and the original code saved
;*
;* Thoughts 13 - Pg 119
;* ... I (Peter) also treat the stack differently. MIKBUG and SWTPC bug always
;* initiaize the stack wehn they started up at A042 and down. The G command then
;* loads the next seven bytes into the CPU registers and jumps to the user code
;* with the stack pointer pointing to A049. So, in a way, we can think of the
;* area below A042 as being a monitor stack, while the area just below A049 as
;* a user stack.
;*
STINST: ldx	#SFRMST         ; $7B6C
	jsr	PDATA1
	jsr	BADDR           ;* L768A
        ;;*
        ;;* I should store X DSTACK+6 (PC) as if we just hit an SWI and everything
        ;;* was pushed on the DSTACK (which is now DSTACK-7)
        ;;* A042 - Mon stack
        ;;* A049 - Usr stack
        ;;*
	;stx	$A042+6         ;* @FIXME: might not be correct (X7FFC was BEGA)
	stx	PC              ;* @FIXME: might not be correct (X7FFC was BEGA)
	ldx	#CONTRL         ;*
;*
;* This is probably the return address when the User code is done (rts'd?)
;*
	stx	ENDA            ;* @FIXME: might not be correct (X7FFE)
	ldx	#DSTACK         ;* (X7FF6)
	stx	SP              ;* (X770F)
;*
;*
;*
SSINST  ldx	SP              ;*
    ifdef NADA
        psha                    ;* 0010 40D5424143442053
        ldaa    0,X
        staa    $10             ;* 0010 junk
        ldaa    1,X
        staa    $11             ;* 0011 CC = D5
        ldaa    2,X
        staa    $12             ;* 0012 B  = 42
        ldaa    3,X
        staa    $13             ;* 0013 A  = 41
        ldaa    4,X
        staa    $14             ;* 0014 X  = 4344
        ldaa    5,X
        staa    $15
        ldaa    6,X
        staa    $16             ;* 0016 PC = 201C
        ldaa    7,X
        staa    $17
        ldaa    8,X             ;* Return address Looks more like B, A
        staa    $18
        ldaa    9,X
        staa    $19
        pula
    endif
	ldx	6,X             ;* PC
	stx	PC              ;* USER PC
	stx	SAVEX           ;* SAVEX  (temp, X gets inc'd by PRNTOP)
        ;stx     $2E             ;* (njc)
	jsr	PRNTOP          ;* Print Address and Instruction (L79CE, DE2)
;
;
        ldx     SAVEX
        ;stx     $26             ;* (njc)
        ;;
        ;; It appears that the 2nd step doesn't correct the old SWI.    WHY???
        ;; @FIXME: NEXT/SAVINST has wrong inst here!
        ;; 
	stx	NEXT            ;* NEXT   @D030 (X76EC)
	ldaa	0,X             ;* Get current instruction
	staa	SAVINST         ;* Save it
        ;; 
        ;staa    $28             ;* (njc) We're correct to here >>> !!! <<<
        ;; 
	ldaa	#_SWI           ;* $3F Replace with SWI
	staa	0,X             ;* Replace instruction with SWI
	cmpa	0,X             ;* Check it
	bne	NOGOOD          ;*
	ldaa	SAVINST         ;* INSTR @D044 Set op code
	cmpa	#$20            ;*
	bcs	NOBR            ;* No Branch (L7BC2)
	cmpa	#$30            ;* [A] - data8 If A < 30 set Carry
	bcs	YESBR           ;* Yes (L7C34) Branch if carry set
;
NOBR	cmpa	#$39            ;* RTS - Check for rts
	bne	NOTRTS          ;* No (L7BC9)
	jmp	RTSIN           ;* Yes (L7C7E)
;
NOTRTS	cmpa	#$3B            ;* RTI - 
	beq	NOGOOD          ;* Don't Do RTI
	cmpa	#$3F            ;* SWI -
	beq	NOGOOD          ;* Ditto for SWI
	cmpa	#$6E            ;* JMP
	bne	NOTJIN          ;* 
;
JINV	jmp	JINDEX          ;* Ok for indexed jumps (L7C6D)
;
NOTJIN	cmpa	#$AD            ;* JSR -
	beq	JINV            ;* Ditto (L7BD5)
	cmpa	#$7E            ;* JMP -
	beq	JEXT            ;* Ok for Extended jumps (L7C5B)
	cmpa	#$BD            ;* JSR
	beq	JEXT            ;* Ditto (L7C5B)
	cmpa	#$8D            ;* BSR -
	beq	YESBR           ;* BSR is a branch too (L7C34)
    ifdef MC10                  ;* 6801 jsr instruction, otherwise HCF (slow?)
	cmpa	#$9D            ;* JSR - Index
	beq	JSRIN           ;* (L7C62)
    endif
	cmpa	#$3E            ;* WAI - 
	bne	NORMAL          ;* Ok if not WAI (L7C05)
;*
;* @FIXME: 2 Problems, leaves SWIstores the next instruction not current
;*
;* Thoughts 14 - Pg 189  Listing 20
;*
NOGOOD	ldx	#NOST           ;*
	jsr	PDATA1          ;* Print "NO!"
        ;;
        ;; Restore the SAVINST
        ;; 
	ldx	NEXT            ;* NEXT
	ldaa	SAVINST         ;* NEXT+2
	staa	0,X             ;* Restore next instr on error
;	rts	                ;* Next command
	jmp	CONTRL          ;* Next command
;
NOST    fcc     "NO!\4"

;* -----------------------------------------------------------------------------
NORMAL	ldaa	#$FF            ;* Erase alt address loc
	staa	BRANCH          ;* (X76E9)
GOUSER	ldx	#SSRETN         ;* Redirect SWI return
        stx     SWIJMP
	lds	SP              ;* set user stack
	rti                     ;* Go to user

;* -----------------------------------------------------------------------------
; Is this L7C14?
SSRETN	ldx	SFE             ; Restore the break address
        stx     SWIJMP
	ldx	NEXT            ;* Restore thee next OP Code
        ;stx     $1C             ;* $1C & $D Next (njc)
	ldaa	SAVINST         ;*
	staa	0,X
        ;staa    $1E            ;* (njc)
	ldaa	BRANCH          ;* Check branch addr
	cmpa	#$FF
	beq	NONE            ;* 
	ldx	BRANCH          ;* Restore the branch address
        ;stx     $2C            ;* (njc)
	ldaa	BRANCH+2        ;* Instruction
	staa	0,X
        staa    $2E             ;* (njc)
NONE
	jmp	SFE             ;* Store stack ptr & print registers
;*
;* Handle Effective address of branch
;
YESBR	ldx	PC              ;*
	ldab	1,X             ;* Get offset
	beq	ZEROOF          ;* Zero offset
	bmi	MINOFF          ;* Minus offset
;*
;* Plus offset
;*
PLUSOF	inx
	decb
	bne	PLUSOF          ;* 
ZEROOF	inx                     ;* Point to next instruction
	inx                     ;*
GOTADD	stx	BRANCH          ;* Save address
	ldaa	0,X             ;* Get instruction
	staa	BRANCH+2        ;* Save it
	ldaa	#_SWI           ;* $3F
	staa	0,X             ;* Substitute WI
	cmpa	0,X             ;* Check that it went in
	beq	GOUSER          ;* Go to user if ok (L7C0A)
	bra	NOGOOD          ;* If it didn't store properly
;*
;* Minus offset
;*
MINOFF	dex                     ;* Subtract offset
	incb                    ;* From instruction address
	bne	MINOFF          ;* (L7C55)
	bra	ZEROOF          ;* (L7C41)
;
JEXT	ldx	PC              ;*
	ldx	1,X             ;* Get extended jump address
	bra	GOTADD          ;* Go take care of it (L7C43)
;* -----------------------------------------------------------------------------
;*
;* Handle Indexed jump
;*
JINDEX	ldx	PC               ;*
	ldab	1,X              ;* Get offset
	ldx	SP               ;* (X770F)
	ldx	4,X              ;* Get user Index register
	dex                      ;*
	dex                      ;* Point to 2 bytes under
	tstb                     ;*
	beq	ZEROOF           ;* If offset is zero (L7C41)
	bra	PLUSOF           ;* If offset is nonzero (L7C3D)
;*
;* Handle RTS instruction
;*
RTSIN	ldx	SP               ;* Get user stack pointer X770F
	ldx	8,X              ;* Get return address from user's stack
	bra	GOTADD           ;* And treat it as a jump (L7C43)

;* -----------------------------------------------------------------------------
;
;* -----------------------------------------------------------------------------
HELLOST fcb     '\12\r\nMODBUG 1.11.18\4' ;* 12 = ^L (CLS)
;* -----------------------------------------------------------------------------
; ==============================================================================
;OUTCH
CRLF    stx     OUTEXR
        ldx     #CRLFST         ; ($771F)
        jsr     PDATA1
        ldx     OUTEXR
        rts
;
CRLFST  fcc     "\r\n\4"
;
;; 
;; Send out:
;;    'FROM '
;; Get 4 byte hex addr
;; load into BEGA
;; Send out:
;;    'TO '
;; Get 4 byte hex addr
;; load into ENDA
;; 
;* -[ From/To ]-----------------------------------------------------------------
FROMTO  ldx     #FROMST         ;* Print From ($799D) @FIXME
        jsr     PDATA1          ;*
        jsr     INEEE           ;*
        cmpa    #CR             ;* CR to escape
FRTO1   bne     FRTO2           ;* 
        jmp     CRLF            ;* We're Done (uses rts to return)
        ;;
        ;; Convert a hex string to bin
        ;; $30 - $46 (0 - F)
        ;; to
        ;; $00 - $0F
        ;; 
FRTO2   suba    #$30
        bmi     NOTHEX           ; Not a Valid hex (less than '0' - L 799A) L799A
        cmpa    #$09
        ble     GOTONE          ; 0 >= A >= 9 (0 - 9)
        cmpa    #$11            ; 'A' - $30
        bmi     NOTHEX
        cmpa    #$16            ; 'F' - $30
        bgt     NOTHEX
        suba    #$07
;DIGIT 
GOTONE  asla                    ; @FIXME
        asla
        asla
        asla                    ;* Shift lo nibble to high
        tab                     ;* Stow it in B
        jsr     INHEX           ;*
        aba                     ;* Combine A & B
        staa    BEGA            ;* 
        jsr     BYTE
        staa    BEGA+1          ; BEGIN   (was X7706)
;*
;* Get ENDA (xxxx)
;*
        ldx     #TOSTR          ; Print TO ($79A4)
        jsr     PDATA1          ; (L 7724)
        jsr     BADDR           ;*
        stx     ENDA            ;*

        jmp     OUTS            ;* (uses rts to return)
;
NOTHEX  ins                     ;*
        ins                     ;*
        rts                     ;*
;
;GOTTWO
;
FROMST  fcc   " FROM \4"
TOSTR   fcc   " TO \4"

;* -[ AD - ASCII Dump ]---------------------------------------------------------
ADINST  jsr     FROMTO          ;* GET ADDRESSES
        ldx     BEGA            ;* GET STARTING ADDRESS
        stx     SAVEX           ;* Art: SAVEX (SAVEX)
        stx     TEMP1           ;* Art: doesn't have this
;*
;* First half, Hex - Uses SAVEX
;*
NXTLIN  jsr     CRLF            ; (L 7717)
        ldx     #SAVEX          ;* SAVEX
        jsr     OUT4HS          ; (L 76D6) Addr
        tst     OUTS            ; (X 76DA) Spaces
        ldab    #$08            ;* First half of the 16 (Hex)
        ldx     SAVEX           ;* SAVEX

AD2     jsr     OUT2H           ;*
        decb
        bne     AD2             ;* Print first 8

        stx     SAVEX           ;* SAVEX
        jsr     OUTS            ;* Middle space
        ldab    #$08            ;* Second half of the 16 (Hex)
        ldx     SAVEX           ;* SAVEX (OUT2H inc X)

AD3     jsr     OUT2H           ;* 
        decb
        bne     AD3             ;* Print second 8

        stx     SAVEX           ;* SAVEX
;*
;* Second half, ASCII uses TEMP1
;*
AD4     jsr     OUTS            ; (L 76DA)
        ldab    #16             ;* output 16 ASCII Chars
        ldx     TEMP1

NXTASC  ldaa    0,X
        dex
        cpx     ENDA            ;* Compare ENDA-1
        bne     AD6             ;*
ADONE   jmp     CONTRL          ;* Done
;
AD6     inx                     ;* Fix X
        inx                     ;* Next character
        stx     TEMP1
;
; shows $20-$7E as ASCII, dot otherwise
;
        cmpa    #$7F-1          ;* [A] - DEL
        bhi     PDOT            ;* Print Dot
        cmpa    #$20-1          ;* Space?
        bhi     PCH             ;* Pint Character

PDOT    ldaa    #$2E            ;* $2E = dot
PCH     jsr     OUTEEE
        decb
        bne     NXTASC          ;*
        ;; 
        ldx     SAVEX
        dex
        cpx     ENDA            ;* Compare ENDA-1
        beq     ADONE           ;* Done
        ;; 
        bra     NXTLIN          ;*
; ------------------------------------------------------------------------------
;
;  DISASSEMBLE "X" COMMAND
;
DEINST: jsr	FROMTO          ; (L 7957)
	ldx	BEGA            ;* X7705
	stx	SAVEX
DE1	bsr	PRNTOP          ;* Goto to print current line (L79CE)
	ldaa	ENDA            ;* Subtract next from last (X7707)
	ldab	ENDA+1          ;* (X7708)
	subb	SAVEX+1         ;* (X7712)
	sbca	SAVEX           ;* 
	bcc	DE1             ;* Return if next <= last (L79BD)
        jmp     CONTRL
;	rts                     ;* Otherwise exit
;*
;* PRNTOP - Subroutine to print address and current instruction
;*
PRNTOP	jsr	CRLF            ;*
	ldx	#SAVEX          ;* Set location of next address
;*
;* Print address
;*
	jsr	OUT4HS          ;* Print it
	jsr	OUTS            ;* 
	ldx	SAVEX           ;* Get address of instruction
	ldaa	0,X             ;* Get operation code
	staa	SAVINST         ;* Save it
        ;; 
        ;staa    $0D             ;* (njc) @FIXME: Here's the dang wrong OP Code
;*
;* Print op
;*
	jsr	OUT2HS          ;* Print it (L76D8)
	stx	SAVEX           ;* Increment SAVEX
	clrb                    ;* Byte counter
	ldaa	SAVINST         ;*
	anda	#$BF            ;* Analyze DP code for no. of bytes
	cmpa	#$83            ;
	beq	LENGTH3         ;* L7A0B
	anda	#$FD
	cmpa	#$8C            ;
	beq	LENGTH3         ;* L7A0B
	ldaa	SAVINST
	anda	#$F0
	cmpa	#$20
	beq	LENGTH2         ;* L7A0C
	cmpa	#$60
	bcs     LENGTH1         ;* L7A0D
	anda	#$30
	cmpa	#$30
	bne	LENGTH2         ;* L7A0C
LENGTH3	inc     B               ;* 3-byte: 8C,*E,CE,7x,Bx,Fx
LENGTH2	inc     B               ;* 2-byte: 2x,6x,8x,9x,Ax,C,Dx,Ex
LENGTH1	stab	COUNT           ;* 1-byte: 1x,3x,4x,5x (X76FC)
	beq	POP3            ;* (L7A22)
	dec	COUNT           ;* (X76FC)
	beq	POP1            ;* (L7A1C)
	jsr	OUT4HS          ;* (L76D6)
	bra	POP2            ;* (L7A1F)

POP1	jsr	OUT2HS          ;* (L7A1C)
POP2	stx	SAVEX           ;* (L7A1F)
POP3	rts                     ;* (L7A22)
;
; ------------------------------------------------------------------------------
	;; 
	;;  **Use JSR so this uses RTS**
        ;; 
;; 
;; BR - Add a Break Point - SET/RESET UP TO FOUR BPS
;;
;; BKTAB[n] = | Addr | op | an addr of $FFxx means empty ($FFxx is ROM)
;; 
BRINST  bsr	BKNUM           ; GET NUMBER OF DESIRED BP (L 7A6A); X contains BKTAB Addr
	stx	TMPSTR          ; Save BP# to tmp (what are we saving?)
	bsr	BERASE          ; GO ERASE OLD ONE & Restore if nec. (L 7A4C)
	ldx	#ADDRST         ; ($7936)
	jsr	PDATA1          ; Print " ADDR? "(L 7724)
	jsr	BADDR           ; GET ADDRESS (L 768A)
;*
;* X now contains the BP address
;*
	stx	BRTMP           ; Save Addr to tmp (X 76EC)
	ldab	0,X             ; Get op @X  -> B
	ldaa	#_SWI           ; GET SWI INSTR -> A ($3F)
	staa	0,X             ; Stow   SWI -> @X
	ldx	TMPSTR          ; Get BP# from tmp (X 7711)
;*       Hi Lo #
;* BPTAB addr1 OP
;*       addr2 OP
;*       addr3 OP
;*       addr4 OP
;*
	ldaa	BRTMP           ; Get hi(Addr) from tmp (X 76EC)
	staa	0,X             ; BP # A -> TMPSTR[0]
	ldaa	BRTMP+1         ; Get lo(Addr) from tmp (X 76ED) ldd perhaps?
	staa	1,X             ; 
	stab	2,X
	rts
;
BERASE  ldab	2,X             ; Get OP
	ldaa	0,X             ; Get Part of Address (Hi)
	cmpa	#$FF            ; Was there an Address?
	beq	BEEXIT          ; No, Exit (L 7A5F)
	ldx	0,X             ; Yes, Get Addr of Break
	stab	0,X             ; Restore OP
	ldx	TMPSTR          ; (X 7711)
	ldaa	#$FF            ;
	staa	0,X             ; Erase BP Table Entry
BEEXIT  rts                     ; and Return
                                ;
        ;;
        ;; BKNUM routine - Get # of Desired BP & Point to its location in
        ;; BKTAB
        ;; 

NUMST   fcc     " NUMBER: \4"
ADDRST  fcc     " ADDR: \4"
;
BKNUM   ldx	#NUMST          ; ($7A60)
	jsr	PDATA1          ; (L 7724)
	jsr	INEEE           ; GET BP# (L 7733)
	suba	#$30            ; CONVERT FROM ASCII
	bmi	BKNUM1          ; (L 7A8D)
	beq	BKNUM1          ; (L 7A8D)
	cmpa	#$04
	bgt	BKNUM1          ; IF Greater Than 4 (L 7A8D)
	psha
	jsr	OUTS            ; (L 76DA)
	pula
	ldx	#BKTAB          ;* ($76EF)
BKLOOP  deca
	beq	BKEXIT          ; (L 7A8F)
	inx
	inx
	inx
	bra	BKLOOP          ; (L 7A85)
;
BKNUM1  ins
	ins
BKEXIT  rts
; ------------------------------------------------------------------------------
;; 
;; BP - Print Break table
;; 
BPINST: ldab	#$30            ; BP Number in ASCII '0'
	ldx	#BKTAB          ; ($ 76EF)
	stx	SAVEX           ;* Tmp storage ?
BPR1:   incb
	cmpb	#$35            ;* Stop at 5 BPs (isn't it actual 4?)
	bne	BPR2            ;* No Display BP1 - BP4 (L 7A9E)
	jmp     CONTRL          ;* RETURN WHEN DONE
;
BPR2:   jsr	CRLF            ; Print CR/LF (L 7717)
	tba                     ; GET BP NUMBER
	jsr	OUTEEE          ; PRINT BP NUMBER (L 7769)
	ldx	SAVEX           ; GET BP ADDRESS
	ldaa	0,X           ; GET BP ADDRESS
	cmpa	#$FF            ; IS THERE ONE?
	bne	BPR3            ; YES, GO PRINT IT (L 7AB3)
	inx
	inx
        inx
	bra	BPR4            ; AND REPEAT (L 7ABF)
;
BPR3:   jsr	OUTS            ; PRINT SPACE (L 76DA)
	ldx	SAVEX
	jsr	OUT4HS          ;* PRINT ADDRESS OF BP (L 76D6)
	jsr	OUT2HS          ;* PRINT OP CODE (L 76D8)
BPR4:   stx	SAVEX
	bra	BPR1            ;* Next BP (L 7A98)

; -[ Find ]---------------------------------------------------------------------
;*
    ifndef      NADA
; ===========================================================================
        ;;* E305 14 Pg 183R
        ;ORG     $E305          ;

FIND
FIINST  ldx     #MANYST         ;* ($E0AB)
        jsr     PDATA1          ;* Ask "How many btyes"
        jsr     INEEE           ;* Get a number
        suba    #$30            ;* Convert from ASCII
        beq     FIND5           ;* if = 0
        bmi     FIND5           ;* if < 0
        cmpa    #$03            ;*
        bgt     FIND5           ;* If > 3
        staa    FINDNO          ;* store number of bytes ($D025)
        jsr     OUTS            ;*
        ldx     #WHATST         ;* ($E1EA)
        jsr     PDATA1          ;* Ask "What bytes"
        ldx     #WHAT           ;* ($D025)
        ;;
        ;; Get the 'WHAT' to search for
        ;;
        ldab    FINDNO
FIENTR  pshb                    ;*
        jsr     BYTE            ;* Enter a byte
        staa    0,X             ;* Store it
        jsr     OUTS
        inx                     ;*
        pulb                    ;* Restore counter
        decb                    ;*
        bne     FIENTR          ;* Enter more, if needed
        ;;
        ;; Now ask the address range
        ;; 
        jsr     FROMTO          ;* Get BEGA and ENDA
        ldx     BEGA            ;* Get ready to look
FIND1   ldab    FINDNO          ;* Main find loop ($D025)
        ldaa    0,X             ;* Get first byte
        cmpa    WHAT            ;*
        bne     FIND4           ;* Wrong byte
        ;;
        ;;  Found #1
        ;; 
        decb                    ;*
        beq     FIND2           ;* Found one correct byte
        ldaa    1,X             ;* Get second byte
        cmpa    WHAT+1          ;*
        bne     FIND4           ;* Wrong
        ;;
        ;; Found #2
        decb                    ;*
        beq     FIND2           ;* Found two correct bytes
        ldaa    2,x             ;* Get tird byte
        cmpa    WHAT+2          ;*
        bne     FIND4           ;* Wrong byte
        ;;
        ;; Found #3
        ;; 
FIND2   stx     SAVEX           ;* Found correct bytes
        bsr     FIND5           ;* Print CRLF via vector at FIND5
        ldx     #SAVEX          ;* Point to address where found ($D020)
        jsr     OUT4HS          ;* Print it -
        jsr     OUTS            ;* One more space
        ldx     SAVEX           ;*
        ldab    #$04            ;* Ready to print 4 bytes
FIND3   jsr     OUT2HS          ;* Print byte
        decb                    ;*
        bne     FIND3           ;* Print four bytes
        ldx     SAVEX           ;* Restore X
FIND4   cpx     ENDA            ;* See if doine
        beq     FIEND           ;* Yes
        inx                     ;* No
        bra     FIND1           ;* Keep looking
        ;;
        ;;
        ;; 
FIND5   jmp     CRLF            ;* Do last CRLF nd return to FCROM when done ($E37E)

FIEND   jmp     CONTRL

    else
FIINST: ldx	#MANYST         ;*
	jsr	PDATA1
	jsr	INEEE           ;*
	suba	#$30
	beq	FIND6
	bmi	FIND6
	cmpa	#$03
	bgt	FIND6
	staa	NBYTES          ;*
	jsr	OUTS            ;*
	ldx	#WHATST         ;*
	jsr	PDATA1
	ldab	NBYTES          ;*
	ldx	#NEXT           ;*
FIND1	pshb
	jsr	BYTE
	pulb
	staa	0,X
	inx
	decb
	bne	FIND1
	jsr	CRLF
	jsr	FROMTO          ; (L7957)
	ldx	BEGA            ;* X7705
FIND2	ldab	NBYTES          ;* X76E9
	ldaa	0,X
	cmpa	NEXT            ;* (X76EC)
	bne	FIND5
	decb
	beq	FIND3
	ldaa	1,X
	cmpa	NEXT+1          ;* (X76ED)
	bne	FIND5
	decb
	beq	FIND3
	ldaa	2,X
	cmpa	SAVINST         ;* (X76EE)
	bne	FIND5
FIND3	stx	SAVEX
	bsr	FIND6
	ldx	#SAVEX
	bsr	FIND7
	jsr	OUTS            ; (L 76DA)
	ldx	SAVEX
	dex
	ldab	#$04
FIND4	jsr	OUT2HS          ; (L 76D8)
	decb
	bne	FIND4
	ldx	SAVEX
FIND5	cpx	ENDA            ; X7707
	beq	FIND6
	inx
	bra	FIND2

FIND6	jsr	CRLF
        jmp     CONTRL

FIND7	jmp	OUT4HS          ; L76D6
    endif
;
MANYST  fcc     "HOW MANY? \4"
WHATST  fcc     "WHAT? \4"
; ------------------------------------------------------------------------------
        ;; Fill up to FFD0 with FF
        dc.b [(*+($FFF8-*))&$FFF8-*]$ff
;
;*
;*      VECTOR
VECTORS ORG     $FFF8           ; EPROM Fill
;
IRQ     FDB     IO
SWI     FDB     SWIH
NMI     FDB     POWDWN
RESET   FDB     START

        END
;* =[ Fini ]====================================================================
;asl -i . -D _E000 -L mikbug.asm
;p2hex +5 -e 0xE1C6 -F Moto -r '$-$' mikbug.p mikbug.s19
;STR=$(bash ./s0.sh "Mikbug 6800")
;sed -i "s/S0030000FC/${STR}/" mikbug.s19
;srec_info mikbug.s19 
;miniprohex --offset -0xE000 -p AT28C64B -w mikbug.s19
;
;/* Local Variables: */
;/* mode: asm        */
;/* End:             */
