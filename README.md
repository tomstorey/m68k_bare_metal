
# Bare Metal m68k Cross Compiler "Toolchain"
- [Bare Metal m68k Cross Compiler "Toolchain"](#bare-metal-m68k-cross-compiler--toolchain-)
  * [Motivation](#motivation)
  * [My solution](#my-solution)
  * [How To Use](#how-to-use)
    + [Get started (installation)](#get-started-installation)
    + [Build libmetal](#build-libmetal)
    + [Create a "project"](#create-a-project)
    + [Linker script](#linker-script)
    + [Write some code already...](#write-some-code-already...)
    + [Notes about floating point](#notes-about-floating-point)
  * [Additional tools](#additional-tools)
- [Advanced Topics](#advanced-topics)
  * [Default interrupt handler](#default-interrupt-handler)
  * [Exception handling routines](#exception-handling-routines)
  * [Interrupt Service Routines](#interrupt-service-routines)
- [Anything Else](#anything-else)
  * [Updates](#updates)
    + [November 2024: object filenames and `build` directory](#november-2024-object-filenames-and-build-directory)
  * [TODOs](#todos)

This repository contains my efforts to create an "idiot proof bare metal m68k cross compiler toolchain of sorts."

Please be advised that I am not a makefile or linker script expert in any way, and the fact this works at all may just be sheer luck. If you have suggestions how I can better or more properly achieve what I have, I would be very appreciative to hear from you. In the mean time, please be gentle. :-)

## Motivation
There are a lot of tools out there that can create cross compiler environments for all sorts of architectures on all sorts of architectures. If you work as a software developer, these tools might make a lot of sense, and may be the right way to go about things.

But as a lowly hobbyist that dabbles in both software and hardware and is certainly a master of neither, I find these tools quite complicated and often hard to get my head around what they are doing and how to use them. I want something simpler.

## My Solution
My solution to the problem was to create something (hopefully) so simple that ideally anyone else like me out there could understand how it is working, and also be able to modify it to suit their needs.

In my solution, I want to take some C source files (and perhaps some assembly source files, too), compile them, link them together, and produce a binary image out the other side that can be loaded directly into ROM and placed into a system and run.

To achieve this I have made a minimal linker script that allows you to position and dimension your ROM and RAM memories as required. The linker script also pulls in a reasonably vanilla flavoured `crt0` that I made, and creates the exception vector table (including reset vector).

Also included is a `Makefile` to help make building your code easier. Essentially the only thing you need to do with the Makefile is list each of the source file names that will be linked together to produce your binary (the compiler, `gcc` in my case, takes care of working out the details including dependencies for C source files).

Other than that, you just start writing code and run `make`! I think that's pretty simple.

## How To Use
There are two different "build environment flavours" that you can choose from:

 - **standalone**: this is a build that will run by itself on your system. It will include a exception vector table (EVT), and program code (crt0, your code, read only/constant data, initialised variables)
 - **application**: this is a build that might, for example, run along side a standalone build. This kind of build includes all of the above with the exception of a pared down crt0 and excludes the EVT

The idea behind these two different builds comes down to how you might build and write software for a bare metal system. For example, you may use a standalone build to implement some kind of operating system or monitor, and perhaps this allows you to load in code over a serial link and execute it. That code may be some kind of application that you want to test and debug, and which itself does not require an EVT.

### Get started (installation)
You can build or install the required tools on a variety of operating systems. Installation instructions are broken out by operating system (or group of) as each is a little different to the last, so please refer to the appropriate INSTALL-xxxx.md file in this repo.

At the time of writing, the tool chain is known to work on the following operating systems:

 - Ubuntu 18.04 and 20.04
 - Debian 9.12 and 10
 - Windows 10 and 11 with WSL
 - macOS (Intel) High Sierra (10.13), Catalina (10.15), Big Sur (11.6), Sonoma (14.7) - realistically, everything between the oldest and newest listed versions and probably a bit either side, too
 - macOS (Apple Silicon) Sequoia (15.5)

Shell scripts are provided to build a toolchain from sources on both linux and macOS.

### Build libmetal
libmetal is just a "libc like library" that I have put together including a lot of standard libc style functions. Included is a `printf` (credit: https://github.com/eyalroz/printf) and `malloc` (credit: own work, inspired by FreeRTOS).

libmetal should only need to be built once per CPU type, and is then used in all of your future projects using that CPU. If further source files or changes to source files are made within libmetal, then you will need to rebuild it for each CPU type that you intend to use.

To build libmetal, simply run `make` within the `libmetal` directory. Provided there are no blocking errors, you will be left with a file called `libmetal-xxxx.a` (where xxxx is the CPU type), and at that point you are done.

Dont forget to modify the CPU type and select your gcc prefix in the `Makefile` as required - the CPU type influences the output filename, as each copy of libmetal is built specific to that CPU.

### Create a "project"
Really this is just as simple as making a copy of either the `standalone` or `application` directory, and naming it appropriately. You'll then work on the files in this directory.

```
~$ cd m68k_bare_metal
~/m68k_bare_metal$ cp -a standalone myproject
~/m68k_bare_metal$ cd myproject
~/m68k_bare_metal/myproject$ ls -la
-rw-r--r-- 1 tom tom 1456 May 31 14:52 Makefile
-rw-r--r-- 1 tom tom 3376 May 31 14:52 crt0.S
-rw-r--r-- 1 tom tom   54 May 31 14:52 main.c
-rw-r--r-- 1 tom tom 5540 May 31 14:52 platform.ld
```

Open `Makefile` in your favourite editor and modify the CPU and PREFIX variables as required for your target and environment.

Once you have done this, the first thing to do is to assemble `crt0.S`. Take a quick look at the very beginning of this file and determine if there are any settings that you want to change for your situation, otherwise, run:

```
~/m68k_bare_metal/myproject$ make crt
```

You'll then notice a file called `crt.o`. This object file is needed by the linker, and is the first code that will execute when the system starts up. `crt0` is responsible for (in a standalone build):

* ensuring interrupts are masked by default
* setting up the stack pointer (manually, notes included)
* copying the EVT to RAM at address 0 or configuring the VBR as/if required
* copying the values of initialised variables into their appropriate memory locations
* clearing the .bss section
* calling soft and hard initialisation hooks

After all of this, it then jumps to your `main()` routine. In an application build, `crt0` only copies initialised variables into RAM, zeroises the .bss section (uninitialised variables) and jumps to `main()`.

### Linker script
The default linker script configuration places ROM at address 0 with a size of 0x100000 (1 megabyte), and RAM at 0x100000 with a size of 0x100000. Space is also reserved for the stack which is initialised to the top of RAM, and all remaining space will be allocated to the heap from which `malloc` will allocate memory.

You may need to modify these values to suit your system and application memory layout and requirements. If you do, be sure to `make clean` and rebuild your project to ensure that the new memory layout is updated in your binary. It is not necessary to rebuild crt0 if you simply modify the memory layout.

To do this, open `platform.ld` in your preferred editor, and look at the `base` and `sz` variables at the top of the file. Modify these as required.

 - `base` refers to the very first memory address of that memory type
 - `sz` refers to the number of bytes provided by that memory

The SSP (Supervisor Stack Pointer) will be initialised to the very top of memory, thus assuming that the stack grows downwards with pre-decrement. Therefore, in the default configuration, the SSP will point to 0x200000, and the first value to be pushed to the stack will be written to 0x1FFFFC (long) or 0x1FFFFE (word or byte).

The initial PC (Program Counter) value will point to the address of `_start`, which is located in `crt0.S`.

The linker script also generates an exception vector table (EVT), and this will be located through addresses 0-0x3FF (0-1023) in the ROM. Each entry in the EVT is a long (4 bytes) which points to an address where the code that handles that exception or interrupt is located. When an interrupt or execption occurrs, the processor reads the corresponding EVT entry and then jumps to the address contained within.

Both the SSP and initial PC values are stored as the very first two longs in the EVT, e.g. from addresses 0-7.

All of the documented exception vectors are pre-configured in the linker script, but if you need to add more, e.g. for your UARTs and other devices, then they can be defined manually in the linker script. See the documentation included within the linker script for an example of how to do that.

Note that while the ROM does not have to always exist from address 0, it will need to exist there initially as the m68k needs to read the SSP and initial PC values starting from address 0. If you require RAM to be located at address 0 in your system, you will need to implement circuitry or some software means to switch the ROM to a higher address. You will also then need to ensure that address range 0-0x3FF in RAM is populated with the EVT required for your system - `crt0` largely takes care of this automatically by either setting the Vector Base Register (VBR) on CPUs that have it, or copying the EVT.

These are the only changes to the linker script required, but you are free to experiment if you wish (or dare).

### Write some code already...
Ok, with all of the setup of your environment completed, you can now being to write code.

Included is a very simple `main.c`, so you can test that everything is working simply by running `make`. If all is successful, you should see a file called `bmbinary`.

```
~/m68k_bare_metal/myproject$ make
m68k-eabi-elf-gcc -m68000 -Wall -g -static -I. -msoft-float -MMD -MP -c -o build/main.c.o main.c
m68k-eabi-elf-ld -o bmbinary build/main.c.o --script=platform.ld -L../libmetal -lmetal-68000
~/m68k_bare_metal/myproject$ ls -la
-rwxrwxrwx 1 tom tom  2238 Nov 28 10:28 Makefile
-rwxrwxrwx 1 tom tom  1392 Nov 28 10:26 platform.ld
-rwxrwxrwx 1 tom tom 18532 Nov 28 10:29 bmbinary
drwxrwxrwx 1 tom tom  4096 Nov 28 10:29 build
-rwxrwxrwx 1 tom tom  1386 Feb  6  2024 crt0.S
-rwxrwxrwx 1 tom tom  1784 Nov 28 10:29 crt0.o
-rwxrwxrwx 1 tom tom    33 Feb  6  2024 main.c
```

If this works without any errors you are off to a very good start. From here you can proceed to write further code, and create additional source files. Worth noting, dependencies for .c files are automatically generated.

For each source file that you create, you will need to add it to `Makefile` in order for it to be compiled and linked. Fortunately this is a very simple process, just follow the instructions at the top of the Makefile.

During compilation, and to keep your working directory clean, all files will be built in the `build` directory, in the same directory tree as the original source files.

Once you are finished writing code and are ready to run it in your system, running `make rom` will output a file called `bmbinary.rom` which can be written to your ROMs and installed in the system.

### Notes about floating point
Most 68000 family CPUs do not include a floating point unit, and many systems do not include an external FPU either. Getting soft float to work in this toolchain has been a challenge, and I'm still not quite there yet. If you are able to help get this working, I'd love to hear from you!

Long story short, floating point may or may not work!

## Additional tools
The Makefile includes some extra rules to help with your development, these are:

 - `make dump` displays a disassembly of `bmbinary`
 - `make dumps` displays a disassembly of `bmbinary` with source code intermixed
 - `make hexdump` will produce a hex dump of `bmbinary.rom`
 - `make clean` will clear out the `build` directory, and remove the `bmbinary*` files from your project directory. `crt0.o` is maintained.

# Advanced Topics
**Note:** Most of what is written below applies only to standalone builds, as application builds do not include an EVT.

## Default interrupt handler
By default, all documented exception vectors will point to a default interrupt handling routine, which is included in `crt0.S`, called `__DefaultInterrupt`.

The default handler simply halts the CPU and masks all IRQs below IRQ7, but this is not likely to be the desired behaviour that a user may want. Therefore, the user needs to create their own service routines to handle them.

The linker script builds the EVT based on the presence or absence of each expected service routine. If a service routine is not defined, then its vector table entry points to `__DefaultInterrupt`, otherwise the entry points to the address of the routine in the ROM image.

You can of course modify or override `__DefaultInterrupt` if you desire some other default behaviour.

## Exception handling routines
If you look in `platform.ld` you will see a list of all of the exception handling routine names that are expected. These can be changed if you would prefer different names.

To ensure that your code handles each exception in the way you would prefer, simply create a routine with the name as described in the linker script. For example, if you would like to handle a divide by zero exception, you would create the following routine:

```c
void __attribute__((interrupt))
ZeroDivide(void)
{
    /* Your code here */
}
```

Exception handlers do not return a value, so they are void. They also do not take any parameters. `__attribute__((interrupt))` tells the compiler to insert the correct return instruction, `rte` instead of `rts`, when returning from an interrupt.

If you were to then run `make` and then `make dump` to view the disassembly, you would notice that the EVT has been populated with an entry that points to the ZeroDivide routine you created, for example:

```
~/m68k_bare_metal/myproject$ make dump
...
Contents of section .evt:
 0010 00000470 00000482 00000470 00000470  ...p.......p...p...
00000482 <ZeroDivide>:
 482:   4e56 0000       linkw %fp,#0
 486:   4e71            nop
 488:   4e5e            unlk %fp
 48a:   4e73            rte
 ...
```

As you can see, rather than pointing to the default interrupt handler at 0x00000470, one entry corresponding to the divide by zero exception now points to 0x00000482.

And thats basically all there is to that. Happy error handling!

## Interrupt Service Routines
To handle a vectored interrupt, you must create an ISR, and also create the appropriate vector table entry in the linker script.

To begin with, in your C file, you can create your ISR as follows:

```c
void __attribute__((interrupt))
my_interrupt_handler(void)
{
    /* Your code here */
}
```

And like exception handlers, ISRs return nothing and have no parameters, so are void. Likewise, the interrupt attribute tells the compiler to use the correct return instruction for this routine.

Now, in the linker script you will need to create an entry to be placed in the EVT. Documentation is included, but lets use another example. Say we want our interrupt vector to be 0x80, we would create our entry as follows:

 - Vector numnber 0x80
 - Multiply by 4 to get a physical address of 0x200
 - Results in origin of 0x200 within the `.evt` section

Therefore we add the following to the linker script:

```
SECTIONS {
	...
    .evt : {
	...
        . = 0x200;
        LONG(ABSOLUTE(my_interrupt_handler));
    } > evt
	...
}
```

Re-compiling our code and inspecting the disassembly we should then expect to see something like the following:

```
~/m68k_bare_metal/myproject$ make dump
...
Contents of section .evt:
 0200 0000048c                             ....
...
0000048c <my_interrupt_handler>:
 48c:   4e56 0000       linkw %fp,#0
 490:   4e71            nop
 492:   4e5e            unlk %fp
 494:   4e73            rte
	...
```

Happy interrupt vectoring!

# Anything Else
Please file an issue with me for any questions you have, I'll do my best to help.

## Updates
### November 2024: object filenames and `build` directory
As time has progressed I've found myself working on ever more complex projects. These have included mixing more assembly and C sources, and also placing files into a directory tree.

The original version of this toolchain assumed that all files would be in one root directory, and didn't account for files sharing the same name but with an extension, e.g. `driver.c` and `driver.s`. Hey, times were simpler back then, and I was still developing my toolchain knowledge. :-)

I have recently updated my toolchain to support building files in a more complex directory structure, and to also support multiple files with a similar name in one directory. Now, each file is compiled into an object file by taking its full file name and adding the `.o` extension, meaning that you can now have `driver.c` and `driver.s` compiled in the same directory, which will result in `driver.c.o` and `driver.s.o` respectively. This allows files of different types, but which are related, to share the same name.

Additionally, all object files will be compiled in to the `build` directory using the same directory structure as the original source files, which I feel helps to keep the root directory of the project much cleaner (not being littered with `.o` and `.d` files any more!)

### July 2025: macOS build scripts for Intel and ARM (Apple Silicon)
I received an Apple Silicon based Mac for work in 2025 and naturally had to try installing my toolchain on this machine. This wasn't immediately successful as there were some differences with the way `brew` installed some supporting libraries on ARM based Macs compared to Intel based Macs. Additionally, the version of clang that was included with macOS Sequoia was not able to compile some code supplied with the `binutils` and `gcc` software suites as it seems to default to a more modern C standard than that code has been written to fit. But after some head scratching and much searching I have been able to produce a build script that should now successfully build the toolchain on at least Sequoia.

Next, `libmetal` did not like building with the most recent versions of GCC, but GCC 11.2.0 as used by the Intel version of the build script would not successfully compile on Sequoia either, so GCC has been updated for the ARM build script to one which seems to be a happy middle ground.

## TODOs
 - FreeBSD build script
 - Integrate a GDB stub or similar for debugging
