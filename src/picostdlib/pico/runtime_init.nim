import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_runtime_init/include".}
{.push header: "pico/runtime_init.h".}

proc runtimeInitClocks*() {.importc: "runtime_init_clocks".}
proc clocksInit*() {.importc: "clocks_init".}

{.pop.}
