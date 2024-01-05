.PHONY: all clean sim test dmcp docs testPgms dist_windows dist_macos dist_dm42

all: sim

EXE =
ifeq ($(OS),Windows_NT)
  EXE = .exe
endif

clean:
	rm -f wp43$(EXE)
	rm -f c43$(EXE)
	rm -f c47$(EXE)
	rm -rf wp43-windows* wp43-macos* wp43-dm42*
	rm -rf c43-windows* c43-macos* c43-dm42*
	rm -rf c47-windows* c47-macos* c47-dm42*
	rm -rf build build.sim build.dmcp build.rel

build.sim:
	meson setup build.sim --buildtype=debug -DRASPBERRY=`tools/onARaspberry`

build.rel:
	meson setup build.rel --buildtype=release -DCI_COMMIT_TAG=$(CI_COMMIT_TAG)

build.dmcp:
	meson setup build.dmcp --cross-file=cross_arm_gcc.build -DCI_COMMIT_TAG=$(CI_COMMIT_TAG)

sim: build.sim
	cd build.sim && ninja sim
	cp build.sim/src/wp43-gtk/c47$(EXE) ./
	cp build.sim/src/generateCatalogs/softmenuCatalogs.h src/generated/
	cp build.sim/src/generateConstants/constantPointers.* src/generated/
	cp build.sim/src/ttf2RasterFonts/rasterFontsData.c src/generated/

test: build.sim
	cd build.sim && ninja test

dmcp: build.dmcp
	cd build.dmcp && ninja dmcp

docs: build.sim
	cd build.sim && ninja docs

testPgms: build.sim
	cd build.sim && ninja testPgms
	cp build.sim/src/generateTestPgms/testPgms.bin res/dmcp/

build.rel/wiki: build.rel
	git clone https://gitlab.com/rpncalculators/c43.wiki.git build.rel/wiki

ifeq ($(CI_COMMIT_TAG),)
  WIN_DIST_DIR = c47-windows
  MAC_DIST_DIR = c47-macos
  DM_DIST_DIR = c47-dm42
else
  WIN_DIST_DIR = c47-windows-$(CI_COMMIT_TAG)
  MAC_DIST_DIR = c47-macos-$(CI_COMMIT_TAG)
  DM_DIST_DIR = c47-dm42-$(CI_COMMIT_TAG)
endif

dist_windows: testPgms build.rel/wiki
	cd build.rel && ninja sim
	mkdir -p $(WIN_DIST_DIR)/res/dmcp $(WIN_DIST_DIR)/res/tone
	cp build.rel/src/wp43-gtk/c47.exe $(WIN_DIST_DIR)/
	cp res/tone/*.wav $(WIN_DIST_DIR)/res/tone/
	cp res/dmcp/testPgms.bin $(WIN_DIST_DIR)/res/dmcp/
	cp res/c47_pre.css $(WIN_DIST_DIR)/res/
	cp res/c47.reg $(WIN_DIST_DIR)/
	cp res/c47.cmd $(WIN_DIST_DIR)/
	cp -r res/PROGRAMS $(WIN_DIST_DIR)/res/
	cp res/dm42l_L1.png $(WIN_DIST_DIR)/res/
	cp res/fonts/C47__StandardFont.ttf $(WIN_DIST_DIR)/
	cp build.rel/wiki/Installation-on-Windows.md $(WIN_DIST_DIR)/readme.txt
	zip -r c47-windows.zip $(WIN_DIST_DIR)
	rm -rf $(WIN_DIST_DIR)

dist_macos: testPgms build.rel
	cd build.rel && ninja sim
	mkdir -p $(MAC_DIST_DIR)/res/dmcp
	cp build.rel/src/wp43-gtk/c47 $(MAC_DIST_DIR)/
	cp res/dmcp/testPgms.bin $(MAC_DIST_DIR)/res/dmcp/
	cp res/c47_pre.css $(MAC_DIST_DIR)/res/
	cp res/dm42l_L1.png $(MAC_DIST_DIR)/res/
	cp res/fonts/C47__StandardFont.ttf $(MAC_DIST_DIR)/
	zip -r c47-macos.zip $(MAC_DIST_DIR)
	rm -rf $(MAC_DIST_DIR)

dist_dm42: dmcp testPgms build.rel/wiki
	mkdir -p $(DM_DIST_DIR)
	cp build.dmcp/src/wp43-dmcp/C47.pgm build.dmcp/src/wp43-dmcp/C47_qspi.bin $(DM_DIST_DIR)
	cp -r res/offimg/Egypt/ $(DM_DIST_DIR)/offimg
	cp -r res/offimg/Norway/ $(DM_DIST_DIR)/offimg
	cp -r res/offimg/Netherlands/ $(DM_DIST_DIR)/offimg
	cp -r res/offimg/From\ WP43/ $(DM_DIST_DIR)/offimg
	cp -r res/offimg/General/ $(DM_DIST_DIR)/offimg
	cp -r res/offimg/HP\ related/ $(DM_DIST_DIR)/offimg
	cp -r res/offimg/C47/ $(DM_DIST_DIR)/offimg
	cp -r res/PROGRAMS $(DM_DIST_DIR)
	cp res/dmcp/original_DM42_keymap.bin res/dmcp/testPgms.bin $(DM_DIST_DIR)
	cp build.rel/wiki/Installation-on-a-DM42.md $(DM_DIST_DIR)/readme.txt
	zip -r c47-dm42.zip $(DM_DIST_DIR)
	rm -rf $(DM_DIST_DIR)

