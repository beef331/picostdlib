import picostdlib
const picousbVer* = "0.1.0"

type
    PicoUsb*  = ref object 
      setBool:bool
      stringX:string

#---- private functions -------
proc readLineInternal(self: PicoUsb, time: uint32 = 100) = #proc general reading of a usb string.
    var readCh: char
    while true: #until you find '\ 255' it run... 
      readCh = getCharWithTimeout(time) #save the character in the variable  readCh.
      if readCh == '\255': #if  found '\255'..
        break #interrupt the while!
      else: #If there is not...
        self.stringX.add($readCh) #add the character in stringX (string) after converting it.

proc setReady(self: PicoUsb) = #proc to check if there is anything in the usb buffer. 
    readLineInternal(self) #read using the private procedure readLineInternal.
    if self.stringX.len > 0: #if string stringX is not empty .. 
        self.setBool = true #set setbool = true.
    else: #if string stringX is empty .. 
        self.setBool = false #set setbool = false .

#----- pubblic functions --------
proc isReady*(self: PicoUsb): bool = #procedure for checking the buffer status. 
    setReady(self) #calls the procedure to set the variable.
    return self.setBool #return the value.

proc readLine*(self: PicoUsb, time: uint32 = 100): string = #proc for read the string in usb 
    readLineInternal(self, time) #read with the private function.
    result = self.stringX #returns the complete string .
    self.stringX = "" #reset variable stringX (= "" empty string).
