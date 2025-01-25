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

import ./btstack
export btstack

importc:
  compilerArg "--target=arm-none-eabi"
  compilerArg "-mthumb"
  compilerArg "-mcpu=cortex-m0plus"
  compilerArg "-fsigned-char"

  sysPath armSysrootInclude
  sysPath armInstallInclude
  sysPath picoSdkPath / "lib/btstack/src"
  sysPath picoSdkPath / "lib/btstack/3rd-party/bluedroid/decoder/include"
  sysPath picoSdkPath / "lib/btstack/3rd-party/bluedroid/encoder/include"
  sysPath piconimCsourceDir
  sysPath getProjectPath()

  renameCallback futharkRenameCallback

  "classic/a2dp.h"
  "classic/a2dp_sink.h"
  "classic/a2dp_source.h"
  "classic/avdtp_acceptor.h"
  "classic/avdtp.h"
  "classic/avdtp_initiator.h"
  "classic/avdtp_sink.h"
  "classic/avdtp_source.h"
  "classic/avdtp_util.h"
  "classic/avrcp_browsing_controller.h"
  "classic/avrcp_browsing.h"
  "classic/avrcp_browsing_target.h"
  "classic/avrcp_controller.h"
  "classic/avrcp_cover_art_client.h"
  "classic/avrcp.h"
  "classic/avrcp_media_item_iterator.h"
  "classic/avrcp_target.h"
  "classic/bnep.h"
  "classic/btstack_cvsd_plc.h"
  "classic/btstack_link_key_db.h"
  "classic/btstack_link_key_db_memory.h"
  "classic/btstack_link_key_db_static.h"
  "classic/btstack_link_key_db_tlv.h"
  "classic/btstack_sbc_bluedroid.h"
  "classic/btstack_sbc.h"
  "classic/btstack_sbc_plc.h"
  "classic/core.h"
  "classic/device_id_server.h"
  "classic/gatt_sdp.h"
  "classic/goep_client.h"
  "classic/goep_server.h"
  "classic/hfp_ag.h"
  "classic/hfp_codec.h"
  "classic/hfp_gsm_model.h"
  "classic/hfp.h"
  "classic/hfp_hf.h"
  "classic/hfp_msbc.h"
  "classic/hid_device.h"
  "classic/hid_host.h"
  "classic/hsp_ag.h"
  "classic/hsp_hs.h"
  "classic/obex.h"
  "classic/obex_iterator.h"
  "classic/obex_message_builder.h"
  "classic/obex_parser.h"
  "classic/pan.h"
  "classic/pbap_client.h"
  "classic/pbap.h"
  "classic/rfcomm.h"
  "classic/sdp_client.h"
  "classic/sdp_client_rfcomm.h"
  "classic/sdp_server.h"
  "classic/sdp_util.h"
  "classic/spp_server.h"