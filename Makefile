# Toolchain
RV = riscv64-unknown-elf
CC = $(RV)-gcc
LD = $(RV)-ld

# Flags
CCFLAGS = -march=rv64g -mabi=lp64 -mcmodel=medany -I$(LIBDIR)
LDFLAGS = -static -nostdlib

# Sources
_SRC = mmio.S firmware.S hypervisor.S supervisor.S
LDSCRIPT = ./link.ld
TARGET = app.elf # Default target

SCRDIR = ./src
OBJDIR = ./build
LIBDIR = ./lib
OUTDIR = ./target

# Derived sources
SRC = $(_SRC:%=$(SCRDIR)/%)
_OBJ = $(patsubst %.S,%.o,$(_SRC))
OBJ = $(_OBJ:%=$(OBJDIR)/%)

.PONY: all

all: info $(TARGET)

info:
	$(info Sources: $(SRC))
	$(info Libraries: $(LIBDIR))
	$(info Linker script: $(LDSCRIPT))
	$(info Output: $(OUTDIR)/$(TARGET))
	$(info --------------------------)

# Compile sources to objects
$(OBJDIR)/%.o: $(SCRDIR)/%.S
	$(CC) -c $(CCFLAGS) -o $@ -c $<

# Link objects to target binary
%.elf: $(OBJDIR)/%.o $(OBJ)
	$(LD) $(LDFLAGS) -script $(LDSCRIPT) -o $(OUTDIR)/$@ $(OBJ)

# Remove build objects & targets
clean:
	rm -f $(OBJDIR)/*
	rm -f $(OUTDIR)/*
