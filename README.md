# Bare Metal m68k Cross Compiler "Toolchain"
- [Bare Metal m68k Cross Compiler "Toolchain"](#bare-metal-m68k-cross-compiler--toolchain-)
  * [Motivation](#motivation)
  * [My solution](#my-solution)
  * [How To Use](#how-to-use)
    + [Get started](#get-started)
    + [Create a "project"](#create-a--project-)
    + [Linker script](#linker-script)
    + [Write some code already...](#write-some-code-already)
  * [Additional tools](#additional-tools)
- [Advanced Topics](#advanced-topics)
  * [Default interrupt handler](#default-interrupt-handler)
  * [Exception handling routines](#exception-handling-routines)
  * [Interrupt Service Routines](#interrupt-service-routines)
- [Anything Else](#anything-else)
  * [TODOs](#todos)

This repository contains my efforts to create an "idiot proof bare metal m68k cross compiler toolchain of sorts."

Please be advised that I am not a makefile or linker script expert in any way, and the fact this works at all may just be sheer luck. If you have suggestions how I can better or more properly achieve what I have, I would be very appreciative to hear from you. In the mean time, please be gentle. :-)

## Motivation
There are a lot of tools out there that can create cross compiler environments for all sorts of architectures on all sorts of architectures. If you work as a software developer, these tools might make a lot of sense, and may be the right way to go about things.

But as a lowly hobbyist that dabbles in both software and hardware and is certainly a master of neither, I find these tools quite complicated and often hard to get my head around what they are doing and how to use them. I want something simpler.

## My solution
My solution to the problem was to create something (hopefully) so simple that ideally anyone else like me out there could understand how it is working, and also be able to modify it to suit their needs.

In my solution, I want to take some C source files (and perhaps some assembly source files, too), compile them, link them together, and produce a binary image out the other side that can be loaded directly into EEPROM and placed into a system and run.

To achieve this I have made a minimal linker script that allows you to position and dimension your ROM and RAM memories as required. The linker script also pulls in a reasonably vanilla flavoured `crt0` that I made.

Also included is a `Makefile` to help make building your code easier. Essentially the only thing you need to do with the Makefile is list each of the object file names that will be linked together to produce your binary (the compiler, `gcc` in my case, takes care of working out the details).

Other than that, you just start writing code and run `make`! I think that's pretty simple.

## How To Use
There are two different "build environment flavours" that you can choose from:

 - **standalone**: this is a build that will run by itself on your system. It will include a reset vector (SSP and initial PC), the interrupt/exception vector table (IVT), and program code (crt0, your code, read only/constant data, initialised variables)
 - **application**: this is a build that might, for example, run along side a standalone build. This kind of build includes only the "your code" contents as mentioned above, except with a pared down crt0 which only copies initialised variables into RAM and zeroises the `.bss` section

The idea behind these two different builds comes down to how you might build and write software for a bare metal system. For example, you may use a standalone build to implement some kind of operating system or monitor, and perhaps this allows you to load in code over a serial link and execute it. That code may be some kind of application that you want to test and debug, and which itself does not require a reset vector or IVT.

### Get started
The first thing you will need to do is install `git`, a compiler, and `make`.

    tom@ubuntu:~$ sudo su -
    [sudo] password for tom:
    root@ubuntu:~# apt install git
    root@ubuntu:~# apt install gcc-m68k-linux-gnu
    root@ubuntu:~# apt install make
    root@ubuntu:~# exit
    logout
    tom@ubuntu:~$

**Note:** I have encountered issues with binutils 2.34, I get complaints from the linker about overlapping sections, therefore I recommend something like 2.30 or 2.31 which are available with Ubuntu 18.04 and Debian 10 respectively, and I have successfully built binaries with these distributions. I also have anecdotal evidence that under Windows 10 and WSL the linking process also works just fine.

From here, clone my repository to grab all of the files you need.

    git clone https://github.com/tomstorey/m68k_bare_metal.git

Thats all you need to do to get started.

### Create a "project"
Really this is just as simple as making a copy of either the standalone or application directory, and naming it appropriately. You'll then work on the files in this directory.

    tom@ubuntu:~$ cd m68k_bare_metal
    tom@ubuntu:~/m68k_bare_metal$ cp -a standalone myproject
    tom@ubuntu:~/m68k_bare_metal$ cd myproject
    tom@ubuntu:~/m68k_bare_metal/myproject$ ls -la
    total 28
    drwxr-xr-x 2 tom tom 4096 May 31 14:52 .
    drwxr-xr-x 6 tom tom 4096 May 31 14:53 ..
    -rw-r--r-- 1 tom tom 1456 May 31 14:52 Makefile
    -rw-r--r-- 1 tom tom 3376 May 31 14:52 crt0.s
    -rw-r--r-- 1 tom tom   54 May 31 14:52 main.c
    -rw-r--r-- 1 tom tom 5540 May 31 14:52 platform.ld

Once you have done this, the first thing to do is to assemble `crt0.s`.

    tom@ubuntu:~/m68k_bare_metal/myproject$ make crt

You'll then notice a file called `crt.o` in your project directory. This object file is needed by the linker, and is the first code that will execute when the system starts up. `crt0` is responsible for (in a standalone build) testing and zeroising RAM, copying the values of initialised variables into their appropriate memory locations, calling soft and hard initialisation hooks, and then jumps to your `main()` routine. In an application build, `crt0` only copies initialised variables into RAM and zeroises the .bss section (uninitialised variables).

### Linker script
The default linker script configuration places ROM at address 0 with a size of 0x100000 (1 megabyte), and RAM at 0x100000 with a size of 0x100000. You may need to modify these values to suit your systems memory layout.

To do this, open `platform.ld` in your preferred editor, and look at the `base` and `sz` variables at the top of the file. Modify these as required.

 - `base` refers to the very first memory address of that memory type
 - `sz` refers to the number of bytes provided by that memory

The SSP (Supervisor Stack Pointer) will be initialised to the very top of memory, thus assuming that the stack grows downwards and with pre-decrement. Therefore, in the default configuration, the SSP will point to 0x200000, and the first value to be pushed to the stack will be written to 0x1FFFFC.

The initial PC (Program Counter) value will point to the address of `_start`, which is located in `crt0`.

Both the SSP and initial PC values are stored as the very first two long words in the resulting ROM, e.g. from addresses 0x0-0x7.

The linker script also generates an interrupt and exception vector table (IVT), and this will be located through addresses 0x8-0x3FF (8-1023) in the ROM. Each entry in the IVT is a long word which points to an address where the code that handles that exception or interrupt is located. When an interrupt or execption occurrs, the processor reads the corresponding IVT entry and then jumps to the address contained within.

All of the documented exception vectors are pre-configured in the linker script, but if you need to add more, e.g. for your UARTs and other devices, then they can be defined manually in the linker script. See the documentation included within for an example of how to do that.

Note that while the ROM does not have to always exist from address 0, it will need to exist there initially as the m68k needs to read the SSP and initial PC values starting from address 0. If you require RAM to be located at address 0 in your system, you will need to implement circuitry or some other means to switch the ROM to a higher address after some number of bytes are read, or after accessing a certain memory address or region. You will also then need to ensure that address range 0x8-0x3FF in RAM is populated with the IVT required for your system - this could either be copied from the ROM, or initialised through software.

These are the only changes to the linker script required, but you are free to experiment if you wish (or dare).

### Write some code already...
Ok, with all of the setup of your environment completed, you can now being to write code.

Included is a very simple `main.c`, so you can test that everything is working simply by running `make`. If all is successful, you should see a file called `bmbinary`.

    tom@ubuntu:~/m68k_bare_metal/myproject$ make
    m68k-linux-gnu-gcc -m68000 -Wall -g -static -I. -msoft-float -MMD -MP -c -o main.o main.c
    m68k-linux-gnu-ld -o bmbinary main.o --script=platform.ld
    tom@ubuntu:~/m68k_bare_metal/myproject$ ls -la
    total 52
    drwxr-xr-x 2 tom tom  4096 May 31 14:54 .
    drwxr-xr-x 6 tom tom  4096 May 31 14:53 ..
    -rw-r--r-- 1 tom tom  1456 May 31 14:52 Makefile
    -rwxrwxr-x 1 tom tom 19056 May 31 14:54 bmbinary
    -rw-rw-r-- 1 tom tom  2136 May 31 14:53 crt0.o
    -rw-r--r-- 1 tom tom  3376 May 31 14:52 crt0.s
    -rw-r--r-- 1 tom tom    54 May 31 14:52 main.c
    -rw-rw-r-- 1 tom tom    15 May 31 14:54 main.d
    -rw-rw-r-- 1 tom tom  2112 May 31 14:54 main.o
    -rw-r--r-- 1 tom tom  5540 May 31 14:52 platform.ld

If this works without any errors you are off to a very good start. From here you can proceed to write further code, and create additional source files. Worth noting, dependencies for .c files are automatically generated.

For each source file that you create, you will need to add it to `Makefile` in order for it to be compiled and linked.

Fortunately this is a very simple process, and all you need to do is add what will be the corresponding object filename to a variable at the top of the Makefile. Instructions are included to demonstrate how you should do this.

Once you are  finished writing code and are ready to run it in your system, running `make rom` will output a file called `bmbinary.rom` which can be written to your ROMs and installed in the system.

## Additional tools
The Makefile includes some extra rules to help with your development, these are:

 - `make dump` displays a disassembly of `bmbinary`
 - `make dumps` displays a disassembly of `bmbinary` with your original source lines intermixed
 - `make hexdump` will produce a hex dump of `bmbinary.rom`
 - `make clean` will remove all `.o`, `.d`, and the `bmbinary` and `bmbinary.rom` files from your project directory (except `crt0.o`)

# Advanced Topics
**Note:** Most of what is written below applies only to standalone builds, as application builds do not invlude an IVT.

## Default interrupt handler
By default, all documented exception vectors (for the 68000) will point to a default interrupt handling routine, which is included in `crt0.s`, called `__DefaultInterrupt`.

The default handler simply resets the processor, but this is not likely to be the desired behaviour that a user may want. Therefore, the user needs to create their own service routines to handle them.

The linker script builds the IVT based on the presence or absence of each expected service routine. If a service routine is not defined, then its vector table entry points to `__DefaultInterrupt`, otherwise the entry points to the memory address of the routine.

You can of course modify `__DefaultInterrupt` if you desire some other default behaviour.

## Exception handling routines
If you look in `platform.ld` you will see a list of all of the exception handling routine names that are expected. These can be changed if you would prefer different names.

To ensure that your code handles each exception in the way you would prefer, simply create a routine with the name as described in the linker script. For example, if you would like to handle a divide by zero exception, you would create the following routine:

    void __attribute__((interrupt))
    ZeroDivide(void)
    {
        /* Your code here */
    }

Exception handlers do not return a value, so they are void. They also do not take any parameters. `__attribute__((interrupt))` tells the compiler to insert the correct return instruction, `rte` instead of `rts`, when returning from an interrupt.

If you were to then run `make` and then `make dump` to view the disassembly, you would notice that the IVT has been populated with an entry that points to the ZeroDivide routine you created, for example:

    tom@ubuntu:~/m68k_bare_metal/myproject$ make dump
    ...
    Contents of section .ivt:
     0008 00000490 00000490 00000490 0000049e  ................
    ...
    0000049e <ZeroDivide>:
     49e:	4e56 0000      	linkw %fp,#0
     4a2:	4e71           	nop
     4a4:	4e5e           	unlk %fp
     4a6:	4e73           	rte
    	...

As you can see, rather than pointing to the default interrupt handler at 0x00000490, one entry corresponding to the divice by zero exception now points to 0x0000049e.

And thats basically all there is to that. Happy error handling!

## Interrupt Service Routines
To handle an interrupt, you must also create an ISR routine, and also create the appropriate vector table entry in the linker script.

To begin with, in your C file, you can create your ISR as follows:

    void __attribute__((interrupt))
    my_interrupt_handler(void)
    {
        /* Your code here */
    }

And like exception handlers, ISRs return nothing and have no parameters, so are void. Likewise, the interrupt attribute tells the compiler to use the correct return instruction for this routine.

Now, in the linker script you will need to create an entry to be placed in the IVT. Documentation is included, but lets use another example. Say we want our interrupt vector to be 0x80, we would create our entry as follows:

 - Vector numnber 0x80
 - Multiply by 4 to get a physical address of 0x200
 - Subtract 8 to cater for IVT section offset
 - Results in origin of 0x1F8 within the `.ivt` section

Therefore we add the following to the linker script:

    . = 0x1F8;
    LONG(ABSOLUTE(my_interrupt_handler));

Re-compiling our code and inspecting the disassembly we should then expect to see something like the following:

    tom@ubuntu:~/m68k_bare_metal/myproject$ make dump
    ...
     01f8 00000000 00000000 000004a8           ............
    ...
    000004a8 <my_interrupt_handler>:
     4a8:	4e56 0000      	linkw %fp,#0
     4ac:	4e71           	nop
     4ae:	4e5e           	unlk %fp
     4b0:	4e73           	rte
    	...

The first byte of the vector entry is indeed at memory address 0x200 in the resulting binary, and points to the address of the `my_interrupt_handler()` routine.

# Anything Else
Please file an issue with me for any questions you have, I'll do my best to help.

## TODOs
 - Integrate a GDB stub for debugging
