#include "riscv_encoding.h"
#include "syscall_encoding.h"

.global hypervisor_start

hypervisor_start:
    # Make sure that hypervisor extension is available
    li a0, ECALL_CSR_MISA
    ecall
    andi a0, a0, 0x80   # Mask out H
    li t0, 0x80         # H should be 0b1
    bne a0, t0, exit_failure
    # Make sure this is hart 0
    li a0, ECALL_CSR_MHARTID
    ecall
    bne a0, zero, exit_failure
    # Todo: Return into guest OS
    # Exit success
    li a0, ECALL_EXIT_SUCCESS
    ecall
    unimp

exit_failure:
    li a0, ECALL_EXIT_FAILURE
    ecall
    unimp
