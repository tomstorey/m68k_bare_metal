# Specify the CPU type that you are targeting your build towards.
#
# Supported architectures can usually be found with the --target-help argument
# passed to gcc, but a quick summary is:
#
# 68000, 68010, 68020, 68030, 68040, 68060, cpu32 (includes 68332 and 68360),
# 68302
CPU=68000

# Uncomment either of the following depending on how you have installed gcc on
# your system. m68k-linux-gnu for Linux installations, m68k-eabi-elf if gcc was
# built from scratch e.g. on a Mac by running the build script.
# PREFIX=m68k-linux-gnu
PREFIX=m68k-eabi-elf

# Dont modify below this line (unless you know what youre doing).
CC=$(PREFIX)-gcc
AR=$(PREFIX)-ar
OBJDUMP=$(PREFIX)-objdump

CFLAGS=-m$(CPU) -Wall -g -static -I../include/ -msoft-float -MMD -MP -O3

C_SRC=$(shell find . -name '*.c')
S_SRC=$(shell find . -name '*.S')
DEP=$(C_SRC:%.c=%.d)
C_OBJ=$(C_SRC:%.c=%.o)
S_OBJ=$(S_SRC:%.S=%.o)

%.o: %.c %.S
	$(CC) $(CFLAGS) -c -o $@ $<

-include $(DEP)

all: libmetal clean

libmetal: $(C_OBJ) $(S_OBJ)
	$(AR) rcs libmetal-$(CPU).a $(C_OBJ) $(S_OBJ)

clean:
	rm -f $(DEP) $(C_OBJ) $(S_OBJ)

dumps:
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -St libmetal-$(CPU).a
