import sys
import pngcanvas


if __name__ == "__main__":
    output_fn = sys.argv[1]
    canvas = pngcanvas.PNGCanvas(640, 480)
    canvas.color = (255, 0, 0, 100)

    x0, y0, x1, y1 = (100, 100, 300, 200)
    canvas.filled_rectangle(x0, y0, x1, y1)
    canvas.color = (0, 255, 0, 100)
    canvas.filled_rectangle(x0 + 50, y0 + 50, x1 + 50, y1 + 50)
    canvas.color = (0, 0, 255, 100)
    canvas.filled_rectangle(x0 + 100, y0 + 100, x1 + 100, y1 + 100)

    with open(output_fn, 'w') as output_fh:
        output_fh.write(canvas.dump())
