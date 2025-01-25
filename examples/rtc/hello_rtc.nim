import picostdlib
import picostdlib/hardware/rtc

stdioInitAll()
echo "Hello RTC!"

# Start on Friday 5th of June 2020 15:45:00
var t = DatetimeT(
  year: 2020,
  month: 06,
  day: 05,
  dotw: 5, # 0 is Sunday, so 5 is Friday
  hour: 15,
  min: 45,
  sec: 00
)

# Start the RTC
rtcInit()
if not rtcSetDatetime(t.addr):
  echo "Setting RTC failed."
else:
  # clk_sys is >2000x faster than clk_rtc, so datetime is not updated immediately when rtc_get_datetime() is called.
  # tbe delay is up to 3 RTC clock cycles (which is 64us with the default clock settings)
  sleepUs(64)

  # Print the time
  while true:
    if not rtcGetDatetime(t.addr):
      echo "Reading RTC failed."
    else:
      echo datetimeToStr(t)
    sleepMs(100)
