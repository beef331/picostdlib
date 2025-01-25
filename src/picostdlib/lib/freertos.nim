##
## FreeRTOS Kernel <DEVELOPMENT BRANCH>
## Copyright (C) 2021 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
##
## SPDX-License-Identifier: MIT
##
## Permission is hereby granted, free of charge, to any person obtaining a copy of
## this software and associated documentation files (the "Software"), to deal in
## the Software without restriction, including without limitation the rights to
## use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
## the Software, and to permit persons to whom the Software is furnished to do so,
## subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
## FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
## COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
## IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##
## https://www.FreeRTOS.org
## https://github.com/FreeRTOS
##
{.hint[XDeclaredButNotUsed]: off.}
{.hint[User]: off.}

import ../hardware/timer # for clock_gettime
export timer

import ../helpers

when defined(nimcheck):
  include ../futharkgen/futhark_freertos
else:
  import std/os, std/macros

  import futhark

  const outputPath = when defined(futharkgen): futharkGenDir / "futhark_freertos.nim" else: ""

  importc:
    outputPath outputPath

    compilerArg "--target=arm-none-eabi"
    compilerArg "-mthumb"
    compilerArg "-mcpu=cortex-m0plus"
    compilerArg "-fsigned-char"
    compilerArg "-fshort-enums" # needed to get the right enum size

    sysPath futhark.getClangIncludePath()
    sysPath armSysrootInclude
    sysPath armInstallInclude
    sysPath cmakeBinaryDir / "generated/pico_base"
    sysPath picoSdkPath / "src/common/pico_base_headers/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "hardware_regs/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_base/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_sync/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "pico_platform/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_compiler/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_sections/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_panic/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_sync_spin_lock/include"
    sysPath freertosKernelPath / "portable/ThirdParty/GCC/RP2040/include"
    sysPath freertosKernelPath / "include"
    path piconimCsourceDir
    path getProjectPath()

    define "PICO_RP2040 (1)"

    renameCallback futharkRenameCallback

    "FreeRTOS.h"
    "task.h"
    "queue.h"
    "timers.h"
    "semphr.h"

when freertosKernelHeap != "":
  {.emit: ["// picostdlib import: ", freertosKernelHeap].}

let tskIDLE_PRIORITY* = UBaseTypeT(0)

{.push header: "FreeRTOSConfig.h".}

let configMINIMAL_STACK_SIZE* {.importc: "configMINIMAL_STACK_SIZE".}: cuint

{.pop.}
