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

PREFIX=m68k-linux-gnu

OBJ=main.o

# Dont modify below this line (unless you know what youre doing).

CC=$(PREFIX)-gcc
AS=$(PREFIX)-as
LD=$(PREFIX)-ld
OBJCOPY=$(PREFIX)-objcopy
OBJDUMP=$(PREFIX)-objdump

CFLAGS=-m68000 -Wall -g -static -I. -msoft-float -MMD -MP
LFLAGS=--script=platform.ld
AFLAGS=-m68000 -Wall -c -g

SRC=$(wildcard *.c)
DEP=$(SRC:%.c=%.d)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.S
	$(CC) -m68000 -c $<

%.o: %.s
	$(CC) -m68000 -c $<

bmbinary: $(OBJ)
	$(LD) -o $@ $(OBJ) $(LFLAGS)

-include $(DEP)

crt: crt0.o
	$(AS) -o crt0.o $(AFLAGS) crt0.s

clean:
	rm -f bmbinary bmbinary.rom $(OBJ) $(DEP)

rom:
	$(OBJCOPY) -O binary bmbinary bmbinary.rom

dump:
	$(OBJDUMP) -belf32-m68k -st -j.reset -j.ivt bmbinary
	$(OBJDUMP) -belf32-m68k -dt -j.text bmbinary
	$(OBJDUMP) -belf32-m68k -st -j.rodata -j.data -j.bss bmbinary

dumps:
	$(OBJDUMP) -belf32-m68k -st -j.reset -j.ivt bmbinary
	$(OBJDUMP) -belf32-m68k -St -j.text bmbinary
	$(OBJDUMP) -belf32-m68k -st -j.rodata -j.data -j.bss bmbinary

hexdump:
	hexdump -C bmbinary.rom
