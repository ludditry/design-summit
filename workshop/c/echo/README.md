This example is a trivial program written in C which exercises stdin, stdout,
and stderr by reading an input string from the user and echo it back to both
stdout and stderr.

To compile:
    $ make tar

To run:
    $ zvsh --zvm-image=echo.tar echo.nexe
    $ zvsh --zvm-image=echo.tar echo.nexe some message!
