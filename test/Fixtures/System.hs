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

t60_ThinkPad :: SystemInfo
t60_ThinkPad = SystemInfo {
    os = "Arch Linux"
  , arch = "x86_64"
  , vendor = "LENOVO"
  , product = Product {
      category = "laptop"
    , chassis_type = "10"
    , family = "ThinkPad T60"
    , name = "1952W5R"
    , version = "ThinkPad T60"
    }
  , board = Board {
      vendor = "LENOVO"
    , name = "1952W5R"
    }
  , cpu = Cpu {
      name = "Intel(R) Core(TM) 2 Duo Processor T7200 @ 2.00GHz"
    , cores = 2
    , threads = 2
    , vendor = Just "GenuineIntel"
    , family = Just "6"
    , model = Just "15"
    , stepping = Just "6"
    }
  , ram = "0"
  }
