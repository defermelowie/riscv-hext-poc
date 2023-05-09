#include "syscall_encoding.h"

.global main

main:
    # Main app code
    nop
    nop
    nop
    nop
    nop
    # Exit success
    li a0, ECALL_EXIT_SUCCESS
    ecall
    # Should be unreachable
    unimp