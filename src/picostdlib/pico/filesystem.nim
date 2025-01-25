
when defined(pico_filesystem) or defined(nimcheck):
  import std/os, std/strutils, std/posix

  export os, posix

  const picoVfsPath = currentSourcePath.replace('\\', DirSep).parentDir.parentDir / "vendor" / "pico-vfs"

  {.emit: "// picostdlib include: " & picoVfsPath / "include".}
  {.compile: picoVfsPath / "src" / "filesystem" / "vfs.c".}
  {.emit: "// picostdlib import: pico_clib_interface pico_sync".}

  when defined(pico_filesystem_default) or defined(nimcheck):
    {.compile: picoVfsPath / "src" / "filesystem" / "fs_init.c".}

  type cssize_t* {.importc: "ssize_t", nodecl.} = int

  {.push header: "blockdevice/blockdevice.h".}

  type
    Blockdevice* {.importc: "blockdevice_t".} = object
      name*: cstring
      config*: pointer
      isInitialized* {.importc: "is_initialized".}: bool

  {.pop.}


  type
    FilesystemType* {.size: sizeof(uint8).} = enum
      FsTypeFat
      FsTypeLittleFS

    DirectoryType* {.size: sizeof(uint8).} = enum
      DtUnknown = 0
      DtDir = 4
      DtReg = 8

  {.push header: "filesystem/filesystem.h".}

  type
    DirectoryEntry* {.importc: "struct dirent".} = object
      d_type*: DirectoryType
      d_name*: array[255 + 1, char]

    FilesystemFile* {.importc: "fs_file_t".} = object
      fd*: cint
      context*: pointer

    FilesystemDirectory* {.importc: "fs_dir_t".} = object
      fd*: cint
      context*: pointer
      current*: DirectoryEntry

    Filesystem* {.importc: "filesystem_t".} = object
      fsType* {.importc: "type".}: FilesystemType
      name*: cstring
      context*: pointer

      mount*: proc(fs: ptr Filesystem; device: ptr BlockDevice; pending: bool): cint
      unmount*: proc(fs: ptr Filesystem): cint
      format*: proc(fs: ptr Filesystem; device: ptr BlockDevice): cint
      remove*: proc(fs: ptr Filesystem; path: cstring): cint
      rename*: proc(fs: ptr Filesystem; oldpath: cstring; newpath: cstring): cint
      mkdir*: proc(fs: ptr Filesystem; path: cstring): cint
      rmdir*: proc(fs: ptr Filesystem; path: cstring): cint
      stat*: proc(fs: ptr Filesystem; path: cstring; stat: Stat): cint

      file_open*: proc(fs: ptr Filesystem; file: ptr FilesystemFile; path: cstring; flags: cint): cint
      file_close*: proc(fs: ptr Filesystem; file: ptr FilesystemFile): cint
      file_write*: proc(fs: ptr Filesystem; file: ptr FilesystemFile; buffer: pointer; size: csize_t): cssize_t
      file_read*: proc(fs: ptr Filesystem; file: ptr FilesystemFile; buffer: pointer; size: csize_t): cssize_t
      file_sync*: proc(fs: ptr Filesystem; file: ptr FilesystemFile): cint
      file_seek*: proc(fs: ptr Filesystem; file: ptr FilesystemFile, offset: Off; whence: cint): Off
      file_tell*: proc(fs: ptr Filesystem; file: ptr FilesystemFile): Off
      file_size*: proc(fs: ptr Filesystem; file: ptr FilesystemFile): Off
      file_truncate*: proc(fs: ptr Filesystem; file: ptr FilesystemFile; length: Off): cint

      dir_open*: proc(fs: ptr Filesystem; dir: ptr FilesystemDirectory; path: cstring): cint
      dir_close*: proc(fs: ptr Filesystem; dir: ptr FilesystemDirectory): cint
      dir_read*: proc(fs: ptr Filesystem; dir: ptr FilesystemDirectory; ent: ptr DirectoryEntry): cint

  let PATH_MAX* {.importc: "PATH_MAX".}: cuint = 256

  {.pop.}


  {.push header: "filesystem/vfs.h".}

  let PICO_FS_DEFAULT_SIZE* {.importc: "PICO_FS_DEFAULT_SIZE".}: cuint = 1408 * 1024

  when defined(pico_filesystem_default) or defined(nimcheck):
    proc fsInit*(): bool {.importc: "fs_init".}
      ## Enable predefined file systems
      ##
      ## This default function defines the block device and file system, formats it if necessary and then mounts it on `/` to make it available.
      ##
      ## \retval true Init succeeded.
      ## \retval false Init failed.

  proc fsFormat*(fs: ptr Filesystem; device: ptr Blockdevice): cint {.importc: "fs_format".}
    ## Format block device with specify file system
    ##
    ## Block devices can be formatted and made available as a file system.
    ##
    ## \param fs File system object. Format the block device according to the specified file system.
    ## \param device Block device used in the file system.
    ## \retval 0 Format succeeded.
    ## \retval -1 Format failed. Error codes are indicated by errno.

  proc fsMount*(path: cstring; fs: ptr Filesystem; device: ptr Blockdevice): cint {.importc: "fs_mount".}
    ## Mounts a file system with block devices at the specified path.
    ##
    ## \param path Directory path of the mount point. Specify a string beginning with a slash.
    ## \param fs File system object.
    ## \param device Block device used in the file system. Block devices must be formatted with a file system.
    ## \retval 0 Mount succeeded.
    ## \retval -1 Mount failed. Error codes are indicated by errno.

  proc fsUnmount*(path: cstring): cint {.importc: "fs_unmount".}
    ## Dismount a file system.
    ##
    ## \param path Directory path of the mount point. Must be the same as the path specified for the mount.
    ## \retval 0 Dismount succeeded.
    ## \retval -1 Dismount failed. Error codes are indicated by errno.

  proc fsReformat*(path: cstring): cint {.importc: "fs_reformat".}
    ## Reformat the mounted file system
    ##
    ## Reformat a file system mounted at the specified path.
    ##
    ## \param path Directory path of the mount point. Must be the same as the path specified for the mount.
    ## \retval 0 Reformat suceeded.
    ## \retval -1 Reformat failed. Error codes are indicated by errno.

  proc fsInfo*(path: cstring; fs: ptr ptr Filesystem; device: ptr ptr Blockdevice): cint {.importc: "fs_info".}
    ## Lookup filesystem and blockdevice objects from a mount point
    ##
    ## \param path Directory path of the mount point. Must be the same as the path specified for the mount.
    ## \param fs Pointer references to filesystem objects
    ## \param device Pointer references to blockdevice objects
    ## \retval 0 Lookup succeeded
    ## \retval -1 Lookup failed. Error codes are indicated by errno.

  proc fsStrerror*(error: cint): cstring {.importc: "fs_strerror".}
    ## File system error message
    ##
    ## Convert the error code reported in the negative integer into a string.
    ##
    ## \param error Negative error code returned by the file system.
    ## \return Pointer to the corresponding message string.

  {.pop.}


  when defined(pico_filesystem_blockdevice_flash) or defined(pico_filesystem_default) or defined(nimcheck):
    {.compile: picoVfsPath / "src" / "blockdevice" / "flash.c".}
    {.emit: "// picostdlib import: hardware_exception hardware_flash pico_sync pico_flash".}

    {.push header: "blockdevice/flash.h".}

    proc blockdeviceFlashCreate*(start: uint32; length: csize_t): ptr Blockdevice {.importc: "blockdevice_flash_create".}
      ## Create Raspberry Pi Pico On-board Flash block device
      ##
      ## Create a block device object that uses the Raspberry Pi Pico onboard flash memory. The start position of the flash memory to be allocated to the block device is specified by start and the length by length. start and length must be aligned to a flash sector of 4096 bytes.
      ##
      ## \param start Specifies the starting position of the flash memory to be allocated to the block device in bytes.
      ## \param length Size in bytes to be allocated to the block device. If zero is specified, all remaining space is used.
      ## \return Block device object. Returnes NULL in case of failure.
      ## \retval NULL Failed to create block device object.

    proc blockdeviceFlashFree*(device: ptr Blockdevice) {.importc: "blockdevice_flash_free".}
      ## Release the flash memory device.
      ##
      ## \param device Block device object.

    {.pop.}


  when defined(pico_filesystem_blockdevice_heap) or defined(nimcheck):
    {.compile: picoVfsPath / "src" / "blockdevice" / "heap.c".}
    {.emit: "// picostdlib import: pico_sync".}

    {.push header: "blockdevice/heap.h".}

    proc blockdeviceHeapCreate*(size: csize_t): ptr Blockdevice {.importc: "blockdevice_heap_create".}
      ## Create RAM heap memory block device
      ##
      ## Create a block device object that uses RAM heap memory.  The size of heap memory allocated to the block device is specified by size.
      ##
      ## \param size Size in bytes to be allocated to the block device.
      ## \return Block device object. Returnes NULL in case of failure.
      ## \retval NULL Failed to create block device object.

    proc blockdeviceHeapFree*(device: ptr Blockdevice) {.importc: "blockdevice_heap_free".}
      ## Release the heap memory device.
      ##
      ## \param device Block device object.

    {.pop.}


  when defined(pico_filesystem_blockdevice_loopback) or defined(nimcheck):
    {.compile: picoVfsPath / "src" / "blockdevice" / "loopback.c".}
    {.emit: "// picostdlib import: pico_sync".}

    {.push header: "blockdevice/loopback.h".}

    proc blockdeviceLoopbackCreate*(path: cstring; capacity: csize_t; blockSize: csize_t): ptr Blockdevice {.importc: "blockdevice_loopback_create".}
      ## Create loopback block device
      ##
      ## Create a loopback device object that uses a disk image file. Specify the file path allocated to the block device, as well as the maximum size capacity and block size block_size.
      ##
      ## \param path Disk image file path.
      ## \param capacity Maximum device size bytes.
      ## \param block_size Block size byte.
      ## \return Block device object. Returnes NULL in case of failure.
      ## \retval NULL Failed to create block device object.

    proc blockdeviceLoopbackFree*(device: ptr Blockdevice) {.importc: "blockdevice_loopback_free".}
      ## Release the loopback device.
      ##
      ## \param device Block device object.

    {.pop.}


  when defined(pico_filesystem_blockdevice_sd) or defined(nimcheck):
    import ../hardware/spi
    import ../hardware/gpio
    from ../hardware/clocks import MHz
    export spi, gpio
    export MHz
    {.compile: picoVfsPath / "src" / "blockdevice" / "sd.c".}
    {.emit: "// picostdlib import: hardware_spi pico_sync".}

    {.push header: "blockdevice/sd.h".}

    let CONF_SD_INIT_FREQUENCY* {.importc: "CONF_SD_INIT_FREQUENCY".}: cint = 10 * 1000 * 1000
    let CONF_SD_TRX_FREQUENCY* {.importc: "CONF_SD_TRX_FREQUENCY".}: cint = 24 * MHz

    proc blockdeviceSdCreateInt(spi: ptr SpiInst; mosi, miso, sckl, cs: uint8; hz: uint32; enableCrc: bool): ptr Blockdevice {.importc: "blockdevice_sd_create".}
      ## Create SD card block device with SPI
      ##
      ## Create a block device object for an SPI-connected SD or MMC card.
      ##
      ## \param spi_inst SPI instance, as defined in the pico-sdk hardware_spi library
      ## \param mosi SPI Master Out Slave In(TX) pin
      ## \param miso SPI Master In Slave Out(RX) pin
      ## \param sckl SPI clock pin
      ## \param cs SPI Chip select pin
      ## \param hz SPI clock frequency (Hz)
      ## \param enable_crc Boolean value to enable CRC on read/write
      ## \return Block device object. Returnes NULL in case of failure.
      ## \retval NULL Failed to create block device object.

    template blockdeviceSdCreate*(spi: ptr SpiInst; mosi, miso, sckl, cs: Gpio; hz: uint32; enableCrc: bool): ptr Blockdevice =
      blockdeviceSdCreateInt(spi, mosi.uint8, miso.uint8, sckl.uint8, cs.uint8, hz, enableCrc)

    proc blockdeviceSdFree*(device: ptr Blockdevice) {.importc: "blockdevice_sd_free".}
      ## Release the SD card device.
      ##
      ## \param device Block device object.

    {.pop.}


  when defined(pico_filesystem_filesystem_littlefs) or defined(pico_filesystem_default) or defined(nimcheck):
    {.compile: picoVfsPath / "src" / "filesystem" / "littlefs.c".}
    {.compile: picoVfsPath / "vendor" / "littlefs" / "lfs.c".}
    {.compile: picoVfsPath / "vendor" / "littlefs" / "lfs_util.c".}
    {.emit: "// picostdlib include: " & (picoVfsPath / "vendor" / "littlefs").}
    {.emit: "// picostdlib import: pico_sync".}

    {.push header: "filesystem/littlefs.h".}

    proc filesystemLittlefsCreate*(blockCycles: uint32; lookaheadSize: uint32): ptr Filesystem {.importc: "filesystem_littlefs_create".}
      ## Create littlefs file system object
      ##
      ## \param block_cycles Number of erase cycles before littlefs evicts metadata logs and moves the metadata to another block.
      ## \param lookahead_size Threshold for metadata compaction during lfs_fs_gc in bytes.
      ## \return File system object. Returns NULL in case of failure.
      ## \retval NULL failed to create file system object.

    proc filesystemLittlefsFree*(fs: ptr Filesystem) {.importc: "filesystem_littlefs_free".}
      ## Release littlefs file system object
      ##
      ## \param fs littlefs file system object

    {.pop.}

  when defined(pico_filesystem_filesystem_fat) or defined(nimcheck):
    {.compile: picoVfsPath / "src" / "filesystem" / "fat.c".}
    {.compile: picoVfsPath / "vendor" / "ff15" / "source" / "ff.c".}
    {.compile: picoVfsPath / "vendor" / "ff15" / "source" / "ffsystem.c".}
    {.compile: picoVfsPath / "vendor" / "ff15" / "source" / "ffunicode.c".}
    {.emit: "// picostdlib include: " & (picoVfsPath / "vendor" / "ff15" / "source").}
    {.emit: "// picostdlib include: " & (picoVfsPath / "include" / "filesystem" / "ChaN").}
    {.emit: "// picostdlib import: pico_sync".}

    {.push header: "filesystem/fat.h".}

    proc filesystemFatCreate*(): ptr Filesystem {.importc: "filesystem_fat_create".}
      ## Create littlefs file system object
      ##
      ## \param block_cycles Number of erase cycles before littlefs evicts metadata logs and moves the metadata to another block.
      ## \param lookahead_size Threshold for metadata compaction during lfs_fs_gc in bytes.
      ## \return File system object. Returns NULL in case of failure.
      ## \retval NULL failed to create file system object.

    proc filesystemFatFree*(fs: ptr Filesystem) {.importc: "filesystem_fat_free".}
      ## Release littlefs file system object
      ##
      ## \param fs littlefs file system object

    {.pop.}


  # old workaround
  #{.emit: "#define lstat stat".}
  # proc lstat(path: cstring; buf: var Stat): cint {.exportc.} = stat(path, buf)
  iterator fsWalkDir*(directory: string): tuple[kind: DirectoryType, name: string] =
    var dirent: ptr Dirent
    var dir = opendir(directory.cstring)
    assert(not dir.isNil)
    defer: assert(closedir(dir) == 0)
    while (dirent = readdir(dir); not dirent.isNil):
      yield (
        kind: cast[DirectoryType](dirent.d_type),
        name: $cast[cstring](dirent.d_name[0].addr)
      )
