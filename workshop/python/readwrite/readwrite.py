if __name__ == "__main__":
    input_file = "/romeo.txt"
    output_file = "/ROMEO.txt"
    inp = open(input_file, 'r')
    out = open(output_file, 'w')

    print "Reading from %s..." % input_file
    data = inp.read()
    print "Writing to %s..." % output_file
    out.write(data.upper())
    out.close()

    print
    print "Contents of %s:" % input_file
    inp.seek(0)
    for line in inp:
        print line,
    print

    print "Contents of %s:" % output_file
    out = open(output_file, 'r')
    for line in out:
        print line,

    inp.close()
