# Benchmark a Haskell development system

## Benchmark results

| CPU | building GHC 9.12.4 with `--flavour=quickest` |
| --- | --- |
| Intel Core Ultra 7 270K Plus | (no results yet) |
| Intel Core Ultra 7 255H | (no results yet) |
| Intel Core Ultra 7 258V | (no results yet) |
| Intel Core i9-10900K | 526s (8m 46s) |
| Intel Core i7-1165G7 | 715s (11m 55s) |
| Intel Core 2 Duo P8700 | 3013s (50m 13s) |

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

## Running `ghc-bench`

Requirements:

- `cabal`
- `ghc-9.12.4`
- `ghc-bench`

If all of these are on your `PATH` you can benchmark your system with:

```console
$ ghc-bench
```

If you need detailed instructions for `ghcup` or `stack` then read on.

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
$ cabal update && stack --resolver=nightly-2026-04-11 exec -- env --unset=GHC_PACKAGE_PATH cabal install ghc-bench
```

Run `ghc-bench`:
```console
$ stack --resolver=nightly-2026-04-11 exec -- env --unset=GHC_PACKAGE_PATH ghc-bench
```

## Details

Running `ghc-bench` requires ~3.4G free space in `/tmp/`.

- `ghc-bench` creates a separate temporary directory for each benchmark run under `/tmp/ghc-bench` and always cleans up after itself.
- The GHC 9.12.4 source tarball is stored at `/tmp/ghc-bench/ghc-9.12.4-src.tar.gz` and reused between benchmark runs (and users).
- `cabal` is used to build Hadrian (the GHC build system)
  - any missing Hadrian dependencies are installed to `~/.local/state/cabal/store`;
    this is the only situation where running `ghc-bench` may modify anything outside of `/tmp/ghc-bench`

Exact steps performed by `ghc-bench`:

1. Download the GHC 9.12.4 source tarball to `/tmp/ghc-bench/ghc-9.12.4-src.tar.gz`
1. Unpack GHC sources into a temporary directory under `/tmp/ghc-bench`
1. Set the environment variable `GHC` to the absolute path of `ghc-9.12.4`
1. Run `./configure`
1. Build Hadrian (not measured as part of the benchmark) by invoking `hadrian/build --help` to trigger dependency compilation
1. Run `hadrian/build -j$(nproc) --flavour=quickest`
