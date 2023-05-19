#include "riscv_encoding.h"
#include "syscall_encoding.h"

# Register is 8 bytes in RV64 
#define REGBYTES 8

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
    # Setup trap delegation
1:  la t0, 1f
    csrw mtvec, t0
    li t0, 0x500 # Delegate ecalls from VS-mode & U-mode
    csrw medeleg, t0
    csrwi mideleg, 0
    # Setup trap handler
1:  la t0, firmware_trap_vector
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
    unimp # Should be unreachable

firmware_trap_vector:
    # Save trap frame to memory
    csrw mscratch, sp          # Write sp to mscratch
    la sp, mtrap_frame
    sd x1, 1*REGBYTES(sp)      # Save ra
    sd x3, 3*REGBYTES(sp)      # Save gp
    sd x4, 4*REGBYTES(sp)      # Save tp
    sd x5, 5*REGBYTES(sp)      # Save t0
    sd x6, 6*REGBYTES(sp)      # Save t1
    sd x7, 7*REGBYTES(sp)      # Save t2
    sd x8, 8*REGBYTES(sp)      # Save s0
    sd x9, 9*REGBYTES(sp)      # Save s1
    sd x10, 10*REGBYTES(sp)    # Save a0
    sd x11, 11*REGBYTES(sp)    # Save a1
    sd x12, 12*REGBYTES(sp)    # Save a2
    sd x13, 13*REGBYTES(sp)    # Save a3
    sd x14, 14*REGBYTES(sp)    # Save a4
    sd x15, 15*REGBYTES(sp)    # Save a5
    sd x16, 16*REGBYTES(sp)    # Save a6
    sd x17, 17*REGBYTES(sp)    # Save a7
    sd x18, 18*REGBYTES(sp)    # Save s2
    sd x19, 19*REGBYTES(sp)    # Save s3
    sd x20, 20*REGBYTES(sp)    # Save s4
    sd x21, 21*REGBYTES(sp)    # Save s5
    sd x22, 22*REGBYTES(sp)    # Save s6
    sd x23, 23*REGBYTES(sp)    # Save s7
    sd x24, 24*REGBYTES(sp)    # Save s8
    sd x25, 25*REGBYTES(sp)    # Save s9
    sd x26, 26*REGBYTES(sp)    # Save s10
    sd x27, 27*REGBYTES(sp)    # Save s11
    sd x28, 28*REGBYTES(sp)    # Save t3
    sd x29, 29*REGBYTES(sp)    # Save t4
    sd x30, 30*REGBYTES(sp)    # Save t5
    sd x31, 31*REGBYTES(sp)    # Save t6
    csrr t0, mscratch   
    sd t0, 2*REGBYTES(sp)      # Save original value of sp
    csrr t0, mstatus    
    sd t0, 32*REGBYTES(sp)     # Save mstatus
    csrr t0, mepc 
    sd t0, 33*REGBYTES(sp)     # Save mepc
    # Handle trap
    csrr t0, mcause
    li t1, CAUSE_USER_ECALL
    beq t0, t1, exit_failure # Ecalls from VU-mode should be delegated to VS-mode
    li t1, CAUSE_VIRTUAL_SUPERVISOR_ECALL
    beq t0, t1, exit_failure # Ecalls from VS-mode should be delegated to HS-mode
    li t1, CAUSE_SUPERVISOR_ECALL
    beq t0, t1, handle_hscall
    li t1, CAUSE_MACHINE_ECALL
    beq t0, t1, handle_mcall
    j exit_failure # Unhandled interrupt/exception causes failure

pop_trap_frame:
    ld t0, 33*REGBYTES(sp)     # Load mepc
    csrw mepc, t0
    ld t0, 32*REGBYTES(sp)     # Load mstatus
    csrw mstatus, t0
    ld x1, 1*REGBYTES(sp)      # Load ra
    ld x3, 3*REGBYTES(sp)      # Load gp
    ld x4, 4*REGBYTES(sp)      # Load tp
    ld x5, 5*REGBYTES(sp)      # Load t0
    ld x6, 6*REGBYTES(sp)      # Load t1
    ld x7, 7*REGBYTES(sp)      # Load t2
    ld x8, 8*REGBYTES(sp)      # Load s0
    ld x9, 9*REGBYTES(sp)      # Load s1
    ld x10, 10*REGBYTES(sp)    # Load a0
    ld x11, 11*REGBYTES(sp)    # Load a1
    ld x12, 12*REGBYTES(sp)    # Load a2
    ld x13, 13*REGBYTES(sp)    # Load a3
    ld x14, 14*REGBYTES(sp)    # Load a4
    ld x15, 15*REGBYTES(sp)    # Load a5
    ld x16, 16*REGBYTES(sp)    # Load a6
    ld x17, 17*REGBYTES(sp)    # Load a7
    ld x18, 18*REGBYTES(sp)    # Load s2
    ld x19, 19*REGBYTES(sp)    # Load s3
    ld x20, 20*REGBYTES(sp)    # Load s4
    ld x21, 21*REGBYTES(sp)    # Load s5
    ld x22, 22*REGBYTES(sp)    # Load s6
    ld x23, 23*REGBYTES(sp)    # Load s7
    ld x24, 24*REGBYTES(sp)    # Load s8
    ld x25, 25*REGBYTES(sp)    # Load s9
    ld x26, 26*REGBYTES(sp)    # Load s10
    ld x27, 27*REGBYTES(sp)    # Load s11
    ld x28, 28*REGBYTES(sp)    # Load t3
    ld x29, 29*REGBYTES(sp)    # Load t4
    ld x30, 30*REGBYTES(sp)    # Load t5
    ld x31, 31*REGBYTES(sp)    # Load t6
    ld x2,  2*REGBYTES(sp)     # Load sp as last
    mret
    
# Todo: Load trap frame from mem into regfile & csr
# Todo: perform mret
    
# Handle ecall from HS-mode
handle_hscall:
    ld t0, 10*REGBYTES(sp) # Save argument (a0) to t0
1:  li t1, ECALL_EXIT_SUCCESS
    bne t0, t1, 1f
    j exit_success
1:  li t1, ECALL_EXIT_FAILURE
    bne t0, t1, 1f
    j exit_failure
1:  li t1, ECALL_CSR_MISA
    bne t0, t1, 1f
    csrr t1, misa # Save misa to a0 in trap frame
    sd t1, 10*REGBYTES(sp)
    ld t2, 33*REGBYTES(sp)  # Add 4 to mepc in trap frame
    addi t2, t2, 0x4
    sd t2, 33*REGBYTES(sp)  
    j pop_trap_frame # Pop trap frame & return from trap
1:  li t1, ECALL_CSR_MHARTID
    bne t0, t1, 1f
    csrr t1, mhartid # Save mhartid to a0 in trap frame
    sd t1, 10*REGBYTES(sp)
    ld t2, 33*REGBYTES(sp)  # Add 4 to mepc in trap frame
    addi t2, t2, 0x4
    sd t2, 33*REGBYTES(sp)  
    j pop_trap_frame # Pop trap frame & return from trap
1:  j exit_failure # Unhandled ecall causes failure
    
# Todo: Handle ecall from M-mode
handle_mcall:
    j exit_failure

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

# exit_value:
#     fence
#     la t0, tohost
#     sw a0, 0(t0)
#     sw zero, 4(t0)

.data

mtrap_frame:
    .skip 34*REGBYTES, 0x0