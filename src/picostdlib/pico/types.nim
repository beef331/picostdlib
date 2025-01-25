import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_base_headers/include".}
{.push header: "pico/types.h".}

const picoOpaqueAbsoluteTime* {.booldefine.} = false
const picoIncludeRtcDatetime* {.booldefine.} = picoRp2040

when picoOpaqueAbsoluteTime:
  type
    AbsoluteTime* {.importc: "absolute_time_t".} = object
      ## the absolute time (now) of the hardware timer
      time*{.importc: "_private_us_since_boot".}: distinct uint64
else:
  type
    AbsoluteTime* {.importc: "absolute_time_t".} = distinct uint64

when picoIncludeRtcDatetime:
  type
    DatetimeT* {.importc: "datetime_t".} = object
      # Structure containing date and time information
      # When setting an RTC alarm, set a field to -1 tells
      # the RTC to not match on this field
      year* {.importc: "year".}: range[0'i16 .. 4095'i16] # 0..4095
      month* {.importc: "month".}: range[1'i8 .. 12'i8] # 1..12, 1 is January
      day* {.importc: "day".}: range[1'i8 .. 31'i8] # 1..28,29,30,31 depending on month
      dotw* {.importc: "dotw".}: range[0'i8 .. 6'i8] # 0..6, 0 is Sunday
      hour* {.importc: "hour".}: range[0'i8 .. 23'i8] # 0..23
      min* {.importc: "min".}: range[0'i8 .. 59'i8] # 0..59
      sec* {.importc: "sec".}: range[0'i8 .. 59'i8] # 0..59

    # Datetime* = object
    #   year*: 0u16..4095u16
    #   month*: 1u8..12u8
    #   day*: 1u8..31u8
    #   dotw*: 0u8..6u8
    #   hour*: 0u8..23u8
    #   min*, sec*: 0u8..59u8

proc toUsSinceBoot*(t: AbsoluteTime): uint64 {.importc: "to_us_since_boot".}
  ## convert an absolute_time_t into a number of microseconds since boot.
  ## \param t the absolute time to convert
  ## \return a number of microseconds since boot, equivalent to t

proc updateUsSinceBoot*(t: ptr AbsoluteTime; usSinceBoot: uint64) {.importc: "update_us_since_boot".}
  ## update an absolute_time_t value to represent a given number of microseconds since boot
  ## \param t the absolute time value to update
  ## \param us_since_boot the number of microseconds since boot to represent. Note this should be representable
  ##                      as a signed 64 bit integer

proc fromUsSinceBoot*(usSinceBoot: uint64): AbsoluteTime {.importc: "from_us_since_boot".}
  ## convert a number of microseconds since boot to an absolute_time_t
  ## \param us_since_boot number of microseconds since boot
  ## \return an absolute time equivalent to us_since_boot

{.pop.}


## Nim helpers

when picoIncludeRtcDatetime:
  import std/times
  export times

  func createDatetime*(): DatetimeT =
    # nonzero range requires initialization
    DatetimeT(month: 1, day: 1)

  proc toNimDateTime*(dt: DatetimeT; zone: Timezone = utc()): DateTime =
    return dateTime(
      year = int dt.year,
      month = Month dt.month,
      monthday = MonthdayRange dt.day,
      hour = HourRange dt.hour,
      minute = MinuteRange dt.min,
      second = SecondRange dt.sec,
      zone = zone
    )

  proc fromNimDateTime*(dt: DateTime): DatetimeT =
    let ndt = dt.utc()
    result = createDatetime()
    result.year = ndt.year.int16
    result.month = ndt.month.int8
    result.day = ndt.monthday.int8
    result.hour = ndt.hour.int8
    result.min = ndt.minute.int8
    result.sec = ndt.second.int8
    result.dotw = (ndt.weekday.int8 + 1) mod 7
