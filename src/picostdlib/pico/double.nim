import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_double/include".}
{.push header: "pico/double.h".}

proc fix2double*(m: int32; e: cint): cdouble {.importc: "fix2double".}
proc ufix2double*(m: uint32; e: cint): cdouble {.importc: "ufix2double".}
proc fix642double*(m: int64; e: cint): cdouble {.importc: "fix642double".}
proc ufix642double*(m: uint64; e: cint): cdouble {.importc: "ufix642double".}

## These methods round towards -Infinity.
proc double2fix*(f: cdouble; e: cint): int32 {.importc: "double2fix".}
proc double2ufix*(f: cdouble; e: cint): uint32 {.importc: "double2ufix".}
proc double2fix64*(f: cdouble; e: cint): int64 {.importc: "double2fix64".}
proc double2ufix64*(f: cdouble; e: cint): uint64 {.importc: "double2ufix64".}
proc double2int*(f: cdouble): int32 {.importc: "double2int".}
proc double2int64*(f: cdouble): int64 {.importc: "double2int64".}

## These methods round towards 0.
proc double2int_z*(f: cdouble): int32 {.importc: "double2int_z".}
proc double2int64_z*(f: cdouble): int64 {.importc: "double2int64_z".}
proc exp10*(x: cdouble): cdouble {.importc: "exp10".}
proc sincos*(x: cdouble; sinx: ptr cdouble; cosx: ptr cdouble) {.importc: "sincos".}
proc powint*(x: cdouble; y: cint): cdouble {.importc: "powint".}

{.pop.}
