import random as rand

def main():

    rand.seed(1)

    outputfile = 'text_vram.mem'

    with open(outputfile, 'w') as file:
        for word in range(8192):
            for bit in range(16):
                file.write(str(rand.randint(0, 1)))
            file.write('\n')

if __name__ == "__main__":
    main()