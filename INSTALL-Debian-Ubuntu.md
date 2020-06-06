# Installation on Ubuntu and Debian
Fortunately, Ubuntu and Debian seem to be quite similar, so the same instructions apply for both of these OSes, and are quite straight forward:

```
~$ sudo su -
[sudo] password for tom:
~# apt install git
~# apt install gcc-m68k-linux-gnu
~# apt install make
~# exit
logout
~$
```

From here, clone my repository to grab all of the files you need.

```
~$ git clone https://github.com/tomstorey/m68k_bare_metal.git
```

The repo will be cloned into a directory called `m68k_bare_metal`.

And that is all that is required for installation.
