import ./base
import ./platform_defs
import ./gpio

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_pio/include".}
{.push header: "hardware/pio.h".}

type
  PioSmConfig* {.importc: "pio_sm_config", bycopy.} = object
    clkdiv* {.importc: "clkdiv".}: uint32
    execctrl* {.importc: "execctrl".}: uint32
    shiftctrl* {.importc: "shiftctrl".}: uint32
    pinctrl* {.importc: "pinctrl".}: uint32

  PioHw {.importc: "pio_hw_t", nodecl.} = object
    ctrl*: IoRw32
    fstat*: IoRo32
    fdebug*: IoRw32
    flevel*: IoRo32
    txf*: array[NUM_PIO_STATE_MACHINES, IoWo32]
    rxf*: array[NUM_PIO_STATE_MACHINES, IoRo32]
    irq*: IoRw32

  PioInstance* = ptr PioHw

  PioStateMachine* = range[0'u .. 3'u]

  PioProgram* {.importc: "pio_program_t", packed, bycopy, nodecl.} = object
    instructions* {.importc: "instructions".}: ptr uint16
    length* {.importc: "length".}: uint8
    origin* {.importc: "origin".}: int8

  PioFifoJoin* {.importc: "enum pio_fifo_join".} = enum
    JoinNone = 0
    JoinTx = 1
    JoinRx = 2

  PioMovStatusType* {.importc: "enum pio_mov_status_type".} = enum
    StatusTxLessThan = 0
    StatusRxLessThan = 1

  PioInterruptSource* {.importc: "enum pio_interrupt_source".} = enum
    ## PIO interrupt source numbers for pio related IRQs
    pisSm0RxFifoNotEmpty = 0 # PIO_INTR_SM0_RXNEMPTY_LSB
    pisSm1RxFifoNotEmpty = 1 # PIO_INTR_SM1_RXNEMPTY_LSB
    pisSm2RxFifoNotEmpty = 2 # PIO_INTR_SM2_RXNEMPTY_LSB
    pisSm3RxFifoNotEmpty = 3 # PIO_INTR_SM3_RXNEMPTY_LSB
    pisSm0TxFifoNotFull = 4  # PIO_INTR_SM0_TXNFULL_LSB
    pisSm1TxFifoNotFull = 5  # PIO_INTR_SM1_TXNFULL_LSB
    pisSm2TxFifoNotFull = 6  # PIO_INTR_SM2_TXNFULL_LSB
    pisSm3TxFifoNotFull = 7  # PIO_INTR_SM3_TXNFULL_LSB
    pisInterrupt0 = 8        # PIO_INTR_SM0_LSB
    pisInterrupt1 = 9        # PIO_INTR_SM1_LSB
    pisInterrupt2 = 10       # PIO_INTR_SM2_LSB
    pisInterrupt3 = 11       # PIO_INTR_SM3_LSB

  PioInterruptNum* = range[0'u .. 7'u]

let
  pio0* {.importc: "pio0", nodecl.}: PioInstance
  pio1* {.importc: "pio1", nodecl.}: PioInstance


# PIO State Machine Config
# Private C bindings

proc setOutPins*(c: var PioSmConfig; outBase: Gpio; outCount: cuint)
  {.importc: "sm_config_set_out_pins".}
  ## Set the 'out' pins in a state machine configuration
  ##
  ## Can overlap with the 'in', 'set' and 'sideset' pins
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param out_base 0-31 First pin to set as output
  ## \param out_count 0-32 Number of pins to set.

proc setSetPins*(c: var PioSmConfig; setBase: Gpio; setCount: cuint)
  {.importc: "sm_config_set_set_pins".}
  ## Set the 'set' pins in a state machine configuration
  ##
  ## Can overlap with the 'in', 'out' and 'sideset' pins
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param set_base 0-31 First pin to set as
  ## \param set_count 0-5 Number of pins to set.

proc setInPins*(c: var PioSmConfig; inBase: Gpio)
  {.importc: "sm_config_set_in_pins".}
  ## Set the 'in' pins in a state machine configuration
  ##
  ## Can overlap with the 'out', 'set' and 'sideset' pins
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param in_base 0-31 First pin to use as input

proc setSidesetPins*(c: var PioSmConfig; sidesetBase: Gpio)
  {.importc: "sm_config_set_sideset_pins".}
  ## Set the 'sideset' pins in a state machine configuration
  ##
  ## Can overlap with the 'in', 'out' and 'set' pins
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param sideset_base 0-31 base pin for 'side set'

proc setSideset*(c: var PioSmConfig; bitCount: cuint; optional: bool; pindirs: bool)
  {.importc: "sm_config_set_sideset".}
  ## Set the 'sideset' options in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param bit_count Number of bits to steal from delay field in the instruction for use of side set (max 5)
  ## \param optional True if the topmost side set bit is used as a flag for whether to apply side set on that instruction
  ## \param pindirs True if the side set affects pin directions rather than values

proc setClkdivIntFrac*(c: var PioSmConfig; divInt: uint16; divFrac: uint8)
  {.importc: "sm_config_set_clkdiv_int_frac".}
  ## Set the state machine clock divider (from integer and fractional parts - 16:8) in a state machine configuration
  ##
  ## The clock divider can slow the state machine's execution to some rate below
  ## the system clock frequency, by enabling the state machine on some cycles
  ## but not on others, in a regular pattern. This can be used to generate e.g.
  ## a given UART baud rate. See the datasheet for further detail.
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param div_int Integer part of the divisor
  ## \param div_frac Fractional part in 1/256ths
  ## \sa sm_config_set_clkdiv()

proc setClkdiv*(c: var PioSmConfig; divisor: cfloat)
  {.importc: "sm_config_set_clkdiv".}
  ## Set the state machine clock divider (from a floating point value) in a state machine configuration
  ##
  ## The clock divider slows the state machine's execution by masking the
  ## system clock on some cycles, in a repeating pattern, so that the state
  ## machine does not advance. Effectively this produces a slower clock for the
  ## state machine to run from, which can be used to generate e.g. a particular
  ## UART baud rate. See the datasheet for further detail.
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param div The fractional divisor to be set. 1 for full speed. An integer clock divisor of n
  ##  will cause the state machine to run 1 cycle in every n.
  ##  Note that for small n, the jitter introduced by a fractional divider (e.g. 2.5) may be unacceptable
  ##  although it will depend on the use case.

proc setWrap*(c: var PioSmConfig; wrapTarget: cuint; wrap: cuint)
  {.importc: "sm_config_set_wrap".}
  ## Set the wrap addresses in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param wrap_target the instruction memory address to wrap to
  ## \param wrap        the instruction memory address after which to set the program counter to wrap_target
  ##                    if the instruction does not itself update the program_counter

proc setJmpPin*(c: var PioSmConfig; pin: Gpio)
  {.importc: "sm_config_set_jmp_pin".}
  ## Set the 'jmp' pin in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param pin The raw GPIO pin number to use as the source for a `jmp pin` instruction

proc setInShift*(c: var PioSmConfig; shiftRight: bool; autopush: bool; pushThreshold: cuint)
  {.importc: "sm_config_set_in_shift".}
  ## Setup 'in' shifting parameters in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param shift_right true to shift ISR to right, false to shift ISR to left
  ## \param autopush whether autopush is enabled
  ## \param push_threshold threshold in bits to shift in before auto/conditional re-pushing of the ISR

proc setOutShift*(c: var PioSmConfig; shiftRight: bool; autopull: bool; pullThreshold: cuint)
  {.importc: "sm_config_set_out_shift".}
  ## Setup 'out' shifting parameters in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param shift_right true to shift OSR to right, false to shift OSR to left
  ## \param autopull whether autopull is enabled
  ## \param pull_threshold threshold in bits to shift out before auto/conditional re-pulling of the OSR

proc setFifoJoin*(c: var PioSmConfig; join: PioFifoJoin)
  {.importc: "sm_config_set_fifo_join".}
  ## Setup the FIFO joining in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param join Specifies the join type. \see enum pio_fifo_join

proc setOutSpecial*(c: var PioSmConfig; sticky: bool; hasEnablePin: bool; enablePinIndex: cuint)
  {.importc: "sm_config_set_out_special".}
  ## Set special 'out' operations in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param sticky to enable 'sticky' output (i.e. re-asserting most recent OUT/SET pin values on subsequent cycles)
  ## \param has_enable_pin true to enable auxiliary OUT enable pin
  ## \param enable_pin_index pin index for auxiliary OUT enable

proc setMovStatus*(c: var PioSmConfig; statusSel: PioMovStatusType; statusN: cuint)
  {.importc: "sm_config_set_mov_status".}
  ## Set source for 'mov status' in a state machine configuration
  ##
  ## \param c Pointer to the configuration structure to modify
  ## \param status_sel the status operation selector. \see enum pio_mov_status_type
  ## \param status_n parameter for the mov status operation (currently a bit count)

proc pioGetDefaultSmConfig*(): PioSmConfig
  {.importc: "pio_get_default_sm_config".}
  ## Get the default state machine configuration
  ##
  ## Setting | Default
  ## --------|--------
  ## Out Pins | 32 starting at 0
  ## Set Pins | 0 starting at 0
  ## In Pins (base) | 0
  ## Side Set Pins (base) | 0
  ## Side Set | disabled
  ## Wrap | wrap=31, wrap_to=0
  ## In Shift | shift_direction=right, autopush=false, push_threshold=32
  ## Out Shift | shift_direction=right, autopull=false, pull_threshold=32
  ## Jmp Pin | 0
  ## Out Special | sticky=false, has_enable_pin=false, enable_pin_index=0
  ## Mov Status | status_sel=STATUS_TX_LESSTHAN, n=0
  ##
  ## \return the default state machine configuration which can then be modified.



proc smSetConfig*(pio: PioInstance; sm: PioStateMachine; config: var PioSmConfig)
  {.importc: "pio_sm_set_config".}
  ## Apply a state machine configuration to a state machine
  ##
  ## \param pio Handle to PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param config the configuration to apply

proc getIndex*(pio: PioInstance): cuint
  {.importc: "pio_get_index".}
  ## Return the instance number of a PIO instance
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \return the PIO instance number (either 0 or 1)

proc gpioInit*(pio: PioInstance; pin: Gpio)
  {.importc: "pio_gpio_init".}
  ## Setup the function select for a GPIO to use output from the given PIO instance
  ##
  ## PIO appears as an alternate function in the GPIO muxing, just like an SPI
  ## or UART. This function configures that multiplexing to connect a given PIO
  ## instance to a GPIO. Note that this is not necessary for a state machine to
  ## be able to read the *input* value from a GPIO, but only for it to set the
  ## output value or output enable.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param pin the GPIO pin whose function select to set

proc getDreq*(pio: PioInstance; sm: PioStateMachine; isTx: bool): cuint
  {.importc: "pio_get_dreq".}
  ## Return the DREQ to use for pacing transfers to/from a particular state machine FIFO
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param is_tx true for sending data to the state machine, false for receiving data from the state machine

proc canAddProgram*(pio: PioInstance; program: ptr PioProgram): bool
  {.importc: "pio_can_add_program".}
  ## Determine whether the given program can (at the time of the call) be loaded onto the PIO instance
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param program the program definition
  ## \return true if the program can be loaded; false if there is not suitable space in the instruction memory

proc canAddProgramAtOffset*(pio: PioInstance; program: ptr PioProgram; offset: cuint): bool
  {.importc: "pio_can_add_program_at_offset".}
  ## Determine whether the given program can (at the time of the call) be loaded onto the PIO instance starting at a particular location
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param program the program definition
  ## \param offset the instruction memory offset wanted for the start of the program
  ## \return true if the program can be loaded at that location; false if there is not space in the instruction memory

proc addProgram*(pio: PioInstance; program: ptr PioProgram): cuint
  {.importc: "pio_add_program".}
  ## Attempt to load the program, panicking if not possible
  ##
  ## \see pio_can_add_program() if you need to check whether the program can be loaded
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param program the program definition
  ## \return the instruction memory offset the program is loaded at

proc addProgramAtOffset*(pio: PioInstance; program: ptr PioProgram; offset: cuint)
  {.importc: "pio_add_program_at_offset".}
  ## Attempt to load the program at the specified instruction memory offset, panicking if not possible
  ##
  ## \see pio_can_add_program_at_offset() if you need to check whether the program can be loaded
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param program the program definition
  ## \param offset the instruction memory offset wanted for the start of the program

proc removeProgram*(pio: PioInstance; program: ptr PioProgram; loadedOffset: cuint)
  {.importc: "pio_remove_program".}
  ## Remove a program from a PIO instance's instruction memory
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param program the program definition
  ## \param loaded_offset the loaded offset returned when the program was added

proc clearInstructionMemory*(pio: PioInstance)
  {.importc: "pio_clear_instruction_memory".}
  ## Clears all of a PIO instance's instruction memory
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1

proc smInit*(pio: PioInstance; sm: PioStateMachine; initialpc: cuint; config: var PioSmConfig)
  {.importc: "pio_sm_init".}
  ## Resets the state machine to a consistent state, and configures it
  ##
  ## This method:
  ## - Disables the state machine (if running)
  ## - Clears the FIFOs
  ## - Applies the configuration specified by 'config'
  ## - Resets any internal state e.g. shift counters
  ## - Jumps to the initial program location given by 'initial_pc'
  ##
  ## The state machine is left disabled on return from this call.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param initial_pc the initial program memory offset to run from
  ## \param config the configuration to apply (or NULL to apply defaults)

proc smSetEnabled*(pio: PioInstance; sm: PioStateMachine; enabled: bool)
  {.importc: "pio_sm_set_enabled".}
  ## Enable or disable a PIO state machine
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param enabled true to enable the state machine; false to disable

proc setSmMaskEnabled*(pio: PioInstance; mask: set[PioStateMachine]; enabled: bool)
  {.importc: "pio_set_sm_mask_enabled".}
  ## Enable or disable multiple PIO state machines
  ##
  ## Note that this method just sets the enabled state of the state machine;
  ## if now enabled they continue exactly from where they left off.
  ##
  ## \see pio_enable_sm_mask_in_sync() if you wish to enable multiple state machines
  ## and ensure their clock dividers are in sync.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param mask bit mask of state machine indexes to modify the enabled state of
  ## \param enabled true to enable the state machines; false to disable

proc smRestart*(pio: PioInstance; sm: PioStateMachine)
  {.importc: "pio_sm_restart".}
  ## Restart a state machine with a known state
  ##
  ## This method clears the ISR, shift counters, clock divider counter
  ## pin write flags, delay counter, latched EXEC instruction, and IRQ wait condition.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)

proc restartSmMask*(pio: PioInstance; mask: set[PioStateMachine])
  {.importc: "pio_restart_sm_mask".}
  ## Restart multiple state machine with a known state
  ##
  ## This method clears the ISR, shift counters, clock divider counter
  ## pin write flags, delay counter, latched EXEC instruction, and IRQ wait condition.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param mask bit mask of state machine indexes to modify the enabled state of

proc smClkdivRestart*(pio: PioInstance; sm: PioStateMachine)
  {.importc: "pio_sm_clkdiv_restart".}
  ## Restart a state machine's clock divider from a phase of 0
  ##
  ## Each state machine's clock divider is a free-running piece of hardware,
  ## that generates a pattern of clock enable pulses for the state machine,
  ## based *only* on the configured integer/fractional divisor. The pattern of
  ## running/halted cycles slows the state machine's execution to some
  ## controlled rate.
  ##
  ## This function clears the divider's integer and fractional phase
  ## accumulators so that it restarts this pattern from the beginning. It is
  ## called automatically by pio_sm_init() but can also be called at a later
  ## time, when you enable the state machine, to ensure precisely consistent
  ## timing each time you load and run a given PIO program.
  ##
  ## More commonly this hardware mechanism is used to synchronise the execution
  ## clocks of multiple state machines -- see pio_clkdiv_restart_sm_mask().
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)

proc clkdivRestartSmMask*(pio: PioInstance; mask: set[PioStateMachine])
  {.importc: "pio_clkdiv_restart_sm_mask".}
  ## Restart multiple state machines' clock dividers from a phase of 0.
  ##
  ## Each state machine's clock divider is a free-running piece of hardware,
  ## that generates a pattern of clock enable pulses for the state machine,
  ## based *only* on the configured integer/fractional divisor. The pattern of
  ## running/halted cycles slows the state machine's execution to some
  ## controlled rate.
  ##
  ## This function simultaneously clears the integer and fractional phase
  ## accumulators of multiple state machines' clock dividers. If these state
  ## machines all have the same integer and fractional divisors configured,
  ## their clock dividers will run in precise deterministic lockstep from this
  ## point.
  ##
  ## With their execution clocks synchronised in this way, it is then safe to
  ## e.g. have multiple state machines performing a 'wait irq' on the same flag,
  ## and all clear it on the same cycle.
  ##
  ## Also note that this function can be called whilst state machines are
  ## running (e.g. if you have just changed the clock divisors of some state
  ## machines and wish to resynchronise them), and that disabling a state
  ## machine does not halt its clock divider: that is, if multiple state
  ## machines have their clocks synchronised, you can safely disable and
  ## reenable one of the state machines without losing synchronisation.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param mask bit mask of state machine indexes to modify the enabled state of

proc enableSmMaskInSync*(pio: PioInstance; mask: set[PioStateMachine])
  {.importc: "pio_enable_sm_mask_in_sync".}
  ## Enable multiple PIO state machines synchronizing their clock dividers
  ##
  ## This is equivalent to calling both pio_set_sm_mask_enabled() and
  ## pio_clkdiv_restart_sm_mask() on the *same* clock cycle. All state machines
  ## specified by 'mask' are started simultaneously and, assuming they have the
  ## same clock divisors, their divided clocks will stay precisely synchronised.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param mask bit mask of state machine indexes to modify the enabled state of

proc setIrq0SourceEnabled*(pio: PioInstance; source: PioInterruptSource; enabled: bool)
  {.importc: "pio_set_irq0_source_enabled".}
  ## Enable/Disable a single source on a PIO's IRQ 0
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param source the source number (see \ref pio_interrupt_source)
  ## \param enabled true to enable IRQ 0 for the source, false to disable.

proc setIrq1SourceEnabled*(pio: PioInstance; source: PioInterruptSource; enabled: bool)
  {.importc: "pio_set_irq1_source_enabled".}
  ## Enable/Disable a single source on a PIO's IRQ 1
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param source the source number (see \ref pio_interrupt_source)
  ## \param enabled true to enable IRQ 1 for the source, false to disable.

proc setIrq0SourceMaskEnabled*(pio: PioInstance; sourceMask: set[PioInterruptSource]; enabled: bool)
  {.importc: "pio_set_irq0_source_mask_enabled".}
  ## Enable/Disable multiple sources on a PIO's IRQ 0
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param source_mask Mask of bits, one for each source number (see \ref pio_interrupt_source) to affect
  ## \param enabled true to enable all the sources specified in the mask on IRQ 0, false to disable all the sources specified in the mask on IRQ 0

proc setIrq1SourceMaskEnabled*(pio: PioInstance; sourceMask: set[PioInterruptSource]; enabled: bool)
  {.importc: "pio_set_irq1_source_mask_enabled".}
  ## Enable/Disable multiple sources on a PIO's IRQ 1
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param source_mask Mask of bits, one for each source number (see \ref pio_interrupt_source) to affect
  ## \param enabled true to enable all the sources specified in the mask on IRQ 1, false to disable all the sources specified in the mask on IRQ 1

proc setIrqnSourceEnabled*(pio: PioInstance; irqIndex: range[0'u .. 1'u]; source: PioInterruptSource; enabled: bool)
  {.importc: "pio_set_irqn_source_enabled".}
  ## Enable/Disable a single source on a PIO's specified (0/1) IRQ index
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param irq_index the IRQ index; either 0 or 1
  ## \param source the source number (see \ref pio_interrupt_source)
  ## \param enabled true to enable the source on the specified IRQ, false to disable.

proc setIrqnSourceMaskEnabled*(pio: PioInstance; irqIndex: range[0'u .. 1'u]; sourceMask: set[PioInterruptSource]; enabled: bool)
  {.importc: "pio_set_irqn_source_mask_enabled".}
  ## Enable/Disable multiple sources on a PIO's specified (0/1) IRQ index
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param irq_index the IRQ index; either 0 or 1
  ## \param source_mask Mask of bits, one for each source number (see \ref pio_interrupt_source) to affect
  ## \param enabled true to enable all the sources specified in the mask on the specified IRQ, false to disable all the sources specified in the mask on the specified IRQ

proc interruptGet*(pio: PioInstance; pioInterruptNum: PioInterruptNum): bool
  {.importc: "pio_interrupt_get".}
  ## Determine if a particular PIO interrupt is set
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param pio_interrupt_num the PIO interrupt number 0-7
  ## \return true if corresponding PIO interrupt is currently set

proc interruptClear*(pio: PioInstance; pioInterruptNum: PioInterruptNum)
  {.importc: "pio_interrupt_clear".}
  ## Clear a particular PIO interrupt
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param pio_interrupt_num the PIO interrupt number 0-7

proc smGetPc*(pio: PioInstance; sm: PioStateMachine): uint8
  {.importc: "pio_sm_get_pc".}
  ## Return the current program counter for a state machine
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return the program counter

proc smExec*(pio: PioInstance; sm: PioStateMachine; instr: cuint)
  {.importc: "pio_sm_exec".}
  ## Immediately execute an instruction on a state machine
  ##
  ## This instruction is executed instead of the next instruction in the normal control flow on the state machine.
  ## Subsequent calls to this method replace the previous executed
  ## instruction if it is still running. \see pio_sm_is_exec_stalled() to see if an executed instruction
  ## is still running (i.e. it is stalled on some condition)
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param instr the encoded PIO instruction

proc smIsExecStalled*(pio: PioInstance; sm: PioStateMachine): bool
  {.importc: "pio_sm_is_exec_stalled".}
  ## Determine if an instruction set by pio_sm_exec() is stalled executing
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return true if the executed instruction is still running (stalled)

proc smExecWaitBlocking*(pio: PioInstance; sm: PioStateMachine; instr: cuint)
  {.importc: "pio_sm_exec_wait_blocking".}
  ## Immediately execute an instruction on a state machine and wait for it to complete
  ##
  ## This instruction is executed instead of the next instruction in the normal control flow on the state machine.
  ## Subsequent calls to this method replace the previous executed
  ## instruction if it is still running. \see pio_sm_is_exec_stalled() to see if an executed instruction
  ## is still running (i.e. it is stalled on some condition)
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param instr the encoded PIO instruction

proc smSetWrap*(pio: PioInstance; sm: PioStateMachine; wrapTarget: cuint; wrap: cuint)
  {.importc: "pio_sm_set_wrap".}
  ## Set the current wrap configuration for a state machine
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param wrap_target the instruction memory address to wrap to
  ## \param wrap        the instruction memory address after which to set the program counter to wrap_target
  ##                    if the instruction does not itself update the program_counter

proc smSetOutPins*(pio: PioInstance; sm: PioStateMachine; outBase: cuint; outCount: cuint)
  {.importc: "pio_sm_set_out_pins".}
  ## Set the current 'out' pins for a state machine
  ##
  ## Can overlap with the 'in', 'set' and 'sideset' pins
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param out_base 0-31 First pin to set as output
  ## \param out_count 0-32 Number of pins to set.

proc smSetSetPins*(pio: PioInstance; sm: PioStateMachine; setBase: cuint; setCount: cuint)
  {.importc: "pio_sm_set_set_pins".}
  ## Set the current 'set' pins for a state machine
  ##
  ## Can overlap with the 'in', 'out' and 'sideset' pins
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param set_base 0-31 First pin to set as
  ## \param set_count 0-5 Number of pins to set.

proc smSetInPins*(pio: PioInstance; sm: PioStateMachine; inBase: cuint)
  {.importc: "pio_sm_set_in_pins".}
  ## Set the current 'in' pins for a state machine
  ##
  ## Can overlap with the 'out', 'set' and 'sideset' pins
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param in_base 0-31 First pin to use as input

proc smSetSidesetPins*(pio: PioInstance; sm: PioStateMachine; sidesetBase: cuint)
  {.importc: "pio_sm_set_sideset_pins".}
  ## Set the current 'sideset' pins for a state machine
  ##
  ## Can overlap with the 'in', 'out' and 'set' pins
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param sideset_base 0-31 base pin for 'side set'

proc smPut*(pio: PioInstance; sm: PioStateMachine; data: uint32)
  {.importc: "pio_sm_put".}
  ## Write a word of data to a state machine's TX FIFO
  ##
  ## This is a raw FIFO access that does not check for fullness. If the FIFO is
  ## full, the FIFO contents and state are not affected by the write attempt.
  ## Hardware sets the TXOVER sticky flag for this FIFO in FDEBUG, to indicate
  ## that the system attempted to write to a full FIFO.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param data the 32 bit data value
  ##
  ## \sa pio_sm_put_blocking()

proc smGet*(pio: PioInstance; sm: PioStateMachine): uint32
  {.importc: "pio_sm_get".}
  ## Read a word of data from a state machine's RX FIFO
  ##
  ## This is a raw FIFO access that does not check for emptiness. If the FIFO is
  ## empty, the hardware ignores the attempt to read from the FIFO (the FIFO
  ## remains in an empty state following the read) and the sticky RXUNDER flag
  ## for this FIFO is set in FDEBUG to indicate that the system tried to read
  ## from this FIFO when empty. The data returned by this function is undefined
  ## when the FIFO is empty.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ##
  ## \sa pio_sm_get_blocking()

proc smIsRxFifoFull*(pio: PioInstance; sm: PioStateMachine): bool
  {.importc: "pio_sm_is_rx_fifo_full".}
  ## Determine if a state machine's RX FIFO is full
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return true if the RX FIFO is full

proc smIsRxFifoEmpty*(pio: PioInstance; sm: PioStateMachine): bool
  {.importc: "pio_sm_is_rx_fifo_empty".}
  ## Determine if a state machine's RX FIFO is empty
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return true if the RX FIFO is empty

proc smGetRxFifoLevel*(pio: PioInstance; sm: PioStateMachine): cuint
  {.importc: "pio_sm_get_rx_fifo_level".}
  ## Return the number of elements currently in a state machine's RX FIFO
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return the number of elements in the RX FIFO

proc smIsTxFifoFull*(pio: PioInstance; sm: PioStateMachine): bool
  {.importc: "pio_sm_is_tx_fifo_full".}
  ## Determine if a state machine's TX FIFO is full
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return true if the TX FIFO is full

proc smIsTxFifoEmpty*(pio: PioInstance; sm: PioStateMachine): bool
  {.importc: "pio_sm_is_tx_fifo_empty".}
  ## Determine if a state machine's TX FIFO is empty
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return true if the TX FIFO is empty

proc smGetTxFifoLevel*(pio: PioInstance; sm: PioStateMachine): cuint
  {.importc: "pio_sm_get_tx_fifo_level".}
  ## Return the number of elements currently in a state machine's TX FIFO
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return the number of elements in the TX FIFO

proc smPutBlocking*(pio: PioInstance; sm: PioStateMachine; data: uint32)
  {.importc: "pio_sm_put_blocking".}
  ## Write a word of data to a state machine's TX FIFO, blocking if the FIFO is full
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param data the 32 bit data value

proc smGetBlocking*(pio: PioInstance; sm: PioStateMachine): uint32
  {.importc: "pio_sm_get_blocking".}
  ## Read a word of data from a state machine's RX FIFO, blocking if the FIFO is empty
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)

proc smDrainTxFifo*(pio: PioInstance; sm: PioStateMachine)
  {.importc: "pio_sm_drain_tx_fifo".}
  ## Empty out a state machine's TX FIFO
  ##
  ## This method executes `pull` instructions on the state machine until the TX
  ## FIFO is empty. This disturbs the contents of the OSR, so see also
  ## pio_sm_clear_fifos() which clears both FIFOs but leaves the state machine's
  ## internal state undisturbed.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ##
  ## \sa pio_sm_clear_fifos()

proc smSetClkdivIntFrac*(pio: PioInstance; sm: PioStateMachine; divInt: uint16; divFrac: uint8)
  {.importc: "pio_sm_set_clkdiv_int_frac".}
  ## Set the current clock divider for a state machine using a 16:8 fraction
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param div_int the integer part of the clock divider
  ## \param div_frac the fractional part of the clock divider in 1/256s

proc smSetClkdiv*(pio: PioInstance; sm: PioStateMachine; divisor: cfloat)
  {.importc: "pio_sm_set_clkdiv".}
  ## Set the current clock divider for a state machine
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \param div the floating point clock divider

proc smClearFifos*(pio: PioInstance; sm: PioStateMachine)
  {.importc: "pio_sm_clear_fifos".}
  ## Clear a state machine's TX and RX FIFOs
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)


# State Machine API

proc smSetPins*(pio: PioInstance; sm: PioStateMachine; pinValues: uint32)
  {.importc: "pio_sm_set_pins".}
  ## Use a state machine to set a value on all pins for the PIO instance
  ##
  ## This method repeatedly reconfigures the target state machine's pin configuration and executes 'set' instructions to set values on all 32 pins,
  ## before restoring the state machine's pin configuration to what it was.
  ##
  ## This method is provided as a convenience to set initial pin states, and should not be used against a state machine that is enabled.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3) to use
  ## \param pin_values the pin values to set

proc smSetPinsWithMask*(pio: PioInstance; sm: PioStateMachine; pinValues: uint32; pinMask: uint32)
  {.importc: "pio_sm_set_pins_with_mask".}
  ## Use a state machine to set a value on multiple pins for the PIO instance
  ##
  ## This method repeatedly reconfigures the target state machine's pin configuration and executes 'set' instructions to set values on up to 32 pins,
  ## before restoring the state machine's pin configuration to what it was.
  ##
  ## This method is provided as a convenience to set initial pin states, and should not be used against a state machine that is enabled.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3) to use
  ## \param pin_values the pin values to set (if the corresponding bit in pin_mask is set)
  ## \param pin_mask a bit for each pin to indicate whether the corresponding pin_value for that pin should be applied.

proc smSetPindirsWithMask*(pio: PioInstance; sm: PioStateMachine; pinDirs: uint32; pinMask: uint32)
  {.importc: "pio_sm_set_pindirs_with_mask".}
  ## Use a state machine to set the pin directions for multiple pins for the PIO instance
  ##
  ## This method repeatedly reconfigures the target state machine's pin configuration and executes 'set' instructions to set pin directions on up to 32 pins,
  ## before restoring the state machine's pin configuration to what it was.
  ##
  ## This method is provided as a convenience to set initial pin directions, and should not be used against a state machine that is enabled.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3) to use
  ## \param pin_dirs the pin directions to set - 1 = out, 0 = in (if the corresponding bit in pin_mask is set)
  ## \param pin_mask a bit for each pin to indicate whether the corresponding pin_value for that pin should be applied.


proc smSetConsecutivePindirs*(pio: PioInstance; sm: PioStateMachine; pinBase: cuint; pinCount: cuint; isOut: bool)
  {.importc: "pio_sm_set_consecutive_pindirs".}
  ## Use a state machine to set the same pin direction for multiple consecutive pins for the PIO instance
  ##
  ## This method repeatedly reconfigures the target state machine's pin configuration and executes 'set' instructions to set the pin direction on consecutive pins,
  ## before restoring the state machine's pin configuration to what it was.
  ##
  ## This method is provided as a convenience to set initial pin directions, and should not be used against a state machine that is enabled.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3) to use
  ## \param pin_base the first pin to set a direction for
  ## \param pin_count the count of consecutive pins to set the direction for
  ## \param is_out the direction to set; true = out, false = in

proc smClaim*(pio: PioInstance; sm: PioStateMachine)
  {.importc: "pio_sm_claim".}
  ## Mark a state machine as used
  ##
  ## Method for cooperative claiming of hardware. Will cause a panic if the state machine
  ## is already claimed. Use of this method by libraries detects accidental
  ## configurations that would fail in unpredictable ways.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)

proc claimSmMask*(pio: PioInstance; smMask: set[PioStateMachine])
  {.importc: "pio_claim_sm_mask".}
  ## Mark multiple state machines as used
  ##
  ## Method for cooperative claiming of hardware. Will cause a panic if any of the state machines
  ## are already claimed. Use of this method by libraries detects accidental
  ## configurations that would fail in unpredictable ways.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm_mask Mask of state machine indexes

proc smUnclaim*(pio: PioInstance; sm: PioStateMachine)
  {.importc: "pio_sm_unclaim".}
  ## Mark a state machine as no longer used
  ##
  ## Method for cooperative claiming of hardware.
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)

proc claimUnusedSm*(pio: PioInstance; required: bool): int
  {.importc: "pio_claim_unused_sm".}
  ## Claim a free state machine on a PIO instance
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param required if true the function will panic if none are available
  ## \return the state machine index or -1 if required was false, and none were free

proc smIsClaimed*(pio: PioInstance; sm: PioStateMachine): bool
  {.importc: "pio_sm_is_claimed".}
  ## Determine if a PIO state machine is claimed
  ##
  ## \param pio The PIO instance; either \ref pio0 or \ref pio1
  ## \param sm State machine index (0..3)
  ## \return true if claimed, false otherwise
  ## \see pio_sm_claim
  ## \see pio_claim_sm_mask

{.pop.}

# Nim helpers

# PIO State Machine Config

proc setOutPins*(c: var PioSmConfig; pins: Slice[Gpio]) =
  c.setOutPins(pins.a, pins.len.cuint)

proc setOutPin*(c: var PioSmConfig; pin: Gpio) =
  c.setOutPins(pin, 1)

proc setSetPins*(c: var PioSmConfig; pins: Slice[Gpio]) =
  c.setSetPins(pins.a, pins.len.cuint)

proc setSideset*(c: var PioSmConfig; bitCount: 1..5; optional: bool; pinDirs: bool) =
  c.setSideset(bitCount.cuint, optional, pinDirs)

proc setClkDiv*(c: var PioSmConfig; divInt: uint16; divFrac: uint8) =
  c.setClkdivIntFrac(divInt, divFrac)

template setClkDiv*(c: var PioSmConfig; divisor: static[1.0 .. 65536.0]) =
  ## Template to set floating point clock divisor when it is known at
  ## compile-time. All the float calculation is done in a  static context,
  ## so we can avoid pulling in software-float code in the final binary.
  const
    divInt = divisor.uint16
    divFrac: uint8 = ((divisor - divInt.float32) * 256).toInt.uint8
  c.setClkdivIntFrac(divInt, divFrac)

# Main PIO API

proc canAddProgram*(pio: PioInstance; program: ptr PioProgram; offset: cuint): bool =
  pio.canAddProgramAtOffset(program, offset)

proc addProgram*(pio: PioInstance; program: ptr PioProgram; offset: cuint) =
  pio.addProgramAtOffset(program, offset)

proc claimUnusedSm*(pio: PioInstance): PioStateMachine =
  pio.claimUnusedSm(true).PioStateMachine

proc setPins*(pio: PioInstance; sm: PioStateMachine; pins: set[Gpio]; value: Value) =
  let v: uint32 = if value == High: uint32.high else: 0
  pio.smSetPinsWithMask(sm, v, cast[uint32](pins))

proc setPinDirs*(pio: PioInstance; sm: PioStateMachine; pins: set[Gpio]; dir: Direction) =
  let v: uint32 = if dir == Out: uint32.high else: 0
  pio.smSetPindirsWithMask(sm, v, cast[uint32](pins))

proc setPinDirs*(pio: PioInstance; sm: PioStateMachine; pins: Slice[Gpio]; dir: Direction) =
  pio.smSetConsecutivePindirs(sm, pins.a.cuint, pins.len.cuint, dir == Out)

proc init*(pio: PioInstance; sm: PioStateMachine; initialpc: uint; config: var PioSmConfig) =
  pio.smInit(sm, initialpc.cuint, config)

proc enable*(pio: PioInstance; sm: PioStateMachine) {.inline.} =
  pio.smSetEnabled(sm, true)

proc enable*(pio: PioInstance; sm: set[PioStateMachine]) {.inline.} =
  pio.setSmMaskEnabled(sm, true)

proc disable*(pio: PioInstance; sm: PioStateMachine) {.inline.} =
  pio.smSetEnabled(sm, false)

proc disable*(pio: PioInstance; sm: set[PioStateMachine]) {.inline.} =
  pio.setSmMaskEnabled(sm, false)

proc putBlocking*(pio: PioInstance; sm: PioStateMachine; data: uint32) {.inline.} =
  pio.smPutBlocking(sm, data)


template pioInclude*(path: static[string]) =
  # experimental:
  # static:
  #   when not fileExists(cmakeBinaryDir / "pioasm" / "pioasm"):
  #     const compileCmd = "cmake --build " & quoteShell(cmakeBinaryDir) & " --target PioasmBuild"
  #     echo compileCmd
  #     doAssert gorgeEx(compileCmd).exitCode == 0
  #   const pioasmCmd = cmakeBinaryDir / "pioasm" / "pioasm" & " " & quoteShell(path) & " " & quoteShell(cmakeBinaryDir / "generated" / lastPathPart(path) & ".h")
  #   echo pioasmCmd
  #   doAssert gorgeEx(pioasmCmd).exitCode == 0
  # {.passC: "-I" & cmakeBinaryDir & "/generated ".}
  {.emit: "// picostdlib generate pio: " & path.}
