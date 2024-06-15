import machine

def load_spi_ram(filename):
    file = open(filename, "rb")
    addr = 0x20030000
    while True:
        data = file.read(1024)
        if not data:
            break
        for b in data:
            machine.mem8[addr] = b
            addr += 1
        if addr >= 0x2003fc00:
            print("Too large")
            break
        print(".", end="")
    print()
    print("Wrote %d bytes" % (addr - 0x20030000,))

    file.close()
