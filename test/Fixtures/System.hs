module Fixtures.System where

import Imports

import SystemInfo

i10900K_desktop :: SystemInfo
i10900K_desktop = SystemInfo {
    os = "Arch Linux"
  , arch = "x86_64"
  , vendor = "To Be Filled By O.E.M."
  , product = Product {
      category = "desktop"
    , chassis_type = "3"
    , family = "To Be Filled By O.E.M."
    , name = "To Be Filled By O.E.M."
    , version = "To Be Filled By O.E.M."
    }
  , board = Board {
      vendor = "ASRock"
    , name = "Z490M-ITX/ac"
    }
  , cpu = Cpu {
      name = "Intel(R) Core(TM) i9-10900K CPU @ 3.70GHz"
    , cores = 10
    , threads = 20
    , vendor = Just "GenuineIntel"
    , family = Just "6"
    , model = Just "165"
    , stepping = Just "5"
    }
  , ram = "33273524224"
  }

x200 :: SystemInfo
x200 = SystemInfo {
    os = "Debian GNU/Linux"
  , arch = "x86_64"
  , vendor = "LENOVO"
  , product = Product {
      category = "laptop"
    , chassis_type = "10"
    , family = "ThinkPad X200"
    , name = "7455D7G"
    , version = "ThinkPad X200"
    }
  , board = Board {
      vendor = "LENOVO"
    , name = "7455D7G"
    }
  , cpu = Cpu {
      name = "Intel(R) Core(TM)2 Duo CPU     P8700  @ 2.53GHz"
    , cores = 2
    , threads = 2
    , vendor = Just "GenuineIntel"
    , family = Just "6"
    , model = Just "23"
    , stepping = Just "10"
    }
  , ram = "3997212672"
  }

dell_xps :: SystemInfo
dell_xps = SystemInfo {
    os = "Arch Linux"
  , arch = "x86_64"
  , vendor = "Dell Inc."
  , product = Product {
      category = "laptop"
    , chassis_type = "10"
    , family = "XPS"
    , name = "XPS 13 9310"
    , version = ""
    }
  , board = Board {
      vendor = "Dell Inc."
    , name = "0GG9PT"
    }
  , cpu = Cpu {
      name = "11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz"
    , cores = 4
    , threads = 8
    , vendor = Just "GenuineIntel"
    , family = Just "6"
    , model = Just "140"
    , stepping = Just "1"
    }
  , ram = "16461537280"
  }
