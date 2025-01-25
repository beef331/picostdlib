import std/setutils
import ./irq
export setutils, irq

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/" & $picoPlatform & "/hardware_structs/include".}
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_gpio/include".}

type
  Gpio* = distinct range[0.cuint .. 47.cuint] # NUM_BANK0_GPIOS = 47 on RP2350B, 29 otherwise
    ## Gpio pins available to the RP2040. Not all pins may be available on some
    ## microcontroller boards.
  GpioOptional* = distinct range[-1 .. 47]

  Direction* {.pure, size: sizeof(bool).} = enum
    ## Gpio direction
    In, Out

  Value* {.pure, size: sizeof(bool).} = enum
    ## Gpio function value
    Low, High

  Cyw43WlGpio* = distinct range[0.cuint .. 2.cuint]
    ## Gpio pins on the Cyw43 chip

const
  GpioUnused* = -1.GpioOptional

proc `==`*(a, b: Gpio): bool {.borrow.}
proc `$`*(a: Gpio): string {.borrow.}
proc `==`*(a, b: GpioOptional): bool {.borrow.}
proc `$`*(a: GpioOptional): string {.borrow.}
proc `==`*(a, b: Cyw43WlGpio): bool {.borrow.}
proc `$`*(a: Cyw43WlGpio): string {.borrow.}

type
  GpioIrqLevel* {.pure, size: sizeof(uint32).} = enum
    ## GPIO Interrupt level definitions (GPIO events)
    ##
    ## An interrupt can be generated for every GPIO pin in 4 scenarios:
    ##
    ## * Level Low: the GPIO pin is a logical 0
    ## * Level High: the GPIO pin is a logical 1
    ## * Edge Fall: the GPIO has transitioned from a logical 1 to a logical 0
    ## * Edge Rise: the GPIO has transitioned from a logical 0 to a logical 1
    ##
    ## The level interrupts are not latched. This means that if the pin is a logical 1 and the level high interrupt is active, it will
    ## become inactive as soon as the pin changes to a logical 0. The edge interrupts are stored in the INTR register and can be
    ## cleared by writing to the INTR register.
    LevelLow
    LevelHigh
    EdgeFall
    EdgeRise

{.push header: "hardware/gpio.h".}

type
  GpioFunction* {.pure, importc: "gpio_function_t", size: sizeof(byte).} = enum
    ## GPIO function definitions for use with function select.
    ## Each GPIO can have one function selected at a time. Likewise,
    ## each peripheral input (e.g. UART0 RX) should only be selected on one
    ## GPIO at a time. If the same peripheral input is connected to multiple
    ## GPIOs, the peripheral sees the logical OR of these GPIO inputs.
    Xip, Spi, Uart, I2c, Pwm, Sio, Pio0, Pio1, Gpck, Usb,
    Null = 0x1F

  GpioIrqCallback* {.importc: "gpio_irq_callback_t".} = proc (gpio: Gpio; eventMask: uint32) {.cdecl.}

  GpioOverride* {.pure, importc: "gpio_override".} = enum
    OverrideNormal # peripheral signal selected via \ref gpio_set_function
    OverrideInvert # invert peripheral signal selected via \ref gpio_set_function
    OverrideLow    # drive low/disable output
    OverrideHigh   # drive high/enable output

  GpioSlewRate* {.pure, importc: "enum gpio_slew_rate", size: sizeof(byte).} = enum
    ## Slew rate limiting levels for GPIO outputs
    ##
    ## Slew rate limiting increases the minimum rise/fall time when a GPIO output
    ## is lightly loaded, which can help to reduce electromagnetic emissions.
    ## \sa gpio_set_slew_rate
    SlewRateSlow # Slew rate limiting enabled
    SlewRateFast # Slew rate limiting disabled

  GpioDriveStrength* {.pure, importc: "enum gpio_drive_strength", size: sizeof(byte).} = enum
    DriveStrength2mA  # 2 mA nominal drive strength
    DriveStrength4mA  # 4 mA nominal drive strength
    DriveStrength8mA  # 2 mA nominal drive strength
    DriveStrength12mA # 12 mA nominal drive strength


proc setFunction*(gpio: Gpio; fn: GpioFunction) {.importc: "gpio_set_function".}
  ## Select GPIO function
  ##
  ## \param gpio GPIO number
  ## \param fn Which GPIO function select to use from list \ref gpio_function_t

proc setFunction*(gpioMask: set[Gpio]; fn: GpioFunction)  {.importc: "gpio_set_function_masked".}
  ## Select the function for multiple GPIOs
  ##
  ## \sa gpio_set_function
  ## \param gpio_mask Mask with 1 bit per GPIO number to set the function for
  ## \param fn Which GPIO function select to use from list \ref gpio_function_t

proc setFunction64*(gpioMask: set[Gpio]; fn: GpioFunction)  {.importc: "gpio_set_function_masked64".}

proc getFunction*(gpio: Gpio): GpioFunction {.importc: "gpio_get_function".}
  ## Determine current GPIO function
  ##
  ## \param gpio GPIO number
  ## \return Which GPIO function is currently selected from list \ref gpio_function_t

proc setPulls*(gpio: Gpio; up: bool; down: bool) {.importc: "gpio_set_pulls".}
  ## Select up and down pulls on specific GPIO
  ##
  ## \param gpio GPIO number
  ## \param up If true set a pull up on the GPIO
  ## \param down If true set a pull down on the GPIO
  ##
  ## \note On the RP2040, setting both pulls enables a "bus keep" function,
  ## i.e. a weak pull to whatever is current high/low state of GPIO.

proc pullUp*(gpio: Gpio) {.importc: "gpio_pull_up".}
  ## Set specified GPIO to be pulled up.
  ##
  ## \param gpio GPIO number

proc isPulledUp*(gpio: Gpio): bool {.importc: "gpio_is_pulled_up".}
  ## Determine if the specified GPIO is pulled up.
  ##
  ## \param gpio GPIO number
  ## \return true if the GPIO is pulled up

proc pullDown*(gpio: Gpio) {.importc: "gpio_pull_down".}
  ## Set specified GPIO to be pulled down.
  ##
  ## \param gpio GPIO number

proc isPulledDown*(gpio: Gpio): bool {.importc: "gpio_is_pulled_down".}
  ## Determine if the specified GPIO is pulled down.
  ##
  ## \param gpio GPIO number
  ## \return true if the GPIO is pulled down

proc disablePulls*(gpio: Gpio) {.importc: "gpio_disable_pulls".}
  ## Disable pulls on specified GPIO
  ##
  ## \param gpio GPIO number

proc setIrqover*(gpio: Gpio; value: GpioOverride) {.importc: "gpio_set_irqover".}
  ## Set GPIO IRQ override
  ##
  ## Optionally invert a GPIO IRQ signal, or drive it high or low
  ##
  ## \param gpio GPIO number
  ## \param value See \ref gpio_override

proc setOutover*(gpio: Gpio; value: GpioOverride) {.importc: "gpio_set_outover".}
  ## Set GPIO output override
  ##
  ## \param gpio GPIO number
  ## \param value See \ref gpio_override

proc setInover*(gpio: Gpio; value: GpioOverride) {.importc: "gpio_set_inover".}
  ## Select GPIO input override
  ##
  ## \param gpio GPIO number
  ## \param value See \ref gpio_override

proc setOeover*(gpio: Gpio; value: GpioOverride) {.importc: "gpio_set_oeover".}
  ## Select GPIO output enable override
  ##
  ## \param gpio GPIO number
  ## \param value See \ref gpio_override

proc setInputEnabled*(gpio: Gpio; enabled: bool) {.importc: "gpio_set_input_enabled".}
  ## Enable GPIO input
  ##
  ## \param gpio GPIO number
  ## \param enabled true to enable input on specified GPIO

proc setInputHysteresisEnabled*(gpio: Gpio; enabled: bool) {.importc: "gpio_set_input_hysteresis_enabled".}
  ## Enable/disable GPIO input hysteresis (Schmitt trigger)
  ##
  ## Enable or disable the Schmitt trigger hysteresis on a given GPIO. This is
  ## enabled on all GPIOs by default. Disabling input hysteresis can lead to
  ## inconsistent readings when the input signal has very long rise or fall
  ## times, but slightly reduces the GPIO's input delay.
  ##
  ## \sa gpio_is_input_hysteresis_enabled
  ## \param gpio GPIO number
  ## \param enabled true to enable input hysteresis on specified GPIO

proc isInputHysteresisEnabled*(gpio: Gpio): bool {.importc: "gpio_is_input_hysteresis_enabled".}
  ## Determine whether input hysteresis is enabled on a specified GPIO
  ##
  ## \sa gpio_set_input_hysteresis_enabled
  ## \param gpio GPIO number

proc setSlewRate*(gpio: Gpio; slew: GpioSlewRate) {.importc: "gpio_set_slew_rate".}
  ## Set slew rate for a specified GPIO
  ##
  ## \sa gpio_get_slew_rate
  ## \param gpio GPIO number
  ## \param slew GPIO output slew rate

proc getSlewRate*(gpio: Gpio): GpioSlewRate {.importc: "gpio_get_slew_rate".}
  ## Determine current slew rate for a specified GPIO
  ##
  ## \sa gpio_set_slew_rate
  ## \param gpio GPIO number
  ## \return Current slew rate of that GPIO

proc setDriveStrength*(gpio: Gpio; drive: GpioDriveStrength) {.importc: "gpio_set_drive_strength".}
  ## Set drive strength for a specified GPIO
  ##
  ## \sa gpio_get_drive_strength
  ## \param gpio GPIO number
  ## \param drive GPIO output drive strength

proc getDriveStrength*(gpio: Gpio): GpioDriveStrength {.importc: "gpio_get_drive_strength".}
  ## Determine current drive strength for a specified GPIO
  ##
  ## \sa gpio_set_drive_strength
  ## \param gpio GPIO number
  ## \return Current drive strength of that GPIO

proc setIrqEnabled*(gpio: Gpio; eventMask: set[GpioIrqLevel]; enabled: bool) {.importc: "gpio_set_irq_enabled".}
  ## Enable or disable specific interrupt events for specified GPIO
  ##
  ## This function sets which GPIO events cause a GPIO interrupt on the calling core. See
  ## \ref gpio_set_irq_callback, \ref gpio_set_irq_enabled_with_callback and
  ## \ref gpio_add_raw_irq_handler to set up a GPIO interrupt handler to handle the events.
  ##
  ## \note The IO IRQs are independent per-processor. This configures the interrupt events for
  ## the processor that calls the function.
  ##
  ## \param gpio GPIO number
  ## \param event_mask Which events will cause an interrupt
  ## \param enabled Enable or disable flag
  ##
  ## Events is a bitmask of the following \ref gpio_irq_level values:
  ##
  ## bit | constant            | interrupt
  ## ----|---------------------|------------------------------------
  ##   0 | GPIO_IRQ_LEVEL_LOW  | Continuously while level is low
  ##   1 | GPIO_IRQ_LEVEL_HIGH | Continuously while level is high
  ##   2 | GPIO_IRQ_EDGE_FALL  | On each transition from high to low
  ##   3 | GPIO_IRQ_EDGE_RISE  | On each transition from low to high
  ##
  ## which are specified in \ref gpio_irq_level

proc gpioSetIrqCallback*(callback: GpioIrqCallback) {.importc: "gpio_set_irq_callback".}
  ## Set the generic callback used for GPIO IRQ events for the current core
  ##
  ## This function sets the callback used for all GPIO IRQs on the current core that are not explicitly
  ## hooked via \ref gpio_add_raw_irq_handler or other gpio_add_raw_irq_handler_ functions.
  ##
  ## This function is called with the GPIO number and event mask for each of the (not explicitly hooked)
  ## GPIOs that have events enabled and that are pending (see \ref gpio_get_irq_event_mask).
  ##
  ## \note The IO IRQs are independent per-processor. This function affects
  ## the processor that calls the function.
  ##
  ## \param callback default user function to call on GPIO irq. Note only one of these can be set per processor.

proc setIrqEnabledWithCallback*(gpio: Gpio; eventMask: set[GpioIrqLevel]; enabled: bool; callback: GpioIrqCallback) {.importc: "gpio_set_irq_enabled_with_callback".}
  ## Convenience function which performs multiple GPIO IRQ related initializations
  ##
  ## This method is a slightly eclectic mix of initialization, that:
  ##
  ## \li Updates whether the specified events for the specified GPIO causes an interrupt on the calling core based
  ## on the enable flag.
  ##
  ## \li Sets the callback handler for the calling core to callback (or clears the handler if the callback is NULL).
  ##
  ## \li Enables GPIO IRQs on the current core if enabled is true.
  ##
  ## This method is commonly used to perform a one time setup, and following that any additional IRQs/events are enabled
  ## via \ref gpio_set_irq_enabled. All GPIOs/events added in this way on the same core share the same callback; for multiple
  ## independent handlers for different GPIOs you should use \ref gpio_add_raw_irq_handler and related functions.
  ##
  ## This method is equivalent to:
  ##
  ## \code{.c}
  ## gpio_set_irq_enabled(gpio, event_mask, enabled);
  ## gpio_set_irq_callback(callback);
  ## if (enabled) irq_set_enabled(IO_IRQ_BANK0, true);
  ## \endcode
  ##
  ## \note The IO IRQs are independent per-processor. This method affects only the processor that calls the function.
  ##
  ## \param gpio GPIO number
  ## \param event_mask Which events will cause an interrupt. See \ref gpio_irq_level for details.
  ## \param enabled Enable or disable flag
  ## \param callback user function to call on GPIO irq. if NULL, the callback is removed

proc setDormantIrqEnabled*(gpio: Gpio; eventMask: set[GpioIrqLevel]; enabled: bool) {.importc: "gpio_set_dormant_irq_enabled".}
  ## Enable dormant wake up interrupt for specified GPIO and events
  ##
  ## This configures IRQs to restart the XOSC or ROSC when they are
  ## disabled in dormant mode
  ##
  ## \param gpio GPIO number
  ## \param event_mask Which events will cause an interrupt. See \ref gpio_irq_level for details.
  ## \param enabled Enable/disable flag

proc getIrqEventMask*(gpio: Gpio): set[GpioIrqLevel] {.importc: "gpio_get_irq_event_mask".}
  ## Return the current interrupt status (pending events) for the given GPIO
  ##
  ## \param gpio GPIO number
  ## \return Bitmask of events that are currently pending for the GPIO. See \ref gpio_irq_level for details.
  ## \sa gpio_acknowledge_irq

proc acknowledgeIrq*(gpio: Gpio; eventMask: set[GpioIrqLevel]) {.importc: "gpio_acknowledge_irq".}
  ## Acknowledge a GPIO interrupt for the specified events on the calling core
  ##
  ## \note This may be called with a mask of any of valid bits specified in \ref gpio_irq_level, however
  ## it has no effect on \a level sensitive interrupts which remain pending while the GPIO is at the specified
  ## level. When handling \a level sensitive interrupts, you should generally disable the interrupt (see
  ## \ref gpio_set_irq_enabled) and then set it up again later once the GPIO level has changed (or to catch
  ## the opposite level).
  ##
  ## \param gpio GPIO number
  ## \param events Bitmask of events to clear. See \ref gpio_set_irq_enabled for details.
  ##
  ## \note For callbacks set with \ref gpio_set_irq_enabled_with_callback, or \ref gpio_set_irq_callback, this function is called automatically.
  ## \param event_mask Bitmask of events to clear. See \ref gpio_irq_level for details.

proc addRawIrqHandlerWithOrderPriority*(gpioMask: set[Gpio]; handler: IrqHandler; orderPriority: uint8) {.importc: "gpio_add_raw_irq_handler_with_order_priority_masked".}
  ## Adds a raw GPIO IRQ handler for the specified GPIOs on the current core
  ##
  ## In addition to the default mechanism of a single GPIO IRQ event callback per core (see \ref gpio_set_irq_callback),
  ## it is possible to add explicit GPIO IRQ handlers which are called independent of the default callback. The order
  ## relative to the default callback can be controlled via the order_priority parameter (the default callback has the priority
  ## \ref GPIO_IRQ_CALLBACK_ORDER_PRIORITY which defaults to the lowest priority with the intention of it running last).
  ##
  ## This method adds such an explicit GPIO IRQ handler, and disables the "default" callback for the specified GPIOs.
  ##
  ## \note Multiple raw handlers should not be added for the same GPIOs, and this method will assert if you attempt to.
  ## Internally, this function calls \ref irq_add_shared_handler, which will assert if the maximum number of shared handlers
  ## (configurable via PICO_MAX_IRQ_SHARED_HANDLERS) would be exceeded.
  ##
  ## A raw handler should check for whichever GPIOs and events it handles, and acknowledge them itself; it might look something like:
  ##
  ## \code{.c}
  ## void my_irq_handler(void) {
  ##     if (gpio_get_irq_event_mask(my_gpio_num) & my_gpio_event_mask) {
  ##        gpio_acknowledge_irq(my_gpio_num, my_gpio_event_mask);
  ##        handle the IRQ
  ##     }
  ##     if (gpio_get_irq_event_mask(my_gpio_num2) & my_gpio_event_mask2) {
  ##        gpio_acknowledge_irq(my_gpio_num2, my_gpio_event_mask2);
  ##        handle the IRQ
  ##     }
  ## }
  ## \endcode
  ##
  ## @param gpio_mask a bit mask of the GPIO numbers that will no longer be passed to the default callback for this core
  ## @param handler the handler to add to the list of GPIO IRQ handlers for this core
  ## @param order_priority the priority order to determine the relative position of the handler in the list of GPIO IRQ handlers for this core.

proc addRawIrqHandlerWithOrderPriority64*(gpioMask: set[Gpio]; handler: IrqHandler; orderPriority: uint8) {.importc: "gpio_add_raw_irq_handler_with_order_priority_masked64".}

proc addRawIrqHandlerWithOrderPriority*(gpio: Gpio; handler: IrqHandler; orderPriority: uint8) {.importc: "gpio_add_raw_irq_handler_with_order_priority".}
  ## Adds a raw GPIO IRQ handler for a specific GPIO on the current core
  ##
  ## In addition to the default mechanism of a single GPIO IRQ event callback per core (see \ref gpio_set_irq_callback),
  ## it is possible to add explicit GPIO IRQ handlers which are called independent of the default callback. The order
  ## relative to the default callback can be controlled via the order_priority parameter(the default callback has the priority
  ## \ref GPIO_IRQ_CALLBACK_ORDER_PRIORITY which defaults to the lowest priority with the intention of it running last).
  ##
  ## This method adds such a callback, and disables the "default" callback for the specified GPIO.
  ##
  ## \note Multiple raw handlers should not be added for the same GPIO, and this method will assert if you attempt to.
  ## Internally, this function calls \ref irq_add_shared_handler, which will assert if the maximum number of shared handlers
  ## (configurable via PICO_MAX_IRQ_SHARED_HANDLERS) would be exceeded.
  ##
  ## A raw handler should check for whichever GPIOs and events it handles, and acknowledge them itself; it might look something like:
  ##
  ## \code{.c}
  ## void my_irq_handler(void) {
  ##     if (gpio_get_irq_event_mask(my_gpio_num) & my_gpio_event_mask) {
  ##        gpio_acknowledge_irq(my_gpio_num, my_gpio_event_mask);
  ##        handle the IRQ
  ##     }
  ## }
  ## \endcode
  ##
  ## @param gpio the GPIO number that will no longer be passed to the default callback for this core
  ## @param handler the handler to add to the list of GPIO IRQ handlers for this core
  ## @param order_priority the priority order to determine the relative position of the handler in the list of GPIO IRQ handlers for this core.

proc addRawIrqHandler*(gpioMask: set[Gpio]; handler: IrqHandler) {.importc: "gpio_add_raw_irq_handler_masked".}
  ## Adds a raw GPIO IRQ handler for the specified GPIOs on the current core
  ##
  ## In addition to the default mechanism of a single GPIO IRQ event callback per core (see \ref gpio_set_irq_callback),
  ## it is possible to add explicit GPIO IRQ handlers which are called independent of the default event callback.
  ##
  ## This method adds such a callback, and disables the "default" callback for the specified GPIOs.
  ##
  ## \note Multiple raw handlers should not be added for the same GPIOs, and this method will assert if you attempt to.
  ##
  ## A raw handler should check for whichever GPIOs and events it handles, and acknowledge them itself; it might look something like:
  ##
  ## \code{.c}
  ## void my_irq_handler(void) {
  ##     if (gpio_get_irq_event_mask(my_gpio_num) & my_gpio_event_mask) {
  ##        gpio_acknowledge_irq(my_gpio_num, my_gpio_event_mask);
  ##        handle the IRQ
  ##     }
  ##     if (gpio_get_irq_event_mask(my_gpio_num2) & my_gpio_event_mask2) {
  ##        gpio_acknowledge_irq(my_gpio_num2, my_gpio_event_mask2);
  ##        handle the IRQ
  ##     }
  ## }
  ## \endcode
  ##
  ## @param gpio_mask a bit mask of the GPIO numbers that will no longer be passed to the default callback for this core
  ## @param handler the handler to add to the list of GPIO IRQ handlers for this core

proc addRawIrqHandler64*(gpioMask: set[Gpio]; handler: IrqHandler) {.importc: "gpio_add_raw_irq_handler_masked64".}

proc addRawIrqHandler*(gpio: Gpio; handler: IrqHandler) {.importc: "gpio_add_raw_irq_handler".}
  ## Adds a raw GPIO IRQ handler for a specific GPIO on the current core
  ##
  ## In addition to the default mechanism of a single GPIO IRQ event callback per core (see \ref gpio_set_irq_callback),
  ## it is possible to add explicit GPIO IRQ handlers which are called independent of the default event callback.
  ##
  ## This method adds such a callback, and disables the "default" callback for the specified GPIO.
  ##
  ## \note Multiple raw handlers should not be added for the same GPIO, and this method will assert if you attempt to.
  ## Internally, this function calls \ref irq_add_shared_handler, which will assert if the maximum number of shared handlers
  ## (configurable via PICO_MAX_IRQ_SHARED_HANDLERS) would be exceeded.
  ##
  ## A raw handler should check for whichever GPIOs and events it handles, and acknowledge them itself; it might look something like:
  ##
  ## \code{.c}
  ## void my_irq_handler(void) {
  ##     if (gpio_get_irq_event_mask(my_gpio_num) & my_gpio_event_mask) {
  ##        gpio_acknowledge_irq(my_gpio_num, my_gpio_event_mask);
  ##        handle the IRQ
  ##     }
  ## }
  ## \endcode
  ##
  ## @param gpio the GPIO number that will no longer be passed to the default callback for this core
  ## @param handler the handler to add to the list of GPIO IRQ handlers for this core

proc removeRawIrqHandler*(gpioMask: set[Gpio]; handler: IrqHandler) {.importc: "gpio_remove_raw_irq_handler_masked".}
  ## Removes a raw GPIO IRQ handler for the specified GPIOs on the current core
  ##
  ## In addition to the default mechanism of a single GPIO IRQ event callback per core (see \ref gpio_set_irq_callback),
  ## it is possible to add explicit GPIO IRQ handlers which are called independent of the default event callback.
  ##
  ## This method removes such a callback, and enables the "default" callback for the specified GPIOs.
  ##
  ## @param gpio_mask a bit mask of the GPIO numbers that will now be passed to the default callback for this core
  ## @param handler the handler to remove from the list of GPIO IRQ handlers for this core

proc removeRawIrqHandler64*(gpioMask: set[Gpio]; handler: IrqHandler) {.importc: "gpio_remove_raw_irq_handler_masked64".}

proc removeRawIrqHandler*(gpio: Gpio; handler: IrqHandler) {.importc: "gpio_remove_raw_irq_handler".}
  ## Removes a raw GPIO IRQ handler for the specified GPIO on the current core
  ##
  ## In addition to the default mechanism of a single GPIO IRQ event callback per core (see \ref gpio_set_irq_callback),
  ## it is possible to add explicit GPIO IRQ handlers which are called independent of the default event callback.
  ##
  ## This method removes such a callback, and enables the "default" callback for the specified GPIO.
  ##
  ## @param gpio the GPIO number that will now be passed to the default callback for this core
  ## @param handler the handler to remove from the list of GPIO IRQ handlers for this core

proc init*(gpio: Gpio) {.importc: "gpio_init".}
  ## Initialise a GPIO for (enabled I/O and set func to GPIO_FUNC_SIO)
  ##
  ## Clear the output enable (i.e. set to input).
  ## Clear any output value.
  ##
  ## \param gpio GPIO number

proc deinit*(gpio: Gpio) {.importc: "gpio_deinit".}
  ## Resets a GPIO back to the NULL function, i.e. disables it.
  ##
  ## \param gpio GPIO number

proc init*(gpioMask: set[Gpio]) {.importc: "gpio_init_mask".}
  ## Initialise multiple GPIOs (enabled I/O and set func to GPIO_FUNC_SIO)
  ##
  ## Clear the output enable (i.e. set to input).
  ## Clear any output value.
  ##
  ## \param gpio_mask Mask with 1 bit per GPIO number to initialize

proc get*(gpio: Gpio): Value {.importc: "gpio_get".}
  ## Get state of a single specified Gpio.
  ##
  ## **Returns:** Current state of the Gpio. Low (0.Value) or High (1.Value)

proc gpioGetAll*(): set[Gpio] {.importc: "gpio_get_all".}
  ## Get raw value of all GPIOs
  ##
  ## \return Bitmask of raw GPIO values

proc gpioGetAll64*(): set[Gpio] {.importc: "gpio_get_all64".}

proc set*(gpioMask: set[Gpio]) {.importc: "gpio_set_mask".}
  ## Drive high every GPIO appearing in mask
  ##
  ## \param mask Bitmask of GPIO values to set

proc set64*(gpioMask: set[Gpio]) {.importc: "gpio_set_mask64".}

proc clear*(gpioMask: set[Gpio]) {.importc: "gpio_clr_mask".}
  ## Drive low every GPIO appearing in mask
  ##
  ## \param mask Bitmask of GPIO values to clear

proc clear64*(gpioMask: set[Gpio]) {.importc: "gpio_clr_mask64".}

proc toggle*(gpioMask: set[Gpio]) {.importc: "gpio_xor_mask".}
  ## Toggle every GPIO appearing in mask
  ##
  ## \param mask Bitmask of GPIO values to toggle

proc toggle64*(gpioMask: set[Gpio]) {.importc: "gpio_xor_mask64".}

proc putMasked*(gpioMask: set[Gpio]; value: set[Gpio]) {.importc: "gpio_put_masked".}
  ## Drive GPIO high/low depending on parameters
  ##
  ## \param mask Bitmask of GPIO values to change
  ## \param value Value to set
  ##
  ## For each 1 bit in \p mask, drive that pin to the value given by
  ## corresponding bit in \p value, leaving other pins unchanged.
  ## Since this uses the TOGL alias, it is concurrency-safe with e.g. an IRQ
  ## bashing different pins from the same core.

proc putMasked64*(gpioMask: set[Gpio]; value: set[Gpio]) {.importc: "gpio_put_masked64".}

proc putAll*(value: set[Gpio]) {.importc: "gpio_put_all".}
  ## Drive all pins simultaneously
  ##
  ## \param value Bitmask of GPIO values to change

proc putAll64*(value: set[Gpio]) {.importc: "gpio_put_all64".}

proc put*(gpio: Gpio; value: Value) {.importc: "gpio_put".}
  ## Drive a single GPIO high/low
  ##
  ## \param gpio GPIO number
  ## \param value If false clear the GPIO, otherwise set it.

proc getOutLevel*(gpio: Gpio): bool {.importc: "gpio_get_out_level".}
  ## Determine whether a GPIO is currently driven high or low
  ##
  ## This function returns the high/low output level most recently assigned to a
  ## GPIO via gpio_put() or similar. This is the value that is presented outward
  ## to the IO muxing,not* the input level back from the pad (which can be
  ## read using gpio_get()).
  ##
  ## To avoid races, this function must not be used for read-modify-write
  ## sequences when driving GPIOs -- instead functions like gpio_put() should be
  ## used to atomically update GPIOs. This accessor is intended for debug use
  ## only.
  ##
  ## \param gpio GPIO number
  ## \return true if the GPIO output level is high, false if low.

proc setDirOut*(gpioMask: set[Gpio]) {.importc: "gpio_set_dir_out_masked".}
  ## Set a number of GPIOs to output
  ##
  ## Switch all GPIOs in "mask" to output
  ##
  ## \param mask Bitmask of GPIO to set to output

proc setDirOut64*(gpioMask: set[Gpio]) {.importc: "gpio_set_dir_out_masked64".}

proc setDirIn*(gpioMask: set[Gpio]) {.importc: "gpio_set_dir_in_masked".}
  ## Set a number of GPIOs to input
  ##
  ## \param mask Bitmask of GPIO to set to input

proc setDirIn64*(gpioMask: set[Gpio]) {.importc: "gpio_set_dir_in_masked64".}

proc setDirMasked*(gpioMask: set[Gpio]; value: set[Gpio]) {.importc: "gpio_set_dir_masked".}
  ## Set multiple GPIO directions
  ##
  ## \param mask Bitmask of GPIO to set to input
  ## \param value Values to set
  ##
  ## For each 1 bit in "mask", switch that pin to the direction given by
  ## corresponding bit in "value", leaving other pins unchanged.
  ## E.g. gpio_set_dir_masked(0x3, 0x2); -> set pin 0 to input, pin 1 to output,
  ## simultaneously.

proc setDirMasked64*(gpioMask: set[Gpio]; value: set[Gpio]) {.importc: "gpio_set_dir_masked64".}

proc setDirAllBits*(values: set[Gpio]) {.importc: "gpio_set_dir_all_bits".}
  ## Set direction of all pins simultaneously.
  ##
  ## \param values individual settings for each gpio; for GPIO N, bit N is 1 for out, 0 for in

proc setDirAllBits64*(values: set[Gpio]) {.importc: "gpio_set_dir_all_bits64".}

proc setDir*(gpio: Gpio; `out`: Direction) {.importc: "gpio_set_dir".}
  ## Set a single GPIO direction
  ##
  ## \param gpio GPIO number
  ## \param out true for out, false for in

proc isDirOut*(gpio: Gpio): bool {.importc: "gpio_is_dir_out".}
  ## Check if a specific GPIO direction is OUT
  ##
  ## \param gpio GPIO number
  ## \return true if the direction for the pin is OUT

proc getDir*(gpio: Gpio): Direction {.importc: "gpio_get_dir".}
  ## Get a specific GPIO direction
  ##
  ## \param gpio GPIO number
  ## \return 1 for out, 0 for in

{.pop.}

# Nim helpers

template setupGpio*(name: untyped; pin: static[range[0 .. 47]]; dir: Direction) =
  # Makes a `const 'name' = pin; init(name); name.setDir(dir)
  # usage: setupGpio(myPinName, 5, Out)
  const name = Gpio(pin)
  init(name)
  setDir(name, dir)

proc init*(_: typedesc[Gpio]; pin: static[range[0 .. 47]]; dir: Direction = Out): Gpio =
  ## perform the typical assignment, init(), and setDir() steps all in one proc.
  ## usage: let myPin = Gpio.init(5, In)
  ##
  ## **parameters**
  ## **pin** : *int* (between 0 and 35) - the pin number corresponding the the Gpio pin
  ## **dir** : *bool* [optional, defaults to Out] - *Out* or *In*
  result = static(Gpio(pin))
  result.init()
  result.setDir(dir)

when defined(runtests):
  setupGpio(myPinName, 5, Out)
  static:
    doAssert myPinName.ord == 5

  let myPin = Gpio.init(5, In)
  discard myPin

  let allpins = gpioGetAll()
  discard allpins

  setDirOut64({Gpio(47)})

