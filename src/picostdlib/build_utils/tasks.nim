import std/strformat
import std/strutils
import std/json
import std/sequtils
import ./common

type
  PicoSetupError = object of CatchableError

let nimbleBackend = if backend.len > 0: backend else: "c"

common.buildDir = "build" / projectName()
doAssert projectName().len > 0

proc namedProgram(program: string): string =
  if namedBin.hasKey(program):
    namedBin[program]
  else:
    program

template picoError(msg: string) =
  raise newException(PicoSetupError, msg)

iterator getPrograms(): string =
  if namedBin.len > 0:
    for key in namedBin.keys:
      yield key
  else:
    for program in bin:
      yield program

proc getSelectedBins(): seq[string] =
  if namedBin.len > 0:
    for key in namedBin.keys:
      if key in commandLineParams:
        result.add key
    if result.len == 0:
      for key in namedBin.keys:
        result.add key
        break
  else:
    for program in bin:
      if program in commandLineParams:
        result.add program

    if result.len == 0:
      result = bin


task fastclean, "Clean task":

  if dirExists(buildDir):
    echo "Cleaning ", buildDir
    let command = "cmake --build " & quoteShell(buildDir) & " --target clean"
    echo command
    exec(command)

    let selectedBins = getSelectedBins()
    for program in getPrograms():
      if program notin selectedBins:
        continue

      rmDir(nimcache(program))


task distclean, "Distclean task":
  if dirExists(buildDir):
    echo "Removing ", buildDir
    rmDir(buildDir)


task configure, "Configure task":
  # I want to put this in the beforeBuild hook,
  # but there you can't see what binaries are
  # about to be built using commandLineParams.

  let selectedBins = getSelectedBins()
  for program in getPrograms():
    if program notin selectedBins:
      continue

    let buildImportPath = importPath(program)
    removeFile(buildImportPath)

  var cmakeArgs: seq[string]
  cmakeArgs.add "-DPICO_SDK_FETCH_FROM_GIT=on"
  cmakeArgs.add "-S"
  cmakeArgs.add "."
  cmakeArgs.add "-B"
  cmakeArgs.add buildDir

  let command = "cmake " & quoteShellCommand(cmakeArgs)
  echo command
  exec(command)

before build:
  if not fileExists(buildDir / "CMakeCache.txt"):
    exec("nimble configure")

  # delete the nimcache json files
  # afterBuild hook will only build those that have a json file
  for program in getPrograms():
    let jsonFile = nimcache(program) / namedProgram(program) & ".json"
    if fileExists(jsonFile):
      removeFile(jsonFile)


after build:
  var elfs: seq[string]
  for program in getPrograms():
    let jsonFile = nimcache(program) / namedProgram(program) & ".json"
    if not fileExists(jsonFile):
      continue

    genCMakeInclude(namedProgram(program), nimbleBackend)
    updateJsonCache(jsonFile)

    let elf = buildDir / program & ".elf"
    elfs.add(elf)

  # run cmake build
  var command = "cmake --build " & quoteShell(buildDir) & " -- -j4"
  echo command
  exec(command)

  if elfs.len > 0:
    try:
      exec("arm-none-eabi-size -G " & quoteShellCommand(elfs))
    except OSError as e: echo e.msg


task buildclean, "Clean and build task":
  let selectedBins = getSelectedBins()
  exec("nimble fastclean " & quoteShellCommand(selectedBins))
  exec("nimble build " & quoteShellCommand(selectedBins))


task upload, "Upload task":
  let selectedBins = getSelectedBins()
  if selectedBins.len > 0:
    let program = selectedBins[0]
    let name = program.splitPath.tail
    if "--build" in commandLineParams and "--clean" in commandLineParams:
      exec(fmt"nimble buildclean {program}")
    elif "--build" in commandLineParams:
      exec(fmt"nimble build {program}")
    exec(fmt"picotool info {buildDir}/{name}.uf2 -a")
    echo "\nUploading..."
    exec(fmt"picotool load {buildDir}/{name}.uf2 -v -x -f")


task monitor, "Monitor task":
  exec("minicom -w -D /dev/ttyACM0")
