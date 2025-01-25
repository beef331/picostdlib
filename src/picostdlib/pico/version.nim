import ../helpers
{.localPassC: "-I" & cmakeBinaryDir & "/generated/pico_base".}
{.push header: "pico/version.h".}

let
  PicoSdkVersionMajor* {.importc: "PICO_SDK_VERSION_MAJOR".}: cuint
  PicoSdkVersionMinor* {.importc: "PICO_SDK_VERSION_MINOR".}: cuint
  PicoSdkVersionRevision* {.importc: "PICO_SDK_VERSION_REVISION".}: cuint
  PicoSdkVersionString* {.importc: "PICO_SDK_VERSION_STRING".}: cstring

{.pop.}
