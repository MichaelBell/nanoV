import time
from machine import UART, Pin, PWM, SPI

uart = UART(1, baudrate=19200, tx=Pin(8), rx=Pin(9), cts=Pin(10))

while True:
    data = uart.read(16)
    if data is not None:
        for d in data:
            if (d >= 32 and d <= 127) or d in (10, 13):
                print(chr(d), end="")
    time.sleep_us(100)
