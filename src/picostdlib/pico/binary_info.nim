import std/macros

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_binary_info/include".}

type
  BinaryInfoBlockDevConfigFlag* = enum
    FlagRead
    FlagWrite
    FlagReformat
    FlagPtUnknown
    FlagPtMbr
    FlagPtGpt
    FlagPtNone

template bi_decl_include*() = {.emit: "#include \"pico/binary_info.h\"".}

macro bi_decl*(input: untyped) =
  result = newStmtList()
  let p = newNimNode(nnkPragma)
  result.add p
  let b = newNimNode(nnkBracket)
  let ece = newColonExpr(ident("emit"), b)
  p.add ece
  for i, item in input:
    if i == 0:
      b.add newStrLitNode("bi_decl(" & item.repr & "(")
    else:
      b.add item
      if i < input.len - 1:
        b.add newStrLitNode(", ")
  b.add newStrLitNode("));")

{.push header: "pico/binary_info.h".}

let
  BinaryInfoMarkerStart* {.importc: "BINARY_INFO_MARKER_START".}: uint32
  BinaryInfoMarkerEnd* {.importc: "BINARY_INFO_MARKER_END".}: uint32

template BINARY_INFO_MAKE_TAG*(c1, c2: static[char]): static[uint] = static (((c2.uint and 0xff) shl 8) or (c1.uint and 0xff))

#[
import ../hardware/gpio

type
  BinaryInfo* {.importc: "binary_info_t".} = object

  BinaryInfoType* {.pure.} = enum
    RawData = 1
    SizedData = 2
    BinaryInfoListZeroTerminated = 3
    Bson = 4
    IdAndInt = 5
    IdAndString = 6
    BlockDevice = 7 # traditional block device
    PinsWithFunc = 8
    PinsWithName = 9
    NamedGroup = 10

const PinsWithNames* = BinaryInfoType.PinsWithName

let
  BINARY_INFO_ID_RP_PROGRAM_NAME* {.importc: "BINARY_INFO_ID_RP_PROGRAM_NAME".}: uint
  BINARY_INFO_ID_RP_PROGRAM_VERSION_STRING* {.importc: "BINARY_INFO_ID_RP_PROGRAM_VERSION_STRING".}: uint
  BINARY_INFO_ID_RP_PROGRAM_BUILD_DATE_STRING* {.importc: "BINARY_INFO_ID_RP_PROGRAM_BUILD_DATE_STRING".}: uint
  BINARY_INFO_ID_RP_BINARY_END* {.importc: "BINARY_INFO_ID_RP_BINARY_END".}: uint
  BINARY_INFO_ID_RP_PROGRAM_URL* {.importc: "BINARY_INFO_ID_RP_PROGRAM_URL".}: uint
  BINARY_INFO_ID_RP_PROGRAM_DESCRIPTION* {.importc: "BINARY_INFO_ID_RP_PROGRAM_DESCRIPTION".}: uint
  BINARY_INFO_ID_RP_PROGRAM_FEATURE* {.importc: "BINARY_INFO_ID_RP_PROGRAM_FEATURE".}: uint
  BINARY_INFO_ID_RP_PROGRAM_BUILD_ATTRIBUTE* {.importc: "BINARY_INFO_ID_RP_PROGRAM_BUILD_ATTRIBUTE".}: uint
  BINARY_INFO_ID_RP_SDK_VERSION* {.importc: "BINARY_INFO_ID_RP_SDK_VERSION".}: uint
  BINARY_INFO_ID_RP_PICO_BOARD* {.importc: "BINARY_INFO_ID_RP_PICO_BOARD".}: uint
  BINARY_INFO_ID_RP_BOOT2_NAME* {.importc: "BINARY_INFO_ID_RP_BOOT2_NAME".}: uint

type
  binary_info_core_t* {.importc: "binary_info_core_t".} = object
    `type`*: uint16
    tag*: uint16

  binary_info_raw_data_t* {.importc: "binary_info_raw_data_t".} = object
    core*: binary_info_core_t
    bytes*: array[1, uint8]

  binary_info_sized_data_t* {.importc: "binary_info_sized_data_t".} = object
    core*: binary_info_core_t
    length*: uint32
    bytes*: array[1, uint8]

  binary_info_list_zero_terminated_t* {.importc: "binary_info_list_zero_terminated_t".} = object
    core*: binary_info_core_t
    list*: ptr BinaryInfo

  binary_info_id_and_int_t* {.importc: "binary_info_id_and_int_t".} = object
    core*: binary_info_core_t
    id*: uint32
    value*: int32

  binary_info_id_and_string_t* {.importc: "binary_info_id_and_string_t".} = object
    core*: binary_info_core_t
    id*: uint32
    value*: cstring

  binary_info_block_device_t* {.importc: "binary_info_block_device_t".} = object
    core*: binary_info_core_t
    name*: cstring
    address*: uint32
    size*: uint32
    extra*: ptr BinaryInfo
    flags*: uint16

  binary_info_pins_with_func_t* {.importc: "binary_info_pins_with_func_t".} = object
    core*: binary_info_core_t
    pin_encoding*: uint32

  binary_info_pins_with_name_t* {.importc: "binary_info_pins_with_name_t".} = object
    core*: binary_info_core_t
    pin_mask*: uint32
    label*: cstring

  binary_info_named_group_t* {.importc: "binary_info_named_group_t".} = object
    core*: binary_info_core_t
    parent_id*: uint32
    flags*: uint16
    group_tag*: uint16
    group_id*: uint32
    label*: cstring

  BinaryInfoBlockDevFlag* {.pure.} = enum
    Read = 1 shl 0
    Write = 1 shl 1
    Reformat = 1 shl 2

  BinaryInfoBlockDevFlagPt* {.pure.} = enum
    Unknown = 0 shl 4
    Mbr = 1 shl 4
    Gpt = 2 shl 4
    None = 3 shl 4

# note plan is to reserve c1 = 0->31 for "collision tags"; i.e.
# for which you should always use random IDs with the binary_info,
# giving you 4 + 8 + 32 = 44 bits to avoid collisions
proc binaryInfoMakeTag*(c1, c2: char): uint16 =
  ((c2.uint16 and 0xff) shl 8) or (c1.uint16 and 0xff)

# template bi_decl*(body: untyped): untyped =
#   echo body

#proc bi_decl_if_func_used*(decl) {.importc: "bi_decl_if_func_used".}

proc bi_program_name*(name: cstring) {.importc: "bi_program_name".}
proc bi_program_description*(description: cstring) {.importc: "bi_program_description".}
proc bi_program_version_string*(versionString: cstring) {.importc: "bi_program_version_string".}
proc bi_program_build_date_string*(dateString: cstring) {.importc: "bi_program_build_date_string".}
proc bi_program_url*(url: cstring) {.importc: "bi_program_url".}

# multiple of these may be added
proc bi_program_feature*(feature: cstring) {.importc: "bi_program_feature".}
proc bi_program_build_attribute*(attr: cstring) {.importc: "bi_program_build_attribute".}
proc bi_program_feature_group*(tag, id, name: cstring) {.importc: "bi_program_feature_group".}
proc bi_program_feature_group_with_flags*(tag, id, name, flags: cstring) {.importc: "bi_program_feature_group_with_flags".}

proc bi_1pin_with_func*(p0: Gpio; function: GpioFunction) {.importc: "bi_1pin_with_func".}
proc bi_2pins_with_func*(p0, p1: Gpio; function: GpioFunction) {.importc: "bi_2pins_with_func".}
proc bi_3pins_with_func*(p0, p1, p2: Gpio; function: GpioFunction) {.importc: "bi_3pins_with_func".}
proc bi_4pins_with_func*(p0, p1, p2, p3: Gpio; function: GpioFunction) {.importc: "bi_4pins_with_func".}
proc bi_5pins_with_func*(p0, p1, p2, p3, p4: Gpio; function: GpioFunction) {.importc: "bi_5pins_with_func".}
proc bi_pin_range_with_func*(plo, phi: Gpio; function: GpioFunction) {.importc: "bi_pin_range_with_func".}

proc bi_pin_mask_with_name*(pmask: cuint; label: cstring) {.importc: "bi_pin_mask_with_name".}
# names are separated by | ... i.e. "name1|name2|name3"
proc bi_pin_mask_with_names*(pmask: cuint; label: cstring) {.importc: "bi_pin_mask_with_names".}
proc bi_1pin_with_name*(p0: Gpio; name: cstring) {.importc: "bi_1pin_with_name".}
proc bi_2pins_with_names*(p0: Gpio; name0: cstring; p1: Gpio; name1: cstring) {.importc: "bi_2pins_with_names".}
proc bi_3pins_with_names*(p0: Gpio; name0: cstring; p1: Gpio; name1: cstring; p2: Gpio; name2: cstring) {.importc: "bi_3pins_with_names".}
proc bi_4pins_with_names*(p0: Gpio; name0: cstring; p1: Gpio; name1: cstring; p2: Gpio; name2: cstring; p3: Gpio; name3: cstring) {.importc: "bi_4pins_with_names".}


]#

{.pop.}
