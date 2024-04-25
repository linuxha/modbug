verbose on

x1:

print "\r\n ... sending debug.s19 ...\r\n"

# Load S1
# Simple code from 2000 - 2027
!< /bin/echo -n "L"
!< cat debug.s19
# This will speed things up a bit
expect "\\*"

# Build Break
!< /bin/echo -n "B"
!< /bin/echo -n "1"
!< /bin/echo -n "201B"

# Jump to code
!< /bin/echo -en "\r\r\r"
!< /bin/echo -n "J"
!< /bin/echo -n "2000"

# Desassemble code
!< /bin/echo -n "X"
!< /bin/echo -n "2018"
!< /bin/echo -n "201F"

# unBuild Break
!< /bin/echo -n "B"
!< /bin/echo -n "1"
!< /bin/echo ""

# Step
!< /bin/echo -en "\r\r\r"
!< /bin/echo -n "S"

# Desassemble code
!< /bin/echo -n "X"
!< /bin/echo -n "2018"
!< /bin/echo -n "201F"

#!< /bin/echo -en "\r\r\r"
!< /bin/echo -n "D"
!< /bin/echo -n "0000"
!< /bin/echo -n "002F"

!< /bin/echo -n "D"
!< /bin/echo -n "A000"
!< /bin/echo -n "A02F"

!< /bin/echo -n "D"
!< /bin/echo -n "D000"
!< /bin/echo -n "D02F"

# A Stack
!< /bin/echo -n "D"
!< /bin/echo -n "AFD0"
!< /bin/echo -n "AFFF"

!< /bin/echo -n "D"
!< /bin/echo -n "DFD0"
!< /bin/echo -n "DFFF"

!< /bin/echo -en "\r\r\r"

#print "\r\n ... Stack isn't correct so do it twice ...\r\n"
#!< /bin/echo -n "J"
#!< /bin/echo -n "2000"

!< /bin/echo -n "S"

!< /bin/echo -n "X"
!< /bin/echo -n "2018"
!< /bin/echo -n "201F"

!< /bin/echo -n "D"
!< /bin/echo -n "0000"
!< /bin/echo -n "002F"

!< /bin/echo -n "D"
!< /bin/echo -n "A000"
!< /bin/echo -n "A02F"

!< /bin/echo -n "D"
!< /bin/echo -n "D000"
!< /bin/echo -n "D02F"

# A Stack
!< /bin/echo -n "D"
!< /bin/echo -n "AFD0"
!< /bin/echo -n "AFFF"

!< /bin/echo -n "D"
!< /bin/echo -n "DFD0"
!< /bin/echo -n "DFFF"

!< /bin/echo -en "\r\r\r"

!< /bin/echo -n "S"

!< /bin/echo -n "X"
!< /bin/echo -n "2018"
!< /bin/echo -n "201F"

!< /bin/echo -n "D"
!< /bin/echo -n "0000"
!< /bin/echo -n "002F"

!< /bin/echo -n "D"
!< /bin/echo -n "A000"
!< /bin/echo -n "A02F"

!< /bin/echo -n "D"
!< /bin/echo -n "D000"
!< /bin/echo -n "D02F"

# A Stack
!< /bin/echo -n "D"
!< /bin/echo -n "AFD0"
!< /bin/echo -n "AFFF"

!< /bin/echo -n "D"
!< /bin/echo -n "DFD0"
!< /bin/echo -n "DFFF"

print "\r\n ... Done!\r\n"
