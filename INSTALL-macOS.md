# Installation on macOS
The installation procedure for macOS is a bit more involved, and will require building of the `gcc` and `binutils` packages from source.

Fortunately I found a script by someone else that makes this procedure relatively painless, requiring only a couple of manual steps to be performed. Full credit to them is noted at the top of the script itself, I only had to make minor adjustments for what seem to be some minor changes in the years since that script was released.

The first step is to make sure that you have `brew` installed. Follow the installation instructions on the brew website: [https://brew.sh/](https://brew.sh/)

brew will install the command line developer tools which will include `git`, so this does not need to be installed separately. You may want to check which version has been installed, and if required, visit the git website to download an installer for a more recent version for example.

[https://git-scm.com/](https://git-scm.com/)

With these two requirements taken care of, clone the repository:

```
~ % git clone https://github.com/tomstorey/m68k_bare_metal.git
```

And then run the `macos-build-toolchain.sh` script.

```
~ % cd m68k_bare_metal
m68k_bare_metal % ./macos-build-toolchain.sh
```

**Note:** You may need to attend the installation, as I noticed on my Mac that some printer dialogs popped up... I'm not sure why, but I had to close them as they would pause the build while waiting for you to do something.

When the build has completed successfully, you can remove two temporary directories that were created (this will free up around 2GB of disk space):

```
m68k_bare_metal % rm -rf toolchain/build toolchain/sources
```

You will find that a new directory has been created, called `toolchain/m68k-eabi-elf-x.x.x` (where x.x.x is the GCC version number that has been built). Inside here are the various binaries that were built in the process above. Each toolchain is contained within its own directory, so it is possible to retain multiple different versions if the need should arise.

The only thing left to do is to modify the Makefiles to point to the binaries that have been built on your Mac. You'll want to modify the `Makefile`s within the `standalone` and `application` directories, so that any projects you create from these will incorporate the changes.

Inside each Makefile, you will find the `PREFIX` variable towards the top. This is the initial part of the filename for each of the various binaries that are called within the Makefile, e.g. the compiler, assembler, linker etc. The prefix and the remaining portion of the binary name are concatenated to form a series of variables that are the full binary name.

Modify the PREFIX variable to point to the binaries that have been compiled on your Mac, e.g.

```
PREFIX=~/m68k_bare_metal/toolchain/m68k-eabi-elf-x.x.x/bin/m68k-eabi-elf
```

You could instead modify your `PATH` environment variable instead of specifying an absolute path within the Makefiles - I leave this as an exercise for the user. :-)

And that should be it for installing on macOS!

