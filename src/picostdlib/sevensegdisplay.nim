import ./hardware/gpio
import ./pico/time

type
  SevenSeg* {.pure.} = enum
    a, b, c, dp, d, e, f, g
  CharacterName* {.pure.} = enum
    Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine, A, B, C, D, E, F

const
  Displayable = {'0'..'9', 'a'..'f'}
  CharLut = [
    Zero: '0',
    One: '1',
    Two: '2',
    Three: '3',
    Four: '4',
    Five: '5',
    Six: '6',
    Seven: '7',
    Eight: '8',
    Nine: '9',
    A: 'a',
    B: 'b',
    C: 'c',
    D: 'd',
    E: 'e',
    F: 'f'
  ]
  DisplayChars = [
    Zero: {a, b, c, d, e, f},
    One: {b, c},
    Two: {a, b, d, e, g},
    Three: {a, b, c, d, g},
    Four: {b, c, f, g},
    Five: {a, c, d, f, g},
    Six: {a, c, d, e, f, g},
    Seven: {a, b, c},
    Eight: {a..g} - {dp},
    Nine: {a..g} - {e, dp},
    A: {a, b, c, e, f, g},
    B: {c, d, e, f, g},
    C: {a, d, e, f},
    D: {b, c, d, e, g},
    E: {a, d, e, f, g},
    F: {a, e, f, g}
  ]

var SevenSegPins*: array[SevenSeg, Gpio]

proc getCharacter*(c: char): (CharacterName, bool) =
  if c in Displayable:
    for charName, x in CharLut:
      if x == c:
        return (charName, true)

proc draw*(s: CharacterName, drawMissing = true) =
  for c in SevenSeg:
    let val =
      if drawMissing: c notin DisplayChars[s]
      else: c in DisplayChars[s]
    SevenSegPins[c].put(val.Value)

proc drawAll*() =
  for c in SevenSeg:
    SevenSegPins[c].put(High)
  for c in SevenSeg:
    SevenSegPins[c].put(Low)
    sleepMs(100)
    SevenSegPins[c].put(High)

proc initPins*() =
  for x in SevenSeg:
    SevenSegPins[x].init()
    SevenSegPins[x].setDir(Out)
    SevenSegPins[x].put(High)
