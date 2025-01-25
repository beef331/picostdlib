import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_float/include".}
{.push header: "pico/float.h".}

proc fix2float*(m: int32; e: cint): cfloat {.importc: "fix2float".}
proc ufix2float*(m: uint32; e: cint): cfloat {.importc: "ufix2float".}
proc fix642float*(m: int64; e: cint): cfloat {.importc: "fix642float".}
proc ufix642float*(m: uint64; e: cint): cfloat {.importc: "ufix642float".}

## These methods round towards -Infinity.
proc float2fix*(f: cfloat; e: cint): int32 {.importc: "float2fix".}
proc float2ufix*(f: cfloat; e: cint): uint32 {.importc: "float2ufix".}
proc float2fix64*(f: cfloat; e: cint): int64 {.importc: "float2fix64".}
proc float2ufix64*(f: cfloat; e: cint): uint64 {.importc: "float2ufix64".}
proc float2int*(f: cfloat): int32 {.importc: "float2int".}
proc float2int64*(f: cfloat): int64 {.importc: "float2int64".}

## These methods round towards 0.
proc float2int_z*(f: cfloat): int32 {.importc: "float2int_z".}
proc float2int64_z*(f: cfloat): int64 {.importc: "float2int64_z".}
proc exp10f*(x: cfloat): cfloat {.importc: "exp10f".}
proc sincosf*(x: cfloat; sinx: ptr cfloat; cosx: ptr cfloat) {.importc: "sincosf".}
proc powintf*(x: cfloat; y: cint): cfloat {.importc: "powintf".}

{.pop.}
