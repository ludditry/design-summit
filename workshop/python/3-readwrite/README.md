This example demonstrates the ability to read and write files within ZeroVM's
in-memory file system.

In addition to the example Python script, we will also pack a sample text file
into the tar which we can read inside ZeroVM.

This example simply reads the provided input file (/romeo.txt), converts to
upper case, and writes it to another file mounted to the root of in-memory file
system (/ROMEO.txt). We notice from this that the in-memory file system is
case-sensitive.

NOTE: Once ZeroVM terminates, anything written to a file inside the instance is
discarded.

To create the example zvm image:
    $ make tar

To run:
    $ zvsh --zvm-image=readwrite.tar --zvm-image=../python.tar python readwrite.py
