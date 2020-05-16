import random as rand

def main():

    rand.seed(1)

    outputfile = 'text_vram.mem'
    number = 0

    with open(outputfile, 'w') as file:
        for word in range(8192):
            for bit in range(16):
                file.write(str(rand.randint(0, 1)))
            # Append an increasing number
            # file.write(str(bin(number)[2:].zfill(8)))
            # number += 1
            # if number == 256:
            #     number = 0
            file.write('\n')

if __name__ == "__main__":
    main()