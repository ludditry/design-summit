from mylib import math
from mylib.geom import rectangle


if __name__ == "__main__":
    x = 15
    print "sqrt(%s) is %s" % (x, math.sqrt(x))
    rect = rectangle.Rectangle(16.7, 81.1)
    print "Area of %s is %s" % (rect, rect.area())
