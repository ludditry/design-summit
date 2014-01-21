import os
import sys
import pprint


if __name__ == "__main__":
    if len(sys.argv) <= 1:
        print "Enter a directory to list."
        sys.exit(1)
    else:
        directory = sys.argv[1]
        pprint.pprint(list(os.walk(directory)))
