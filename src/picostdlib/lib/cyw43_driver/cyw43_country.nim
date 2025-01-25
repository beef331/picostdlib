##
##  This file is part of the cyw43-driver
##
##  Copyright (C) 2019-2022 George Robotics Pty Ltd
##
##  Redistribution and use in source and binary forms, with or without
##  modification, are permitted provided that the following conditions are met:
##
##  1. Redistributions of source code must retain the above copyright notice,
##     this list of conditions and the following disclaimer.
##  2. Redistributions in binary form must reproduce the above copyright notice,
##     this list of conditions and the following disclaimer in the documentation
##     and/or other materials provided with the distribution.
##  3. Any redistribution, use, or modification in source or binary form is done
##     solely for personal benefit and not for any commercial purpose or for
##     monetary gain.
##
##  THIS SOFTWARE IS PROVIDED BY THE LICENSOR AND COPYRIGHT OWNER "AS IS" AND ANY
##  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
##  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
##  DISCLAIMED. IN NO EVENT SHALL THE LICENSOR OR COPYRIGHT OWNER BE LIABLE FOR
##  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
##  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
##  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
##  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
##  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
##  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
##  This software is also available for use with certain devices under different
##  terms, as set out in the top level LICENSE file.  For commercial licensing
##  options please email contact@georgerobotics.com.au.
##

## * \addtogroup cyw43_driver
##

## *
##   \file cyw43_country.h
## CYW43 country codes
##

type
  Cyw43Country* = distinct uint32

proc `==`*(a, b: Cyw43Country): bool {.borrow.}
proc `$`*(a: Cyw43Country): string {.borrow.}

template cyw43Country*(a, b: char; rev: int): Cyw43Country =
  ##  create a country code from the two character country and revision number
  (a.uint8 or (b.uint8 shl 8) or (rev shl 16)).Cyw43Country

## !
##  \name Country codes
##  \anchor CYW43_COUNTRY_
##
## !\{


const
  CYW43_COUNTRY_WORLDWIDE* = cyw43Country('X', 'X', 0)
    ## Worldwide Locale (passive Ch12-14)

  CYW43_COUNTRY_AUSTRALIA*         = cyw43Country('A', 'U', 0)
  CYW43_COUNTRY_AUSTRIA*           = cyw43Country('A', 'T', 0)
  CYW43_COUNTRY_BELGIUM*           = cyw43Country('B', 'E', 0)
  CYW43_COUNTRY_BRAZIL*            = cyw43Country('B', 'R', 0)
  CYW43_COUNTRY_CANADA*            = cyw43Country('C', 'A', 0)
  CYW43_COUNTRY_CHILE*             = cyw43Country('C', 'L', 0)
  CYW43_COUNTRY_CHINA*             = cyw43Country('C', 'N', 0)
  CYW43_COUNTRY_COLOMBIA*          = cyw43Country('C', 'O', 0)
  CYW43_COUNTRY_CZECH_REPUBLIC*    = cyw43Country('C', 'Z', 0)
  CYW43_COUNTRY_DENMARK*           = cyw43Country('D', 'K', 0)
  CYW43_COUNTRY_ESTONIA*           = cyw43Country('E', 'E', 0)
  CYW43_COUNTRY_FINLAND*           = cyw43Country('F', 'I', 0)
  CYW43_COUNTRY_FRANCE*            = cyw43Country('F', 'R', 0)
  CYW43_COUNTRY_GERMANY*           = cyw43Country('D', 'E', 0)
  CYW43_COUNTRY_GREECE*            = cyw43Country('G', 'R', 0)
  CYW43_COUNTRY_HONG_KONG*         = cyw43Country('H', 'K', 0)
  CYW43_COUNTRY_HUNGARY*           = cyw43Country('H', 'U', 0)
  CYW43_COUNTRY_ICELAND*           = cyw43Country('I', 'S', 0)
  CYW43_COUNTRY_INDIA*             = cyw43Country('I', 'N', 0)
  CYW43_COUNTRY_ISRAEL*            = cyw43Country('I', 'L', 0)
  CYW43_COUNTRY_ITALY*             = cyw43Country('I', 'T', 0)
  CYW43_COUNTRY_JAPAN*             = cyw43Country('J', 'P', 0)
  CYW43_COUNTRY_KENYA*             = cyw43Country('K', 'E', 0)
  CYW43_COUNTRY_LATVIA*            = cyw43Country('L', 'V', 0)
  CYW43_COUNTRY_LIECHTENSTEIN*     = cyw43Country('L', 'I', 0)
  CYW43_COUNTRY_LITHUANIA*         = cyw43Country('L', 'T', 0)
  CYW43_COUNTRY_LUXEMBOURG*        = cyw43Country('L', 'U', 0)
  CYW43_COUNTRY_MALAYSIA*          = cyw43Country('M', 'Y', 0)
  CYW43_COUNTRY_MALTA*             = cyw43Country('M', 'T', 0)
  CYW43_COUNTRY_MEXICO*            = cyw43Country('M', 'X', 0)
  CYW43_COUNTRY_NETHERLANDS*       = cyw43Country('N', 'L', 0)
  CYW43_COUNTRY_NEW_ZEALAND*       = cyw43Country('N', 'Z', 0)
  CYW43_COUNTRY_NIGERIA*           = cyw43Country('N', 'G', 0)
  CYW43_COUNTRY_NORWAY*            = cyw43Country('N', 'O', 0)
  CYW43_COUNTRY_PERU*              = cyw43Country('P', 'E', 0)
  CYW43_COUNTRY_PHILIPPINES*       = cyw43Country('P', 'H', 0)
  CYW43_COUNTRY_POLAND*            = cyw43Country('P', 'L', 0)
  CYW43_COUNTRY_PORTUGAL*          = cyw43Country('P', 'T', 0)
  CYW43_COUNTRY_SINGAPORE*         = cyw43Country('S', 'G', 0)
  CYW43_COUNTRY_SLOVAKIA*          = cyw43Country('S', 'K', 0)
  CYW43_COUNTRY_SLOVENIA*          = cyw43Country('S', 'I', 0)
  CYW43_COUNTRY_SOUTH_AFRICA*      = cyw43Country('Z', 'A', 0)
  CYW43_COUNTRY_SOUTH_KOREA*       = cyw43Country('K', 'R', 0)
  CYW43_COUNTRY_SPAIN*             = cyw43Country('E', 'S', 0)
  CYW43_COUNTRY_SWEDEN*            = cyw43Country('S', 'E', 0)
  CYW43_COUNTRY_SWITZERLAND*       = cyw43Country('C', 'H', 0)
  CYW43_COUNTRY_TAIWAN*            = cyw43Country('T', 'W', 0)
  CYW43_COUNTRY_THAILAND*          = cyw43Country('T', 'H', 0)
  CYW43_COUNTRY_TURKEY*            = cyw43Country('T', 'R', 0)
  CYW43_COUNTRY_UK*                = cyw43Country('G', 'B', 0)
  CYW43_COUNTRY_USA*               = cyw43Country('U', 'S', 0)
