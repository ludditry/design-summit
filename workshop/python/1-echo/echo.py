import sys


if __name__ == "__main__":
    if len(sys.argv) > 1:
        sys.stdout.write("stdout: ")
        sys.stderr.write("stderr: ")
        for s in sys.argv[1:]:
            sys.stdout.write("%s " % s)
            sys.stderr.write("%s " % s)
        sys.stdout.write("\n")
        sys.stderr.write("\n")
    else:
        sys.stderr.write("You must type a message to echo!\n")
