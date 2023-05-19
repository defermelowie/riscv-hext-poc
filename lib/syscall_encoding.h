#define ECALL_EXIT_SUCCESS    0x0 // Exit with success
#define ECALL_EXIT_FAILURE    0x1 // Exit with failure
#define ECALL_CSR_MISA        0x2 // Get ISA register
#define ECALL_CSR_MHARTID     0x3 // Get hardware thread
#define ECALL_MEANING_OF_LIFE 0x8 // Get the meaning of life