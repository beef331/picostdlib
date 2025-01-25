import std/[strformat, strutils, strscans, sets, genasts, json]
import std/os except commandLineParams
import pkg/micros

export os except commandLineParams

when declared(mkDir):
  template createDir*(path: string) = mkDir(path)
when declared(rmFile):
  template removeFile*(path: string) = rmFile(path)
when declared(cpFile):
  template copyFile*(source, dest: string) = cpFile(source, dest)

type
  LinkableLib* = enum
    adc = "hardware_adc"
    aon_timer = "pico_aon_timer"
    base = "hardware_base"
    claim = "hardware_claim"
    clocks = "hardware_clocks"
    # divider = "hardware_divider"  ## collides with pico_divider
    dma = "hardware_dma"
    exception = "hardware_exception"
    flash = "hardware_flash"
    gpio = "pico_stdlib"
    i2c = "hardware_i2c"
    interp = "hardware_interp"
    irq = "hardware_irq"
    pio = "hardware_pio"
    pll = "hardware_pll"
    powman = "hardware_powman"
    pwm = "hardware_pwm"
    reset = "hardware_resets"
    rtc = "hardware_rtc"
    spi = "hardware_spi"
    # sync = "hardware_sync"  ## collides with pico_sync
    timer = "hardware_timer"
    uart = "pico_stdlib"
    vreg = "hardware_vreg"
    watchdog = "hardware_watchdog"
    xosc = "hardware_xosc"

    multicore = "pico_multicore"

    ## pico_stdlib group
    binary_info = "pico_stdlib"
    runtime = "pico_stdlib"
    platform = "pico_stdlib"
    # printf = "pico_stdlib"  ## TODO
    stdio = "pico_stdlib"
    util = "pico_stdlib"

    async_context_base = "pico_async_context_base"
    async_context_poll = "pico_async_context_poll"
    async_context_threadsafe_background = "pico_async_context_threadsafe_background"
    async_context_freertos = "pico_async_context_freertos"

    rand = "pico_rand"

    sync = "pico_sync"

    time = "pico_time"

    unique_id = "pico_unique_id"

    ## pico_runtime group, part of pico_stdlib
    bit_ops = "pico_stdlib"
    divider = "pico_stdlib"
    double = "pico_stdlib"
    # int64_ops = "pico_stdlib"  ## TODO
    `float` = "pico_stdlib"
    # malloc = "pico_stdlib"  ## TODO
    # mem_ops = "pico_stdlib"  ## TODO
    # standard_link = "pico_stdlib"  ## TODO

    # util = "pico_util"  ## in group pico_stdlib already

  BackendExtension {.pure.} = enum
    c, cpp


const cMakeIncludeTemplate* = """
# This is a generated file do not modify it, 'piconim' makes it every build.

target_link_libraries(${{target}} {strLibs})

target_include_directories(${{target}} PRIVATE {includes})

{pios}
"""

var buildDir* = ""
proc importPath*(program: string): string = buildDir / program / "imports.cmake"
proc nimcache*(program: string): string = buildDir / program / "nimcache"

macro parseLinkableLib(s: string): untyped =
  ## Parses enum using the field name and field str
  let
    lLib = bindSym"LinkableLib".enumDef
    caseStmt = caseStmt(NimName s)
  var usedLabels = initHashSet[string]()
  for field in lLib.fields:
    let
      fieldName = NimNode(field)[0]
      strName = newLit $fieldName
      valStr = NimNode(field)[^1].strVal
    caseStmt.add:
      let ofBrch = ofBranch(strName, fieldName)
      if valStr notin usedLabels:
        ofBrch.addCondition NimNode(field)[^1]
      ofBrch
    usedLabels.incl valStr
  caseStmt.add:
    elseBranch():
      genAst():
        raise newException(ValueError, "Not found field")
  result = NimNode caseStmt


proc getLinkedLib(fileName: string): tuple[libs: HashSet[string], pios: HashSet[string], includes: HashSet[string]] =
  ## Iterates over lines searching for includes adding to result
  let file = readFile(fileName)
  for line in file.split("\n"):
    var incld = ""
    if line.scanf("""#include "$+.""", incld) or line.scanf("""#include <$+.""", incld):
      let incld = incld.replace('/', '_')
      try:
        result.libs.incl $incld.splitFile.name.parseLinkableLib()
      except: discard
    elif line.scanf("""// picostdlib import: $+""", incld):
      let libs = incld.split(" ")
      for l in libs:
        result.libs.incl l
    elif line.scanf("""// picostdlib generate pio: $+""", incld):
      result.pios.incl incld
    elif line.scanf("""// picostdlib include: $+""", incld):
      result.includes.incl incld

proc getPicoLibs(program: string, extension: string): tuple[libs: string, pios: string, includes: string] =
  var libs = initHashSet[string]()
  var pios = initHashSet[string]()
  var includes = initHashSet[string]()
  for kind, path in walkDir(nimcache(program)):
    if kind == pcFile and path.endsWith(fmt".{extension}"):
      let res = getLinkedLib(path)
      libs.incl res.libs
      pios.incl res.pios
      includes.incl res.includes

  for lib in libs:
    result.libs.add lib
    result.libs.add " "
  for pio in pios:
    result.pios.add "pico_generate_pio_header(${target} \"" & pio & "\")\n"
  for incl in includes:
    result.includes.add "\n  "
    result.includes.add incl

proc genCMakeInclude*(program: string; backend: string) =
  ## Create a CMake include file in the csources containing:
  ##  - all pico-sdk libs to link
  ##  - path to current Nim compiler "lib" path, to be added to the
  ##    C compiler include path

  let extension = $parseEnum[BackendExtension](backend)

  let buildImportPath = importPath(program)

  # pico-sdk libs, pio headers
  let (strLibs, pios, includes) = getPicoLibs(program, extension)

  # only update file if contents change
  # to prevent CMake from reconfiguring
  if fileExists(buildImportPath):
    let oldTemplate = readFile(buildImportPath)
    let newTemplate = fmt(cMakeIncludeTemplate)
    if oldTemplate != newTemplate:
      echo "writing " & buildImportPath
      writeFile(buildImportPath, newTemplate)
  else:
    echo "writing " & buildImportPath
    createDir(buildImportPath.parentDir())
    writeFile(buildImportPath, fmt(cMakeIncludeTemplate))

proc updateJsonCache*(jsonFile: string) =
  let jsonFileCached = jsonFile.changeFileExt(".cached.json")

  if fileExists(jsonFileCached):
    let oldJsonFile = readFile(jsonFileCached)
    let newJsonFile = readFile(jsonFile)
    if oldJsonFile != newJsonFile:
      # only copy the json file if contents change
      echo "writing " & jsonFileCached
      copyFile(jsonFile, jsonFileCached)
    else:
      # preserve timestamp to prevent CMake from reconfiguring
      when declared(exec):
        when defined(posix):
          exec("cp -p " & quoteShell(jsonFileCached) & " " & quoteShell(jsonFile))
      else:
        setLastModificationTime(jsonFile, getLastModificationTime(jsonFileCached))
  else:
    echo "writing " & jsonFileCached
    copyFile(jsonFile, jsonFileCached)
