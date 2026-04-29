.PHONY: run iso clean

SRC := ${CURDIR}
OUT := /tmp/ghc-bench/live
ISO := $(OUT)/out/ghc-bench-live-latest-x86_64.iso
RUN := qemu-system-x86_64 \
  -machine q35 \
  -enable-kvm \
  -cpu host \
  -smp 10 \
  -m 24G \
  -device virtio-vga \
  -display gtk,gl=on \
  -cdrom "$(ISO)"

LOCAL_REPO_DIR := $(OUT)/pacman
LOCAL_REPO := $(LOCAL_REPO_DIR)/custom.db.tar.zst
GHC_BIN := $(LOCAL_REPO_DIR)/ghc-bin-9.12.4-1-x86_64.pkg.tar.zst
BUILD := $(LOCAL_REPO_DIR)/build

BIN_DIR := airootfs/usr/local/bin
CABAL_BIN := $(BIN_DIR)/cabal
GHC_BENCH_BIN := $(BIN_DIR)/ghc-bench

USER_CACHE_DIRS := airootfs/root/.cache/cabal airootfs/root/.cache/ghc-bench

CABAL_INSTALL := cabal install -z --installdir=$(BIN_DIR) --install-method=copy --overwrite-policy=always

run: $(ISO)
	$(RUN) -nic none

iso:
	sudo rm -f "$(ISO)"
	make "$(ISO)"

$(ISO): $(CABAL_BIN) $(GHC_BENCH_BIN) $(LOCAL_REPO) $(USER_CACHE_DIRS)
	mkdir -p "$(OUT)"
	cd "$(OUT)" && sudo mkarchiso -v -r "$(SRC)"

$(USER_CACHE_DIRS): $(CABAL_BIN) $(GHC_BENCH_BIN)
	rm -f airootfs/root/.config/cabal/config
	HOME=$(SRC)/airootfs/root $(CABAL_BIN) update
	HOME=$(SRC)/airootfs/root $(GHC_BENCH_BIN) --prepare
	sed -i 's/\/home\/.*\/airootfs//' airootfs/root/.config/cabal/config
	rm -r airootfs/root/.local/state/cabal/store/
	rm -r airootfs/root/.cache/cabal/logs/

$(CABAL_BIN):
	$(CABAL_INSTALL) cabal-install

$(GHC_BENCH_BIN):
	$(CABAL_INSTALL) ghc-bench

$(GHC_BIN):
	BUILDDIR=$(BUILD) SRCDEST=$(BUILD) PKGDEST=$(LOCAL_REPO_DIR) makepkg -D ghc
	rm -rf "$(BUILD)"

$(LOCAL_REPO): $(GHC_BIN)
	repo-add "$(LOCAL_REPO)" "$(GHC_BIN)"

clean:
	rm -f $(CABAL_BIN)
	rm -f $(GHC_BENCH_BIN)
	rm -rf $(USER_CACHE_DIRS)
	sudo rm -rf "$(OUT)"
