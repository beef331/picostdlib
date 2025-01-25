switch("path", "$projectDir/../src")
switch("path", getCurrentDir() & "/src")

switch("d", "runtests")
switch("d", "futharkgen")

## filesystem modules - uncomment to enable
--define:pico_filesystem
--define:pico_filesystem_default # includes flash, littlefs and fs_init
--define:pico_filesystem_blockdevice_flash
--define:pico_filesystem_blockdevice_heap
--define:pico_filesystem_blockdevice_loopback
--define:pico_filesystem_blockdevice_sd
--define:pico_filesystem_filesystem_littlefs
--define:pico_filesystem_filesystem_fat

switch("d", "WIFI_SSID:myssid")
switch("d", "WIFI_PASSWORD:mypassword")

when not defined(mock):
  # switch("os", "freertos")
  # switch("define", "freertosKernelHeap:FreeRTOS-Kernel-Heap3")

  include "../template/src/config.nims"

  switch("d", "cmakeBinaryDir:" & getCurrentDir() & "/build/tests")
  switch("d", "piconimCsourceDir:" & getCurrentDir() & "/template/csource")
