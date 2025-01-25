import pkg/[commandant]
import std/[strformat, strutils, os, osproc, terminal, sequtils, tables, macros, json]
import ./common

type PicoSetupError = object of CatchableError

proc printError(msg: string) =
  echo ansiForegroundColorCode(fgRed), msg, ansiResetCode


template picoError(msg: string) =
  raise newException(PicoSetupError, msg)


proc helpMessage(): string =
  result = """piconim: Create and build Raspberry Pi Pico Nim projects.

Subcommands:
  init
  configure
  build
  path

Run piconim init <project-name> to create a new project directory from a
template. This will create a new folder, so make sure you are in the parent
folder. You can also provide the following options to the subcommand:

    (--sdk, -s) ->       specify the path to a locally installed pico-sdk
                         repository. ex: --sdk:/home/user/pico-sdk
    (--board, -b) ->     specify the board type (pico or pico_w are accepted),
                         choosing pico_w includes a pico_w blink example
    (--overwrite, -O) -> a flag to specify overwriting an exisiting directory
                         with the <project-name> already created. Be careful
                         with this. ex: piconim myProject --overwrite will
                         replace a folder named myProject.

Run piconim configure to create the `build/<project>/` directory. This
is required before building if the `build/<project>/` does not yet exist (for
example after a fresh clone or git clean of an existing project.) The following
options are available:

    (--project, -p) ->   specify build project name. By default it will
                         use the nimble package's name as project name
    (--source, -S) -->   specify the source directory containing the
                         CMakeLists.txt file you wish to use. By default it
                         is set to the current directory.
    (--sdk, -s) ->       specify the path to a locally installed pico-sdk
                         repository. This is only used for the setup.
    (--board, -b) ->     specify the board type. This is only used for the setup.

Run piconim build <program> to compile the project, the <program>.uf2
file will be located in `build/<project>/`

    (--project, -p) ->   specify build project name. By default it will
                         use the nimble package's name as project name
    (--target, -t) ->    specify the cmake target associated with this binary.
                         By default it will be the program's basename.
    (--compileOnly, -c) -> only compile nim code, don't invoke cmake
    (--upload, -u) -->   Attempt to upload and execute using picotool.
"""

const embeddedFiles = (proc (): OrderedTable[string, string] =
  const root = getProjectPath() / ".." / ".." / ".." / "template"
  for item in os.walkDirRec(root, relative = true, checkDir = true):
    result[item] = staticRead(root / item)
)()

proc validateSdkPath(sdk: string) =
  # check if the sdk option path exists and has the appropriate cmake file (very basic check...)
  if not sdk.dirExists():
    picoError fmt"could not find an existing directory with the provided --sdk argument : {sdk}"

  if not fileExists(sdk / "pico_sdk_init.cmake"):
    picoError fmt"directory provided with --sdk argument does not appear to be a valid pico-sdk library: {sdk}"


proc createProject(projectPath: string; sdk = ""; board: string = ""; override = false) =
  let name = projectPath.splitPath.tail

  echo "Select type binary or hybrid to be able to build the program"

  let nimbleProc = startProcess(
    "nimble",
    args = ["init", name],
    options = {poEchoCmd, poUsePath, poParentStreams}
  )
  let nimbleExit = nimbleProc.waitForExit()
  if nimbleExit != 0:
    echo "Nimble exited with error code: ", nimbleExit
    echo "Will not copy over template"
  else:
    discard existsOrCreateDir(projectPath)

    for f in embeddedFiles.keys:
      echo "piconim: writing file ", projectPath / f
      let filepath = projectPath / f
      createDir(filepath.parentDir)
      writeFile(filepath, embeddedFiles[f])

    if board == "pico_w":
      echo "piconim: moving ", projectPath / "src" / "picow_blink.nim", " to ", projectPath / "src" / "blink.nim"
      moveFile(projectPath / "src" / "picow_blink.nim", projectPath / "src" / "blink.nim")
    else:
      echo "piconim: removing ", projectPath / "src" / "picow_blink.nim"
      removeFile(projectPath / "src" / "picow_blink.nim")

    # rename nim file
    echo "piconim: moving ", projectPath / "src" / "blink.nim", " to ", projectPath / "src" / name & ".nim"
    moveFile(projectPath / "src" / "blink.nim", projectPath / "src" / name & ".nim")

    # add picostdlib tasks to nimble file
    let nimbleFile = projectPath / name & ".nimble"
    echo "piconim: updating file ", nimbleFile
    nimbleFile.writeFile(nimbleFile.readFile() & "requires \"picostdlib >= 0.4.0\"\n\ninclude picostdlib/build_utils/tasks\n")

    # replace blink name with project name
    # set SDK path if provided
    let cmakelistsPath = projectPath / "CMakeLists.txt"
    var cmakelistsContent = cmakelistsPath.readFile()
    cmakelistsContent = cmakelistsContent.replace("blink", name)
    if sdk != "":
      cmakelistsContent = cmakelistsContent.replace("# set(PICO_SDK_PATH ENV{PICO_SDK_PATH})", "set(PICO_SDK_PATH \"" & sdk & "\") # Set by piconim")
    cmakelistsContent = cmakelistsContent.replace("set(PICO_BOARD pico)", "set(PICO_BOARD " & board & ") # Set by piconim")
    if board == "pico_w":
      cmakelistsContent = cmakelistsContent.replace("# pico_cyw43_arch_lwip_threadsafe_background pico_lwip_mbedtls pico_mbedtls", "pico_cyw43_arch_lwip_threadsafe_background pico_lwip_mbedtls pico_mbedtls")
    echo "piconim: updating file ", cmakelistsPath
    cmakelistsPath.writeFile(cmakelistsContent)

    echo "Project created!"
    echo &"Type `cd {name}` and then `nimble configure` to configure CMake"
    echo "Then run `nimble build` to compile the project"

proc getProjectInfo(): JsonNode =
  return execProcess("nimble", args = ["dump", "--json"], options = {poStdErrToStdOut, poUsePath}).parseJson()

proc doSetup(projectIn = ""; sourceDirIn = "."; boardIn = ""; sdk = "") =
  let projectInfo = getProjectInfo()
  let project = if projectIn != "": projectIn else: projectInfo["name"].str
  buildDir = "build" / project

  echo "Setting up " & buildDir

  var cmakeArgs: seq[string]
  cmakeArgs.add "-DPICO_SDK_FETCH_FROM_GIT=on"
  if sdk != "":
    cmakeArgs.add "-DPICO_SDK_PATH=" & sdk
  if boardIn != "":
    cmakeArgs.add "-DPICO_BOARD=" & boardIn
  cmakeArgs.add "-S"
  cmakeArgs.add sourceDirIn
  cmakeArgs.add "-B"
  cmakeArgs.add buildDir

  let cmakecmd = "cmake " & quoteShellCommand(cmakeArgs)
  echo ">> " & cmakecmd
  doAssert execCmd(cmakecmd) == 0

proc doBuild(mainProgram: string; projectIn = ""; targetIn = ""; compileOnly: bool = false; upload: bool = false; sourceDirIn: string = "."; buildBoardIn: string = "") =
  let projectInfo = getProjectInfo()
  let project = if projectIn != "": projectIn else: projectInfo["name"].str
  buildDir = "build" / project
  let program = mainProgram.lastPathPart()
  let target = if targetIn != "": targetIn else: program
  let backend = if projectInfo["backend"].str != "": projectInfo["backend"].str else: "c"

  if not fileExists(buildDir / "CMakeCache.txt"):
    doSetup(project, sourceDirIn, buildBoardIn)

  echo "Building " & program & " in " & buildDir
  let jsonFile = nimcache(target) / program & ".json"
  if fileExists(jsonFile):
    removeFile(jsonFile)

  # compile the nim program to .c files
  let nimcmd = "nim " & quoteShellCommand([backend, "-d:cmakeBinaryDir:" & absolutePath(buildDir), "-d:cmakeTarget:" & target, "--nimcache:" & "build" / project / target / "nimcache", mainProgram])
  echo ">> " & nimcmd
  if execCmd(nimcmd) != 0:
    removeFile(jsonFile.changeFileExt(".cached.json"))
    picoError(fmt"unable to compile the provided nim program: {mainProgram}")

  genCMakeInclude(target, backend)
  if fileExists(jsonFile):
    updateJsonCache(jsonFile)

  if compileOnly:
    return

  # run cmake build
  var args = @["--build", buildDir, "--target", target, "--"]
  if countProcessors() > 1:
    args.add("-j" & $countProcessors())
  let cmakecmd = "cmake " & quoteShellCommand(args)
  echo ">> " & cmakecmd
  doAssert execCmd(cmakecmd) == 0

  # size statistics for compiled binary
  let elf = buildDir / target & ".elf"
  if fileExists(elf):
    discard execCmd("arm-none-eabi-size -G " & quoteShell(elf))

  let uf2 = buildDir / target & ".uf2"
  if upload and fileExists(uf2):
    discard execCmd("picotool info -a " & quoteShell(uf2))
    discard execCmd("picotool load -x " & quoteShell(uf2) & " -f")


proc validateInitInputs(name: string; sdk: string = ""; board: string = ""; overwrite: bool) =
  ## ensures that provided setup cli parameters will work

  # check if name is valid filename
  if not name.isValidFilename():
    picoError fmt"provided --name argument will not work as filename: {name}"

  # check if the name already has a directory with the same name
  if dirExists(joinPath(getCurrentDir(), name)) and overwrite == false:
    picoError fmt"provided project name ({name}) already has directory, use --overwrite if you wish to replace contents"

  if sdk != "":
    validateSdkPath sdk

proc doPath() =
  let appDir = os.getAppDir()
  if dirExists(appDir / "src" / "picostdlib"):
    echo appDir / "src" / "picostdlib" # development
  elif dirExists(appDir / "picostdlib"):
    echo appDir / "picostdlib" # installed
  else:
    echo appDir # fallback

# --- MAIN PROGRAM ---
when isMainModule:
  commandline:
    subcommand(init, "init", "i"):
      argument(name, string)
      commandant.option(board, string, "board", "b", "pico")
      commandant.option(sdk, string, "sdk", "s")
      flag(overwriteTemplate, "overwrite", "O")
    subcommand(setup, "configure", "c"):
      commandant.option(projectInSetup, string, "project", "p")
      commandant.option(sourceDirIn, string, "source", "S", ".")
      commandant.option(setupSdk, string, "sdk", "s")
      commandant.option(boardIn, string, "board", "b")
    subcommand(build, "build", "b"):
      argument(mainProgram, string)
      commandant.option(projectInBuild, string, "project", "p")
      commandant.option(targetIn, string, "target", "t")
      flag(compileOnly, "compileOnly", "c")
      flag(upload, "upload", "u")
      commandant.option(buildSourceDirIn, string, "source", "S", ".")
      commandant.option(buildBoardIn, string, "board", "b")
    subcommand(path, "path"):
      discard


  if init:
    validateInitInputs(name, sdk, board, overwriteTemplate)
    let dirDidExist = dirExists(name)
    try:
      createProject(name, sdk, board)
    except PicoSetupError as e:
      printError(e.msg)
      if not dirDidExist:
        try:
          removeDir(name) # We failed remove file
        except IOError:
          discard
  elif setup:
    doSetup(projectInSetup, sourceDirIn, boardIn, setupSdk)
  elif build:
    doBuild(mainProgram, projectInBuild, targetIn, compileOnly, upload, buildSourceDirIn, buildBoardIn)
  elif path:
    doPath()
  else:
    echo helpMessage()
