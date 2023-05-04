#include "encoding.h"

.global _start
.align 2

_start:
    # Initialize regiser file to zero
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0
    # Disable multicore (put all cores other than core0 into infinite loop)
    csrr a0, mhartid
1:  bnez a0, 1b
    # Initialize physical memory protection to allow all accesses
1:  la t0, 1f
    csrw mtvec, t0
    li t0, 0x000000008000ffff
    csrw pmpaddr0, t0
    li t0, PMP_TOR | PMP_R | PMP_W | PMP_X
    csrw pmpcfg0, t0
    # Setup no address translation & protection
1:  la t0, 1f
    csrw mtvec, t0
    csrwi satp, 0
    # Todo: Setup trap delegation
1:  la t0, 1f
    csrw mtvec, t0
    csrwi medeleg, 0
    csrwi mideleg, 0
    # Setup trap handler
1:  la t0, trap_vector
    csrw mtvec, t0
    # Return into hypervisor
    csrr t1, mstatus
    li t2, 0xffffff7fffffe7ff
    and t1, t1, t2
    li t2, 0x0000000000000800
    or t1, t1, t2
    csrw mstatus, t1
    la t1, hypervisor_start
    csrw mepc, t1
    mret
    unimp # Program counter should never arrive here

trap_vector:
    csrr t0, mcause
    li t1, CAUSE_USER_ECALL
    beq t0, t1, handle_ucall
    li t1, CAUSE_VIRTUAL_SUPERVISOR_ECALL
    beq t0, t1, handle_vscall
    li t1, CAUSE_SUPERVISOR_ECALL
    beq t0, t1, handle_hscall
    li t1, CAUSE_MACHINE_ECALL
    beq t0, t1, handle_mcall
    j exit_failure # Unhandled interrupt/exception

# Todo: Handle ecall from U-mode (or VU-mode)
handle_ucall:
    li a0, 0x6
    j exit_value
    
# Todo: Handle ecall from VS-mode
handle_vscall:
    li a0, 0x4
    j exit_value
    
# Todo: Handle ecall from HS-mode
handle_hscall:
    li a0, 0x2
    j exit_value
    
# Todo: Handle ecall from M-mode
handle_mcall:
    li a0, 0x1
    j exit_value

exit_success:
    fence
    la t0, tohost
    li t1, 0x1 
    sw t1, 0(t0)
    sw zero, 4(t0)

exit_failure:
    fence
    la t0, tohost
    li t1, 0x3
    sw t1, 0(t0)
    sw zero, 4(t0)

exit_value:
    fence
    la t0, tohost
    sw a0, 0(t0)
    sw zero, 4(t0)