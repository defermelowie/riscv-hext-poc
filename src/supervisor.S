#include "riscv_encoding.h"
#include "syscall_encoding.h"

.global supervisor_start

supervisor_start:
    # Check if misa.H is correctly masked out
    li a0, ECALL_CSR_MISA
    ecall
    andi a0, a0, 0x80
    beq a0, zero, 1f
    li a0, ECALL_EXIT_FAILURE
    ecall
    # Setup trap handler
1:  la t0, supervisor_trap_vector
    csrw stvec, t0
    # Return into user application
    csrr t0, sstatus
    li t1, 0xfffffffffffff7ff
    and t0, t0, t1
    csrw sstatus, t0 # Set sstatus.SPP to user (0b0)
    la t0, main
    csrw sepc, t0
    sret
    unimp # Should be unreachable

supervisor_trap_vector:
    csrr t0, scause
    li t1, CAUSE_USER_ECALL
    bne t0, t1, 1f
    j handle_ucall
    # Unhandled interrupt/exception
1:  li a0, ECALL_EXIT_FAILURE
    ecall
    unimp

# Handle ecall from (V)U-mode
handle_ucall:
    mv t0, a0 # Save argument to t0
1:  li t1, ECALL_EXIT_SUCCESS
    bne t0, t1, 1f
    ecall # Forward ecall to higher privilege level
1:  li t1, ECALL_EXIT_FAILURE
    bne t0, t1, 1f
    ecall # Forward ecall to higher privilege level
    # Unhandled ecall
1:  li a0, ECALL_EXIT_FAILURE
    ecall
    unimp
