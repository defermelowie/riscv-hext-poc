# Toolchain
RV = riscv64-unknown-elf
CC = $(RV)-gcc
LD = $(RV)-ld

# Flags
CCFLAGS = -march=rv64g -mabi=lp64 -mcmodel=medany -I$(LIBDIR)
LDFLAGS = -static -nostdlib

# Sources
_SRC = firmware.S mmio.S hypervisor.S
SCRDIR = ./src
OBJDIR = ./build
LIBDIR = ./lib
LDSCRIPT = ./link.ld
TARGET = ./target/hypervisor.elf

# Derived sources
SRC = $(_SRC:%=$(SCRDIR)/%)
_OBJ = $(patsubst %.S,%.o,$(_SRC))
OBJ = $(_OBJ:%=$(OBJDIR)/%)

.PONY: all

all: $(TARGET)

info:
	$(info Sources: $(SRC))
	$(info Library directory: $(LIBDIR))
	$(info Linker script: $(LDSCRIPT))
	$(info ------------------ )
	$(info Objects: $(OBJ))
	$(info Target: $(TARGET))

# Compile sources to objects
$(OBJDIR)/%.o: $(SCRDIR)/%.S
	$(CC) -c $(CCFLAGS) -o $@ -c $<

# Link objects to target binary
$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -script $(LDSCRIPT) -o $@ $(OBJ)

# Remove build objects & targets
clean:
	rm -f $(OBJ)
	rm -f $(TARGET)
