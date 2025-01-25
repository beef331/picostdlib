const packageName = getCurrentDir().splitPath().tail
const cmakeBinaryDir {.strdefine.} = getCurrentDir() / "build" / packageName

# import cmake config
const cmakecachePath = cmakeBinaryDir / "generated" / "cmakecache.nim"
when fileExists(cmakecachePath):
  staticInclude(cmakecachePath)

  when CMAKE_BUILD_TYPE in ["Release", "MinSizeRel", "RelWithDebInfo"]:
    when releaseFollowsCmake:
      switch("define", "release")

  when CMAKE_BUILD_TYPE == "MinSizeRel":
    switch("opt", "size") # needs to be after (define:release)

  when PICO_CYW43_SUPPORTED:
    switch("define", "picoCyw43Supported")

switch("define", "picosdk")

switch("cpu", "arm")
# switch("os", "any")
switch("define", "posix") # workaround for os=any

patchFile("stdlib", "monotimes", picostdlibPath / "patches" / "monotimes")
patchFile("stdlib", "posix_other", picostdlibPath / "patches" / "posix_other")
patchFile("stdlib", "asyncmacro", picostdlibPath / "patches" / "asyncmacro")
patchFile("stdlib", "asyncfutures", picostdlibPath / "patches" / "asyncfutures")
