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
#PREFIX=/mnt/c/Projects/git/m68k_bare_metal/toolchain/m68k-eabi-elf-14.3.0/bin/m68k-eabi-elf

# Dont modify below this line (unless you know what youre doing).
BUILDDIR=build

CC=$(PREFIX)-gcc
AR=$(PREFIX)-ar
OBJDUMP=$(PREFIX)-objdump

CFLAGS=-m$(CPU) -Wall -g -static -I../include/ -msoft-float -MMD -MP -O3

C_SRCS=$(shell find . -name '*.c')
S_SRCS=$(shell find . -name '*.s')
SS_SRCS=$(shell find . -name '*.S')
SRCS=$(C_SRCS) $(S_SRCS) $(SS_SRCS)
OBJS=$(patsubst %.c,$(BUILDDIR)/%.c.o,$(SRCS))
OBJS:=$(patsubst %.s,$(BUILDDIR)/%.s.o,$(OBJS))
OBJS:=$(patsubst %.S,$(BUILDDIR)/%.S.o,$(OBJS))
DEPS=$(OBJS:.o=.d)

.PHONY: all libmetal clean dumps

all: libmetal clean

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/%.c.o: %.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/%.S.o: %.S
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

-include $(DEPS)

libmetal: $(OBJS)
	$(AR) rcs libmetal-$(CPU).a $(OBJS)

clean:
	rm -rf $(BUILDDIR)/*

dumps:
	$(OBJDUMP) -mm68k:$(CPU) -belf32-m68k -St libmetal-$(CPU).a
