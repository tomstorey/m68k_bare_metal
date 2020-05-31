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

# Dont modify below this line (unless you know what youre doing).

CC=m68k-linux-gnu-gcc
AS=m68k-linux-gnu-as
LD=m68k-linux-gnu-ld

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
	rm -f bmbinary bmbinary.bin $(OBJ) $(DEP)

rom:
	m68k-linux-gnu-objcopy -O binary bmbinary bmbinary.rom

dump:
	m68k-linux-gnu-objdump -belf32-m68k -st -j.reset -j.ivt bmbinary
	m68k-linux-gnu-objdump -belf32-m68k -dt -j.text bmbinary
	m68k-linux-gnu-objdump -belf32-m68k -st -j.rodata -j.data -j.bss bmbinary

dumps:
	m68k-linux-gnu-objdump -belf32-m68k -st -j.reset -j.ivt bmbinary
	m68k-linux-gnu-objdump -belf32-m68k -St -j.text bmbinary
	m68k-linux-gnu-objdump -belf32-m68k -st -j.rodata -j.data -j.bss bmbinary

hexdump:
	hexdump -C bmbinary.rom
