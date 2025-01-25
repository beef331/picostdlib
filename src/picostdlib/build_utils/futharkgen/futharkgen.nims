switch("path", "$projectDir/../../..")

switch("d", "futharkgen")
switch("d", "useFuthark")
switch("d", "futharkRebuild")
switch("d", "opirRebuild")

include "../../../../template/src/config.nims"

switch("d", "cyw43ArchBackend:threadsafe_background")

switch("d", "cmakeBinaryDir:" & getCurrentDir() & "/build/futharkgen")
switch("d", "piconimCsourceDir:" & getCurrentDir() & "/template/csource")
