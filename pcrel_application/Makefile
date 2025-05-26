# List all of the source files that will be compiled into your binary.
#
# For example, if you have the following source files
#
#   main.c
#   user.c
#   driver.s
#
# then your SRCS list would be
#
#   SRCS=main.c user.c driver.s
#
# The list may span several lines of text by appending a backslash to each line,
# for example:
#
#   SRCS=main.c user.c \
#        driver.s
SRCS=main.c

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
BUILDDIR=build

CC=$(PREFIX)-gcc
LD=$(PREFIX)-ld
OBJCOPY=$(PREFIX)-objcopy
OBJDUMP=$(PREFIX)-objdump

CFLAGS=-m$(CPU) -Wall -g -static -I../include -I. -msoft-float -MMD -MP -mpcrel -O
LFLAGS=--script=pcrel_application.ld -L../libmetal -lmetal-$(CPU)

OBJS=$(patsubst %.c,$(BUILDDIR)/%.c.o,$(SRCS))
OBJS:=$(patsubst %.S,$(BUILDDIR)/%.S.o,$(OBJS))
OBJS:=$(patsubst %.s,$(BUILDDIR)/%.s.o,$(OBJS))
DEPS=$(OBJS:.o=.d)

bmbinary: $(OBJS)
	$(LD) -o $@ $(OBJS) $(LFLAGS)

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/%.c.o: %.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.S.o: %.S
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.s.o: %.s
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

-include $(DEPS)

all: bmbinary rom

crt: crt0.S
	$(CC) $(CFLAGS) -c -o crt0.o crt0.S
	rm -f crt0.d

clean:
	rm -rf $(BUILDDIR)/*
	rm -f bmbinary*

rom:
	$(OBJCOPY) -O binary bmbinary bmbinary.rom
	$(OBJCOPY) -O srec bmbinary bmbinary.srec

dump:
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -dt -j.text bmbinary
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -st -j.rodata -j.data -j.bss bmbinary

dumps:
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -St -j.text bmbinary
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -st -j.rodata -j.data -j.bss bmbinary

hexdump:
	hexdump -C bmbinary.rom
