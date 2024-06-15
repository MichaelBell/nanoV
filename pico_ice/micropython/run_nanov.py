import time
import sys
import rp2
import machine
from machine import UART, Pin, PWM, SPI

@rp2.asm_pio(autopush=True, push_thresh=32, in_shiftdir=rp2.PIO.SHIFT_RIGHT)
def pio_capture():
    in_(pins, 8)

from load_spi_ram import load_spi_ram

def run(query=True, stop=True):
    machine.mem32[0x40064000] = 0xd1
    machine.freq(300_000_000)

    for i in range(4):
        Pin(i, Pin.IN, pull=None)
    for i in range(8,27):
        Pin(i, Pin.IN, pull=None)

    ice_creset_b = machine.Pin(27, machine.Pin.OUT)
    ice_creset_b.value(0)
    
    #rp2.disable_sim_spi_ram()
    #rp2.enable_sim_spi_ram()

    ice_done = machine.Pin(26, machine.Pin.IN)
    time.sleep_us(10)
    ice_creset_b.value(1)

    while ice_done.value() == 0:
        print(".", end = "")
        time.sleep(0.001)
    print()

    if query:
        input("Reset? ")

    rst_n = Pin(12, Pin.OUT)
    clk = Pin(24, Pin.OUT)

    clk.off()
    rst_n.on()
    time.sleep(0.001)
    rst_n.off()

    clk.on()
    time.sleep(0.001)
    clk.off()
    time.sleep(0.001)

    for i in range(10):
        clk.off()
        time.sleep(0.001)
        clk.on()
        time.sleep(0.001)

    rst_n.on()
    time.sleep(0.001)
    clk.off()

    capture = False
    if capture:
        sm = rp2.StateMachine(1, pio_capture, 24_000_000, in_base=Pin(0))

        capture_len=1024
        buf = bytearray(capture_len)

        rx_dma = rp2.DMA()
        c = rx_dma.pack_ctrl(inc_read=False, treq_sel=5) # Read using the SM0 RX DREQ
        sm.restart()
        sm.exec("wait(%d, gpio, %d)" % (0, 6))
        rx_dma.config(
            read=0x5020_0024,        # Read from the SM1 RX FIFO
            write=buf,
            ctrl=c,
            count=capture_len//4,
            trigger=True
        )
        sm.active(1)

    if query:
        input("Start? ")

    uart = UART(0, baudrate=93750, tx=Pin(0), rx=Pin(1), timeout=100, timeout_char=10)
    time.sleep(0.001)
    clk = PWM(Pin(24), freq=12_000_000, duty_u16=32768)

    if capture:
        # Wait for DMA to complete
        while rx_dma.active():
            time.sleep_us(100)
            
        sm.active(0)
        del sm

    if not stop:
        return

    #if query:
    #    input("Stop? ")

    if True:
        try:
            while True:
                data = uart.read(16)
                if data is not None:
                    for d in data:
                        if d > 0 and d <= 127:
                            print(chr(d), end="")
                time.sleep_us(100)
                
                if rp2.bootsel_button() != 0:
                    raise KeyboardInterrupt()

        except KeyboardInterrupt:
            pass
        finally:
            del clk
            Pin(12, Pin.IN, pull=Pin.PULL_DOWN)
            Pin(24, Pin.IN, pull=Pin.PULL_DOWN)
    else:
        del clk
        Pin(12, Pin.IN, pull=Pin.PULL_DOWN)
        Pin(24, Pin.IN, pull=Pin.PULL_DOWN)
        
    if capture:
        for j in (4, 5, 6, 7):
            print("%02d: " % (j,), end="")
            for d in buf:
                print("-" if (d & (1 << j)) != 0 else "_", end = "")
            print()

def execute(filename, stop=False):
    load_spi_ram(filename)
    rp2.enable_sim_spi_ram()
    run(query=False, stop=stop)
