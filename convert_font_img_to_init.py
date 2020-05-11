from PIL import Image
import sys, getopt

def main(argv):

    inputfile = ''
    outputfile = ''

    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        print('-i <inputfile> -o <outputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('-i <inputfile> -o <outputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputfile = arg

    im = Image.open(inputfile)
    px = im.load()

    with open(outputfile, 'w') as file:
        for row in range(16):
            for col in range(16):
                for row_pixel in range(16):
                    for col_pixel in range(8):
                        if (px[(col_pixel + (col * 8)), (row_pixel + (row * 16))]):
                            file.write('1')
                        else:
                            file.write('0')
                    # New row
                    file.write('\n')

if __name__ == "__main__":
    main(sys.argv[1:])