This example builds off of the previous example to do something slightly more
interesting. As with the previous example, we will pack a third party library
(pngcanvas; see https://github.com/rcarmo/pngcanvas) into a ZeroVM image (tar)
and use it to do some basic image processing.

In the previous example, we saw how we can use the `zvsh` @ syntax to create
a channel to pipe a file into ZeroVM to read. You can also write to files on
the host system in this manner. To demonstrate this, this example contains
some simple code for generating PNG images.

Since these examples are intended to be run on the command line, a script has
been provided to upload your images to imgur.com to easily visualize output.
(See http://imgur.com/tools/imgurbash.sh.)

First, pack the pngcanvas library in a tar:

    $ make tar

Next, prepare a blank output file which ZeroVM can write to:

    $ make output
    or just:
    $ touch output.png  # or whatever you want to call the file

Now you can run the example. The script provided (`png.py`) simply draws
some basic geometrical shapes to a small image.

    $ zvsh --zvm-image=pngcanvas.tar --zvm-image=../python.tar python @png.py \
      @output.png

To upload and view your image in imgur.com, you can use the provided script.
After a succesful upload, the script should give you a url where you can view
the image. For example:

    $ ./imgurbash.sh output.png
    http://i.imgur.com/Ep7pZ5o.png
    Delete page: http://imgur.com/delete/nanyP5CkPQ5qfra
    Haven't copied to the clipboard: no $DISPLAY

For comparison, the expected output is provided as `expected-output.png`.
