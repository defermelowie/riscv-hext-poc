#include "riscv_encoding.h"

.global hypervisor_start

hypervisor_start:
    li a0, 0x7
    li a1, 0x4
    ecall