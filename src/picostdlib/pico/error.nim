import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_base_headers/include".}

type
  PicoErrorCode* {.pure, size: sizeof(int8), importc: "enum pico_error_codes", header: "pico/error.h".} = enum
    ## Common return codes from pico_sdk methods that return a status
    PicoErrorInsufficientResources = -9
    PicoErrorConnectFailed = -8
    PicoErrorBadauth = -7
    PicoErrorIo = -6
    PicoErrorInvalidArg = -5
    PicoErrorNotPermitted = -4
    PicoErrorNoData = -3
    PicoErrorGeneric = -2
    PicoErrorTimeout = -1
    PicoErrorNone = 0

const
  PicoOk* = PicoErrorNone
