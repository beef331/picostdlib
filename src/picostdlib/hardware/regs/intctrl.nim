type
  InterruptNumber* {.pure, size: sizeof(cuint).} = enum
    TimerIrq0 = 0
    TimerIrq1 = 1
    TimerIrq2 = 2
    TimerIrq3 = 3
    PwmIrqWrap = 4
    UsbCtrlIrq = 5
    XipIrq = 6
    Pio0Irq0 = 7
    Pio0Irq1 = 8
    Pio1Irq0 = 9
    Pio1Irq1 = 10
    DmaIrq0 = 11
    DmaIrq1 = 12
    IoIrqBank0 = 13
    IoIrqQSpi = 14
    SIoIrqProc0 = 15
    SIoIrqProc1 = 16
    ClocksIrq = 17
    Spi0Irq = 18
    Spi1Irq = 19
    Uart0Irq = 20
    Uart1Irq = 21
    AdcIrqFifo = 22
    I2C0Irq = 23
    I2C1Irq = 24
    RtcIrq = 25
    User0Irq
    User1Irq
    User2Irq
    User3Irq
    User4Irq
    User5Irq
