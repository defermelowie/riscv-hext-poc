#include "riscv_encoding.h"
#include "syscall_encoding.h"

# Register is 8 bytes in RV64 
#define REGBYTES 8

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
1:  # Setup trap delegation
    li t0, 0x100 # Delegate ecalls from VU-mode
    csrw hedeleg, t0
    csrwi hideleg, 0x0
    # Setup trap handler
    la t0, hypervisor_trap_vector
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
    # Save trap frame to memory
    csrw sscratch, sp          # Write sp to sscratch
    la sp, strap_frame
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
    csrr t0, sscratch   
    sd t0, 2*REGBYTES(sp)      # Save original value of sp
    csrr t0, sstatus    
    sd t0, 32*REGBYTES(sp)     # Save sstatus
    csrr t0, sepc 
    sd t0, 33*REGBYTES(sp)     # Save sepc
    # Handle trap
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

pop_trap_frame:
    ld t0, 33*REGBYTES(sp)     # Load sepc
    csrw sepc, t0
    ld t0, 32*REGBYTES(sp)     # Load sstatus
    csrw sstatus, t0
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
    sret

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
    and t1, a0, t1 # Mask out H-bit
    sd t1, 10*REGBYTES(sp) # Save masked misa 
    ld t2, 33*REGBYTES(sp)  # Add 4 to sepc in trap frame
    addi t2, t2, 0x4
    sd t2, 33*REGBYTES(sp)  
    j pop_trap_frame
    # Unhandled ecall
1:  li a0, ECALL_EXIT_FAILURE
    ecall
    unimp

.data

strap_frame:
    .skip 34*REGBYTES, 0x0