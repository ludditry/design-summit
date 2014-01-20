This example is a a program written in Python which walks the file system,
given a starting path. This example allows you to explore the in memory file
system in a very simple way.

To package the example in a tar:
    $ make tar

To run:
    $ zvsh --zvm-image=walk.tar --zvm-image=../python.tar python walk.py /
    $ zvsh --zvm-image=walk.tar --zvm-image=../python.tar python walk.py /lib/python2.7/site-packages
    $ zvsh --zvm-image=walk.tar --zvm-image=../python.tar python walk.py /share
    $ zvsh --zvm-image=walk.tar --zvm-image=../python.tar python walk.py /share/man
