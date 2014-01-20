This example is a trivial program written in Python which exercises stdin,
stdout, and stderr by reading an input string from the user and echo it back to
both stdout and stderr.

To package the example in a tar:
    $ make tar

To run:
    $ zvsh --zvm-image=echo.tar --zvm-image=../python.tar python echo.py
    $ zvsh --zvm-image=echo.tar --zvm-image=../python.tar python echo.py some message!
