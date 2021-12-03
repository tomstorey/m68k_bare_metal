# List all of the object files that will be combined into your final binary
# in the OBJ variable.
#
# For example, if you have the following source files
#
#   main.c
#   user.c
#   driver.s
#
# then your OBJ list would be
#
#   main.o user.o driver.o
#
# The compiler will automatically choose the correct source file (.c, .s etc)
# according to the object file (.o) to be created.
OBJ=main.o

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
LD=$(PREFIX)-ld
OBJCOPY=$(PREFIX)-objcopy
OBJDUMP=$(PREFIX)-objdump

CFLAGS=-m$(CPU) -Wall -g -static -I../include -I. -msoft-float -MMD -MP -O
LFLAGS=--script=platform.ld -L../libmetal -lmetal-$(CPU)

SRC=$(wildcard *.c)
DEP=$(SRC:%.c=%.d)

%/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%/%.o: %.S
	$(CC) $(CFLAGS) -c $<

%/%.o: %.s
	$(CC) $(CFLAGS) -c $<

bmbinary: $(OBJ)
	$(LD) -o $@ $(OBJ) $(LFLAGS)

-include $(DEP)

all: bmbinary rom

crt:
	$(CC) $(CFLAGS) -c crt0.S

clean:
	rm -f $(OBJ) $(DEP)

rom:
	$(OBJCOPY) -O binary bmbinary bmbinary.rom
	$(OBJCOPY) -O srec bmbinary bmbinary.srec

dump:
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -st -j.evt bmbinary
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -dt -j.text bmbinary
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -st -j.rodata -j.data -j.bss -j.heap -j.stack bmbinary

dumps:
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -st -j.evt bmbinary
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -St -j.text bmbinary
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -st -j.rodata -j.data -j.bss -j.heap -j.stack bmbinary

hexdump:
	hexdump -C bmbinary.rom
