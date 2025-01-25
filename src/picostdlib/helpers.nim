import std/os, std/strutils, std/macros, std/compilesettings

macro staticInclude(path: static[string]): untyped =
  newTree(nnkIncludeStmt, newLit(path))

type
  PicoPlatformKind* = enum
    PlatformRp2040 = "rp2040"
    PlatformRp2350_ArmS = "rp2350-arm-s"
    PlatformRp2350_RiscV = "rp235-riscv"

  PicoChipKind* = enum
    ChipRp2040 = "rp2040"
    ChipRp2350 = "rp2350"

const cmakeBinaryDir* {.strdefine.} = os.getEnv("CMAKE_BINARY_DIR").replace('\\', DirSep)
const cmakecachePath = cmakeBinaryDir / "generated" / "cmakecache.nim"

when fileExists(cmakecachePath):
  # exports PICO_SDK_PATH, PICO_BOARD, CMAKE_BUILD_TYPE...
  staticInclude(cmakecachePath)

const picoSdkPath* {.strdefine.} = when declared(PICO_SDK_PATH): PICO_SDK_PATH else: os.getEnv("PICO_SDK_PATH").replace('\\', DirSep)
const freertosKernelPath* {.strdefine.} = when declared(FREERTOS_KERNEL_PATH): FREERTOS_KERNEL_PATH else: ""
const picoMbedtlsPath* {.strdefine.} = when declared(PICO_MBEDTLS_PATH): PICO_MBEDTLS_PATH else: picoSdkPath / "lib" / "mbedtls"
const picoLwipPath* {.strdefine.} = when declared(PICO_LWIP_PATH): PICO_LWIP_PATH else: picoSdkPath / "lib" / "lwip"

const picoBoard* {.strdefine.} = when declared(PICO_BOARD): PICO_BOARD else: "pico"
const picoPlatform* = when declared(PICO_PLATFORM): parseEnum[PicoPlatformKind](PICO_PLATFORM, PlatformRp2040) else: PlatformRp2040
const picoChip* = when declared(PICO_CHIP): parseEnum[PicoChipKind](PICO_CHIP, ChipRp2040) else: ChipRp2040

const picoRp2040* = picoChip == ChipRp2040
const picoRp2350* = picoChip == ChipRp2350

const piconimCsourceDir* {.strdefine.} = getProjectPath().replace('\\', DirSep).parentDir() / "csource"
const picostdlibFutharkSysroot* {.strdefine.} = ""
const nimcacheDir* = querySetting(SingleValueSetting.nimcacheDir)
const futharkGenDir* = currentSourcePath.replace('\\', DirSep).parentDir / "futharkgen"
when defined(nimcheck):
  const cyw43ArchBackend* = "threadsafe_background"
else:
  const cyw43ArchBackend* {.strdefine.} = "none" # threadsafe_background, freertos, poll, none
const freertosKernelHeap* {.strdefine.} = ""

const armSysrootInclude* = static:
  when picostdlibFutharkSysroot != "":
    picostdlibFutharkSysroot
  else:
    let sysroot = staticExec("arm-none-eabi-gcc -print-sysroot").strip().replace('\\', DirSep).normalizedPath()
    if sysroot != "" and dirExists(sysroot / "include"):
      sysroot / "include"
    elif dirExists("/usr/lib/arm-none-eabi/include"): # symlink to /usr/include/newlib on debian
      "/usr/lib/arm-none-eabi/include"
    elif dirExists("/usr/arm-none-eabi/include"): # check fallback
      "/usr/arm-none-eabi/include"
    else:
      ""

const armInstallInclude* = static:
  let searchDirsResult = staticExec("arm-none-eabi-gcc -print-search-dirs").strip()
  if searchDirsResult != "":
    let lines = searchDirsResult.split("\n")
    if lines.len >= 1:
      let firstLine = lines[0].strip().split(": ")
      if firstLine.len >= 2:
        firstLine[1].replace('\\', DirSep).normalizedPath() / "include"
      else: ""
    else: ""
  else: ""

func futharkRenameCallback*(name: string; kind: string; partof: string): string =
  result = name
  if kind in ["struct", "anon", "typedef", "enum"] and result.len > 0:
    removePrefix(result, "struct_")
    removePrefix(result, "enum_")
    if result.len > 0:
      result[0] = result[0].toUpperAscii()
