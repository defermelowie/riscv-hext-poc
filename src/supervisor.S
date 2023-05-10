#include "syscall_encoding.h"

.global supervisor_start

supervisor_start:
    # Todo: Check if misa.H is correctly masked out
    li a0, ECALL_CSR_MISA
    ecall
    andi a0, a0, 0x80
    beq a0, zero, 1f
    li a0, ECALL_EXIT_FAILURE
    ecall
    # Todo: Return into application main
    # Exit success
1:  li a0, ECALL_EXIT_SUCCESS
    ecall