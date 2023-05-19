#include "syscall_encoding.h"

.global main

main:
    # Main app code
    nop
    nop
    nop
    li a0, ECALL_MEANING_OF_LIFE
    ecall
    nop
    nop
    nop
    li t1, 42
    bne a0, t1, f
    nop
    nop
    nop
    # Exit success
s:  li a0, ECALL_EXIT_SUCCESS
    ecall
    unimp # Should be unreachable
    # Exit failure
f:  li a0, ECALL_EXIT_FAILURE
    ecall
    unimp # Should be unreachable