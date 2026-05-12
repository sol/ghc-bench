# Benchmark a Haskell development system

## Benchmark results

| CPU | [GHC 9.12.4 build](src/Benchmark/BuildGhc.hs) | [hedgehog-1.7-dependencies](src/Benchmark/BuildCabalPackage.hs) | [hedgehog-1.7-build](src/Benchmark/BuildCabalPackage.hs) | [containers-0.8-ghci](src/Benchmark/Ghci.hs) |
| --- | --- | --- | --- | --- |
| [Intel Core Ultra 9 285K](results/intel/core_ultra_series_2/285K) | 388s (6m28s) | 17s | 10s | 4s |
| [Intel Core Ultra 7 255H](results/intel/unknown/Intel(R)_Core(TM)_Ultra_7_255H) | 428s (7m8s) | 23s | 11s | 4s |
| [Intel Core Ultra 7 255H](results/intel/unknown/Intel(R)_Core(TM)_Ultra_7_255H) | 437s (7m17s) | 23s | 11s | 4s |
| [Intel Core i9-10900K](results/intel/10th/i9-10900K) | 524s (8m44s) | 28s | 13s | 5s |
| [Intel Core i9-10900K](results/intel/10th/i9-10900K) (vm) | 588s (9m48s) | 29s | 15s | 6s |
| [AMD EPYC-Genoa](results/amd/unknown/AMD_EPYC-Genoa_Processor) (vm) | 661s (11m1s) | 27s | 21s | 7s |
| [Intel Core i7-1165G7](results/intel/11th/i7-1165G7) | 715s (11m55s) | - | - | - |
| [AMD Ryzen 5 5600X](results/unknown/unknown/AMD_Ryzen_5_5600X) | 730s (12m10s) | 35s | 16s | 7s |
| [AMD Ryzen 9 9900X3D](results/amd/unknown/AMD_Ryzen_9_9900X3D_12-Core_Processor_(6_Cores_through_Virtualbox)) (vm) | 754s (12m34s) | 33s | 15s | 5s |
| [Intel Core i7-9700](results/intel/9th/i7-9700) (WSL2) | 924s (15m24s) | 49s | 23s | 7s |
| [Intel Core Ultra 7 258V](results/intel/lunar/258V) (WSL2) | 995s (16m35s) | 60s | 18s | 7s |
| [Intel Core i5-3230M](results/intel/unknown/Intel(R)_Core(TM)_i5-3230M_CPU_@_2.60GHz) | 1879s (31m19s) | 112s (1m52s) | 33s | 12s |
| [Intel Core 2 Duo P8700](results/intel/core_2/P8700) | 3013s (50m13s) | - | - | - |

## About
`ghc-bench` measures how well a system performs on Haskell development workloads compared to other systems.

It allows you to:
- benchmark a system
- submit benchmark results via GitHub issues
- compare benchmark results across systems

This can be used to:
- verify that a system delivers expected performance
- understand the impact of a hardware upgrade
- guide purchasing decisions

## Workloads

I'm interested in the following workloads:

- Building GHC
- Building a Cabal project
- Loading a project into `ghci`

## Running `ghc-bench`

NOTE: If you are on Windows, you can run `ghc-bench` from a bootable USB drive (see next section).

Requirements:

- `cabal`
- `ghc-9.12.4`
- `ghc-bench`

If all of these are on your `PATH` you can benchmark your system with:

```console
$ ghc-bench
```

If you want to know about other options or need detailed instructions then read on.

### Running `ghc-bench` from a bootable USB drive

**Advantage**

- provides a consistent environment for benchmarking
- does not require network connectivity; results are submitted via a QR code
- based on [`archiso`](https://wiki.archlinux.org/title/Archiso) (see the corresponding [GiHub Actions workflow](https://github.com/sol/ghc-bench/blob/iso-image/.github/workflows/mkarchiso.yml))

**Steps**

Download
https://github.com/sol/ghc-bench/releases/download/live-iso-image/ghc-bench-live-latest-x86_64.iso and [prepare a bootable USB drive](https://github.com/sol/ghc-bench/wiki/Preparing-a-bootable-USB-drive).

After booting into the live environment:

1. First use `--dry-run` and make sure that you can submit results via the generated QR code:
   ```bash
   ghc-bench --qr --dry-run
   ```
   (make sure that the whole QR code fits on your screen and that you have a device that is capable of opening the corresponding URL)
1. Run `ghc-bench`
   ```bash
   ghc-bench --qr
   ```
1. Submit the result by scanning the generated QR code and opening the corresponding GitHub issue URL (if you are prompted to select an issue template, select "Benchmark result", this might happen if you are using the GitHub mobile app)

### Running `ghc-bench` with `ghcup`

Install `cabal`, `ghc-9.12.4`, and `ghc-bench`:
```console
$ ghcup install cabal
$ ghcup install ghc 9.12.4 --no-set
$ cabal update && cabal install -w ghc-9.12.4 ghc-bench
```

Run `ghc-bench`:
```console
$ ghc-bench
```

### Running `ghc-bench` with `stack`

Install `cabal` and `ghc-bench`:
```console
$ stack --resolver=nightly-2026-04-11 install cabal-install
$ cabal update && stack --resolver=nightly-2026-04-11 exec --no-ghc-package-path -- cabal install ghc-bench
```

Run `ghc-bench`:
```console
$ stack --resolver=nightly-2026-04-11 exec --no-ghc-package-path -- ghc-bench
```

## Submitting a benchmark result

`ghc-bench` never submits results on its own.

Upon completion, it generates a URL that pre-fills a GitHub issue.

To submit a benchmark result, follow these two steps:

1. Open the generated URL
1. Submit the GitHub issue

Benchmark results are then processed by a GitHub Action.

## Details

Running `ghc-bench` requires ~3.4G free space in `/tmp/`.

- `ghc-bench` creates a separate temporary directory for each benchmark run under `/tmp/ghc-bench` and always cleans up after itself.
- The GHC 9.12.4 source tarball is stored at `~/.cache/ghc-bench/ghc-9.12.4-src.tar.gz` and reused between benchmark runs.
- `cabal` is used to build Hadrian (the GHC build system)
  - any missing Hadrian dependencies are installed to `~/.local/state/cabal/store`;
    apart from the GHC tarball, this is the only other situation where running `ghc-bench` may modify anything outside of `/tmp/ghc-bench`

Exact steps performed by `ghc-bench`:

1. Download the GHC 9.12.4 source tarball to `~/.cache/ghc-bench/ghc-9.12.4-src.tar.gz`
1. Unpack GHC sources into a temporary directory under `/tmp/ghc-bench`
1. Set the environment variable `GHC` to the absolute path of `ghc-9.12.4`
1. Run `./configure`
1. Build Hadrian (not measured as part of the benchmark) by invoking `hadrian/build --help` to trigger dependency compilation
1. Run `hadrian/build -j$(nproc) --flavour=quickest`

**Auditing**
- [Auditing `ghc-bench`](https://github.com/sol/ghc-bench/wiki/Auditing-ghc%E2%80%90bench)
- [Build Verification and Trust Model for the Live ISO Image](https://github.com/sol/ghc-bench/wiki/Build-Verification-and-Trust-Model-for-the-Live-ISO-Image)
