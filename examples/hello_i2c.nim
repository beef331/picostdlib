import picostdlib/[gpio, i2c]
import picostdlib

const 
  on = true
  off = false
  p0: uint8 = 0b00000001 #create a bit mask 
  p1: uint8 = 0b00000010
  p2: uint8 = 0b00000100
  p3: uint8 = 0b00001000
  p4: uint8 = 0b00010000
  p5: uint8 = 0b00100000
  p6: uint8 = 0b01000000
  p7: uint8 = 0b10000000

type 
  Pcf8574 = ref object #creates the pcf8574 object
    addressDevice: uint8
    blockk: I2cInst
    buffer: uint8

<<<<<<< HEAD
proc writeBytex(self: Pcf8574, dato: uint8 ) = #proc to write the byte 
  let dato = dato.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.addressDevice, dato, 1, true) #write the data on the i2c bus 

proc digitaWrite(self:Pcf8574, pin:uint8, value: bool) =
  if value == on:
    self.buffer = (self.buffer or pin) #go to act (turn on) the selected bit 
    writeBytex(self, self.buffer)
  elif value == off:
    self.buffer = (self.buffer and pin) #go to act (turn off) the selected bit 
    writeBytex(self, self.buffer)
=======
proc writeBytex(self: Pcf8574, dato:uint8 ) = #proc to write the byte 
  let dato = dato.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.addressDevice, dato,1, true) #write the data on the i2c bus 

proc digitaWrite(self:Pcf8574,pin:uint8, value:bool) =
  if value == on:
    self.buffer = (self.buffer or pin) #go to act (turn on) the selected bit 
    writeBytex(self,self.buffer)
  elif value == off:
    self.buffer = (self.buffer and pin) #go to act (turn off) the selected bit 
    writeBytex(self,self.buffer)
>>>>>>> 1e185632afa82362ac111789620c484db97d2448


when isMainModule:
  stdioInitAll()
  let expander = Pcf8574(addressDevice: 0x20, blockk: i2c0, buffer: 0b00000000) #initializes the object 

  const sda = 0.Gpio 
  const scl = 1.Gpio 
  const address = 0x20
<<<<<<< HEAD
  init(i2c0, 10000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()

  var buffer: uint8 = 0b00000000
=======
  init(i2c0,10000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()

  var buffer:uint8 = 0b00000000
>>>>>>> 1e185632afa82362ac111789620c484db97d2448
  writeBytex(expander, buffer)
  sleep(1000)

  while true:
<<<<<<< HEAD
    digitaWrite(expander, p1, on) #turn on the bit "p1" 
    sleep(1500)
    digitaWrite(expander, p4, on) #turn on the bit "p4" 
    sleep(1500)
    digitaWrite(expander, p1, off) #turn off the bit "p1" 
    sleep(1500)
    digitaWrite(expander, p4, off) #turn off the bit "p4" 
    sleep(1500)
    
#[ in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc) 
add--> (hardware_i2c) ]#
=======
    digitaWrite(expander,p1,on) #turn on the bit "p1" 
    sleep(1500)
    digitaWrite(expander,p4,on) #turn on the bit "p4" 
    sleep(1500)
    digitaWrite(expander,p1,off) #turn off the bit "p1" 
    sleep(1500)
    digitaWrite(expander,p4,off) #turn off the bit "p4" 
    sleep(1500)
    
#[ in ...csource/CMakeLists.txt add target_link_libraries(tests pico_stdlib hardware_adc) 
add--> (hardware_i2c) ]#
>>>>>>> 1e185632afa82362ac111789620c484db97d2448
