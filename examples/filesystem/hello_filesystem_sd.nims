
## filesystem modules - uncomment to enable

--define:pico_filesystem
# --define:pico_filesystem_default # includes flash, littlefs and fs_init
# --define:pico_filesystem_blockdevice_flash
# --define:pico_filesystem_blockdevice_heap
# --define:pico_filesystem_blockdevice_loopback
--define:pico_filesystem_blockdevice_sd
# --define:pico_filesystem_filesystem_littlefs
--define:pico_filesystem_filesystem_fat
