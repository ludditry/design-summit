This example demonstrates how to package and use a 3rd party / custom Python
package. A trivial library called `mylib` is provided for the sake of example.
Note that in the current directory, `mylib` is nested inside the directory
structure `./lib/python2.7/site-packages`. The reason for this is that Python on
ZeroVM has the following `sys.path`:

    ['/dev', '/lib/python27.zip', '/lib/python2.7',
     '/lib/python2.7/plat-linux2', '/lib/python2.7/lib-tk',
     '/lib/python2.7/lib-old', '/lib/python2.7/lib-dynload',
     '/lib/python2.7/site-packages']

So we need to mount the library files in such a place where Python can import
them. `/lib/python2.7/site-packages` is a good well-known location for placing
additional libraries. (See `Makefile` for how the library is packed into a tar
/ zvm image.)

To create the example zvm image:

    $ make tar

As with previous examples, we mount our custom tar image as well as the
standard `python.tar`. This example introduces some additional `zvsh` syntax
for creating input/output channels:

    $ zvsh --zvm-image=mylib.tar --zvm-image=../python.tar python @start.py

The `python @start.py` tells `zvsh` to do two things:

    1) Mount the `start.py` script as a file in the ZeroVM in-memory filesystem
    2) Run the script in the Python interpreter.

In earlier examples, our scripts (the entry points of our programs) were
mounted inside a tar image in order to be made available to the ZeroVM run-time
environment. The example above is good alternative if the entry point of your
program is a single file script which relies on the Python standard library and
other libraries mounted with `--zvm-image` to do most of the computation. In
other words, you don't need to wrap your script in yet another tar.
