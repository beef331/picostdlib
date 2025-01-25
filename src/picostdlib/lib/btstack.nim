##
## “BlueKitchen” shall refer to BlueKitchen GmbH.
## “Raspberry Pi” shall refer to Raspberry Pi Ltd.
## “Product” shall refer to Raspberry Pi hardware products Raspberry Pi Pico W or Raspberry Pi Pico WH.
## “Customer” means any purchaser of a Product.
## “Customer Products” means products manufactured or distributed by Customers which use or are derived from Products.
##
## Raspberry Pi grants to the Customer a non-exclusive, non-transferable, non-sublicensable, irrevocable, perpetual
## and worldwide licence to use, copy, store, develop, modify, and transmit BTstack in order to use BTstack with or
## integrate BTstack into Products or Customer Products, and distribute BTstack as part of these Products or
## Customer Products or their related documentation or SDKs.
##
## All use of BTstack by the Customer is limited to Products or Customer Products, and the Customer represents and
## warrants that all such use shall be in compliance with the terms of this licence and all applicable laws and
## regulations, including but not limited to, copyright and other intellectual property laws and privacy regulations.
##
## BlueKitchen retains all rights, title and interest in, to and associated with BTstack and associated websites.
## Customer shall not take any action inconsistent with BlueKitchen’s ownership of BTstack, any associated services,
## websites and related content.
##
## There are no implied licences under the terms set forth in this licence, and any rights not expressly granted
## hereunder are reserved by BlueKitchen.
##
## BTSTACK IS PROVIDED BY RASPBERRY PI "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
## THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED TO THE FULLEST EXTENT
## PERMISSIBLE UNDER APPLICABLE LAW. IN NO EVENT SHALL RASPBERRY PI OR BLUEKITCHEN BE LIABLE FOR ANY DIRECT, INDIRECT,
## INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
## GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
## LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
## OUT OF THE USE OF BTSTACK, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
{.hint[XDeclaredButNotUsed]: off.}
{.hint[User]: off.}

import std/os, std/macros
import ../helpers

import futhark

importc:
  compilerArg "--target=arm-none-eabi"
  compilerArg "-mthumb"
  compilerArg "-mcpu=cortex-m0plus"
  compilerArg "-fsigned-char"

  sysPath armSysrootInclude
  sysPath armInstallInclude
  sysPath picoSdkPath / "lib/btstack/src"
  sysPath picoSdkPath / "lib/btstack/3rd-party/lc3-google/include"
  sysPath picoSdkPath / "lib/btstack/3rd-party/bluedroid/decoder/include"
  sysPath picoSdkPath / "lib/btstack/3rd-party/bluedroid/encoder/include"
  path piconimCsourceDir
  path getProjectPath()

  renameCallback futharkRenameCallback

  "ad_parser.h"
  "bluetooth_company_id.h"
  "bluetooth_data_types.h"
  "bluetooth_gatt.h"
  "bluetooth.h"
  "bluetooth_psm.h"
  "bluetooth_sdp.h"
  "btstack_audio.h"
  "btstack_base64_decoder.h"
  "btstack_bool.h"
  "btstack_chipset.h"
  "btstack_control.h"
  "btstack_crypto.h"
  "btstack_debug.h"
  "btstack_defines.h"
  "btstack_em9304_spi.h"
  "btstack_event.h"
  "btstack.h"
  "btstack_hid.h"
  "btstack_hid_parser.h"
  "btstack_lc3_google.h"
  "btstack_lc3.h"
  "btstack_linked_list.h"
  "btstack_linked_queue.h"
  "btstack_memory.h"
  "btstack_memory_pool.h"
  "btstack_network.h"
  "btstack_resample.h"
  "btstack_ring_buffer.h"
  "btstack_run_loop_base.h"
  "btstack_run_loop.h"
  "btstack_sample_rate_compensation.h"
  "btstack_sco_transport.h"
  "btstack_slip.h"
  "btstack_stdin.h"
  "btstack_tlv.h"
  "btstack_tlv_none.h"
  "btstack_uart_block.h"
  "btstack_uart.h"
  "btstack_uart_slip_wrapper.h"
  "btstack_util.h"

  "gap.h"
  "hci_cmd.h"
  "hci_dump.h"
  "hci.h"
  "hci_transport_em9304_spi.h"
  "hci_transport.h"
  "hci_transport_h4.h"
  "hci_transport_h5.h"
  "hci_transport_usb.h"
  "l2cap.h"
  "l2cap_signaling.h"



