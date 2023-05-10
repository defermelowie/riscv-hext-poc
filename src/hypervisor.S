#include "riscv_encoding.h"
#include "syscall_encoding.h"

.global hypervisor_start

hypervisor_start:
    # Make sure that hypervisor extension is available
    li a0, ECALL_CSR_MISA
    ecall
    andi a0, a0, 0x80   # Mask out H
    li t0, 0x80         # H should be 0b1
    beq a0, t0, 1f
    li a0, ECALL_EXIT_FAILURE
    ecall
    # Make sure this is hart 0
1:  li a0, ECALL_CSR_MHARTID
    ecall
    beq a0, zero, 1f
    li a0, ECALL_EXIT_FAILURE
    ecall
    # Setup trap handler
1:  la t0, hypervisor_trap_vector
    csrw stvec, t0
    # Return into guest OS
    csrr t0, sstatus
    li t1, 0x0000000000000100
    or t0, t0, t1
    csrw sstatus, t0 # Set sstatus.SPP to supervisor (0b1)
    csrr t0, hstatus
    li t1, 0x0000000000000080
    or t0, t0, t1
    csrw hstatus, t0 # Set hstatus.SPV to V=1 (0b1)
    la t0, supervisor_start
    csrw sepc, t0
    sret
    unimp # Should be unreachable

hypervisor_trap_vector:
    csrr t0, scause
    li t1, CAUSE_USER_ECALL
    bne t0, t1, 1f
    li a0, ECALL_EXIT_FAILURE # Ecalls from VU-mode should have been delegated to VS-mode
    ecall
1:  li t1, CAUSE_VIRTUAL_SUPERVISOR_ECALL
    bne t0, t1, 1f
    j handle_vscall
    # Unhandled interrupt/exception
1:  li a0, ECALL_EXIT_FAILURE
    ecall
    unimp

# Handle ecall from VS-mode
handle_vscall:
    mv t0, a0 # Save argument to t0
1:  li t1, ECALL_EXIT_SUCCESS
    bne t0, t1, 1f
    ecall # Forward ecall to firmware
1:  li t1, ECALL_EXIT_FAILURE
    bne t0, t1, 1f
    ecall # Forward ecall to firmware
1:  li t1, ECALL_CSR_MISA
    bne t0, t1, 1f
    ecall # Forward ecall to firmware
    li t1, 0xffffffffffffff7f
    and a0, a0, t1 # Mask out H-bit
    csrr t2, sepc
    addi t2, t2, 0x4
    csrw sepc, t2
    sret
    # Unhandled ecall
1:  li a0, ECALL_EXIT_FAILURE
    ecall
    unimp
