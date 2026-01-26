.PHONY: all clean sim test dmcp dmcpr47 dmcp5 dmcp5r47 docs testPgms dist_windows dist_macos dist_linux dist_dmcp dist_dmcpr47 dist_dmcp5 dist_dmcp5r47

all: sim
both: sim simr47

EXE =
ifeq ($(OS),Windows_NT)
  EXE = .exe
endif

BUILD_PC = build.sim
DIST_DIR_PC = build.sim
XVFB =
FORCENEW_TESTPGMS =
GMP_MESON_BUILD  = subprojects/gmp-6.2.1/meson.build
GMP_MESON_SOURCE = subprojects/packagefiles/gmp-6.2.1/meson.build

$(GMP_MESON_BUILD): $(GMP_MESON_SOURCE)
	rm -rf subprojects/gmp-6.2.1

clean: $(GMP_MESON_BUILD)
	rm -f wp43$(EXE)
	rm -f c47$(EXE)
	rm -f r47$(EXE)
	rm -rf wp43-windows* wp43-macos* wp43-linux* wp43-dm42*
	rm -rf c47-windows* c47-macos* c47-linux* c47-dmcp* r47-dmcp*
	rm -rf build build.sim build.dmcp build.dmcp5 build.rel build.rel.debug
	rm -f src/generated/*.c src/generated/constantPointers.h src/generated/softmenuCatalogs.h
	rm -rf PROGRAMS/ALLPGMS

build.sim:
	meson setup $(BUILD_PC) --buildtype=custom -DRASPBERRY=`tools/onARaspberry` -DDECNUMBER_FASTMUL=true

build.rel:
	meson setup $(BUILD_PC) --buildtype=release -DCI_COMMIT_TAG=$(CI_COMMIT_TAG) -DDECNUMBER_FASTMUL=true

build.rel.debug:
	meson setup $(BUILD_PC) --buildtype=custom -DCI_COMMIT_TAG=$(CI_COMMIT_TAG) -DDECNUMBER_FASTMUL=true

build.dmcp:
	meson setup build.dmcp --cross-file=src/c47-dmcp/cross_arm_gcc.build -DDMCPVERSION=dmcp -DCI_COMMIT_TAG=$(CI_COMMIT_TAG) -DDECNUMBER_FASTMUL=true

build.dmcp5:
	meson setup build.dmcp5 --cross-file=src/c47-dmcp5/cross_arm_gcc.build -DDMCPVERSION=dmcp5 -DCI_COMMIT_TAG=$(CI_COMMIT_TAG) -DDECNUMBER_FASTMUL=true

sim: $(BUILD_PC)
	cd $(BUILD_PC) && ninja sim
	cp $(BUILD_PC)/src/c47-gtk/c47$(EXE) ./
	install -C $(BUILD_PC)/src/generateCatalogs/softmenuCatalogs.h src/generated/
	install -C $(BUILD_PC)/src/generateConstants/constantPointers.h src/generated/
	install -C $(BUILD_PC)/src/generateConstants/constantPointers.c src/generated/
	install -C $(BUILD_PC)/src/ttf2RasterFonts/rasterFontsData.c src/generated/

simr47: $(BUILD_PC)
	cd $(BUILD_PC) && ninja simr47
	cp $(BUILD_PC)/src/c47-gtk/r47$(EXE) ./
	install -C $(BUILD_PC)/src/generateCatalogs/softmenuCatalogs.h src/generated/
	install -C $(BUILD_PC)/src/generateConstants/constantPointers.h src/generated/
	install -C $(BUILD_PC)/src/generateConstants/constantPointers.c src/generated/
	install -C $(BUILD_PC)/src/ttf2RasterFonts/rasterFontsData.c src/generated/

dmcp: build.dmcp
	cd build.dmcp && ninja dmcp

dmcpr47: build.dmcp
	cd build.dmcp && ninja dmcp_r47

dmcp5: build.dmcp5
	cd build.dmcp5 && ninja dmcp5

dmcp5r47: build.dmcp5
	cd build.dmcp5 && ninja dmcp5_r47

docs: build.sim
	cd $(BUILD_PC) && ninja docs

testPgms: build.sim
	cd $(BUILD_PC) && ninja testPgms
	mkdir -p res/testPgms
	cp $(BUILD_PC)/src/generateTestPgms/testPgms.bin res/testPgms/

test: build.sim testPgms
	cd $(BUILD_PC) && ninja test

build.rel/wiki: build.rel
	rm -fr $(BUILD_PC)/wiki
	git clone https://gitlab.com/rpncalculators/c43.wiki.git $(BUILD_PC)/wiki

ifeq ($(CI_COMMIT_TAG),)
  WIN_DIST_DIR = c47-windows
  MAC_DIST_DIR = c47-macos
  LINUX_DIST_DIR = c47-linux
  DMCP_DIST_DIR = c47-dmcp
  DMCPR47_DIST_DIR = r47-dmcp
  DMCP5_DIST_DIR = c47-dmcp5
  DMCP5R47_DIST_DIR = r47-dmcp5
  VERSION = $(shell git describe --match=NeVeRmAtCh --always --abbrev=8 --dirty=-mod)
else
  WIN_DIST_DIR = c47-windows-$(CI_COMMIT_TAG)
  MAC_DIST_DIR = c47-macos-$(CI_COMMIT_TAG)
  LINUX_DIST_DIR = c47-linux-$(CI_COMMIT_TAG)
  DMCP_DIST_DIR = c47-dmcp-$(CI_COMMIT_TAG)
  DMCPR47_DIST_DIR = r47-dmcp-$(CI_COMMIT_TAG)
  DMCP5_DIST_DIR = c47-dmcp5-$(CI_COMMIT_TAG)
  DMCP5R47_DIST_DIR = r47-dmcp5-$(CI_COMMIT_TAG)
  VERSION = $(CI_COMMIT_TAG)
  #
  FORCENEW_TESTPGMS = 1
endif

dist_install_PC: sim simr47
	mkdir -p $(DIST_DIR_PC)/res/
	cp $(BUILD_PC)/src/c47-gtk/c47$(EXE) $(DIST_DIR_PC)/
	cp $(BUILD_PC)/src/c47-gtk/r47$(EXE) $(DIST_DIR_PC)/
	cp -r res/PROGRAMS $(DIST_DIR_PC)/res/
	cp -r res/STATE $(DIST_DIR_PC)/res/
	cp res/c47_pre.css $(DIST_DIR_PC)/res/
	cp res/C47.png $(DIST_DIR_PC)/res/
	cp res/C47short.png $(DIST_DIR_PC)/res/
	cp res/R47.png $(DIST_DIR_PC)/res/
	cp res/R47short.png $(DIST_DIR_PC)/res/
	cp res/fonts/C47__StandardFont.ttf $(DIST_DIR_PC)/

dist_testPgms_PC: testPgms dist_install_PC
	mkdir -p $(DIST_DIR_PC)/res/testPgms/
	cp res/testPgms/testPgms.bin res/testPgms/testPgms.txt $(DIST_DIR_PC)/res/testPgms/
	cd $(DIST_DIR_PC) && $(XVFB) ./c47$(EXE) --writeexportall
	cd $(DIST_DIR_PC)/PROGRAMS/ && zip -r ../res/testPgms/testPgms.zip ALLPGMS
	cp $(DIST_DIR_PC)/res/testPgms/testPgms.zip res/testPgms/

dist_windows: BUILD_PC = build.rel
dist_windows: DIST_DIR_PC = $(WIN_DIST_DIR)
dist_windows: build.rel/wiki dist_testPgms_PC
	rm -rf $(WIN_DIST_DIR)/PROGRAMS
	mkdir -p $(WIN_DIST_DIR)/res/tone
	cp res/tone/*.wav $(WIN_DIST_DIR)/res/tone/
	cp res/c47.reg $(WIN_DIST_DIR)/
	cp res/c47.cmd $(WIN_DIST_DIR)/
	cp $(BUILD_PC)/wiki/Installation-on-Windows.md $(WIN_DIST_DIR)/readme.txt
	#zip the package
	zip -r c47-windows.zip $(WIN_DIST_DIR)
	rm -rf $(WIN_DIST_DIR)

dist_macos: BUILD_PC = build.rel
dist_macos: DIST_DIR_PC = $(MAC_DIST_DIR)
dist_macos: dist_testPgms_PC
	rm -rf $(MAC_DIST_DIR)/PROGRAMS
	#zip the package
	zip -r c47-macos.zip $(MAC_DIST_DIR)
	rm -rf $(MAC_DIST_DIR)

dist_linux: BUILD_PC = build.rel.debug
dist_linux: DIST_DIR_PC = $(LINUX_DIST_DIR)
dist_linux: dist_testPgms_PC
	rm -rf $(LINUX_DIST_DIR)/PROGRAMS
	# debug setting (defined by custom meson buildtype) as workaround for issue #470
	strip $(LINUX_DIST_DIR)/c47 # workaround #470
	cp res/c47.xpm $(LINUX_DIST_DIR)/res/
	#zip the package
	zip -r c47-linux.zip $(LINUX_DIST_DIR)
	rm -rf $(LINUX_DIST_DIR)

DIST_DIR_DM = $(DMCP_DIST_DIR)
dist_install_DM: build.rel/wiki
	mkdir -p $(DIST_DIR_DM)
	mkdir -p $(DIST_DIR_DM)/resources
	cp -r res/offimg/Egypt/. $(DIST_DIR_DM)/offimg
	cp -r res/offimg/Norway/. $(DIST_DIR_DM)/offimg
	cp -r res/offimg/Netherlands/. $(DIST_DIR_DM)/offimg
	cp -r res/offimg/From\ WP43/. $(DIST_DIR_DM)/offimg
	cp -r res/offimg/General/. $(DIST_DIR_DM)/offimg
	cp -r res/offimg/HP\ related/. $(DIST_DIR_DM)/offimg
	cp -r res/offimg/C47/. $(DIST_DIR_DM)/offimg
	cp -r res/PROGRAMS $(DIST_DIR_DM)
	cp -r res/STATE $(DIST_DIR_DM)
	cp res/keymaps/keymap_DM42.bin $(DIST_DIR_DM)/resources

ifeq ($(FORCENEW_TESTPGMS),)
  DIST_TESTPGMS_DM = dist_testPgms_DM
else
  DIST_TESTPGMS_DM = dist_testPgms_forcenew_DM
endif

dist_testPgms_DM: dist_install_DM
	mkdir -p $(DIST_DIR_DM)
	mkdir -p $(DIST_DIR_DM)/resources
	cp res/testPgms/testPgms.bin res/testPgms/testPgms.txt res/testPgms/testPgms.zip $(DIST_DIR_DM)/resources

dist_testPgms_forcenew_DM: dist_testPgms_PC dist_install_DM
	mkdir -p $(DIST_DIR_DM)
	mkdir -p $(DIST_DIR_DM)/resources
	cp $(BUILD_PC)/res/testPgms/testPgms.bin $(BUILD_PC)/res/testPgms/testPgms.txt $(BUILD_PC)/res/testPgms/testPgms.zip $(DIST_DIR_DM)/resources

dist_dmcp: DIST_DIR_DM = $(DMCP_DIST_DIR)
dist_dmcp: dmcp $(DIST_TESTPGMS_DM)
	cp build.dmcp/src/c47-dmcp/C47.pgm build.dmcp/src/c47-dmcp/C47_qspi.bin $(DIST_DIR_DM)
	zip -r $(DIST_DIR_DM)/resources/C47.map.zip build.dmcp/src/c47-dmcp/C47.map
	cp $(BUILD_PC)/wiki/Installation-on-a-DM42.md $(DIST_DIR_DM)/install_C47_on_DM42_readme_on_wiki.txt
	zip -r c47-dmcp.zip $(DIST_DIR_DM)
	rm -rf $(DIST_DIR_DM)

dist_dmcp5: DIST_DIR_DM = $(DMCP5_DIST_DIR)
dist_dmcp5: dmcp5 $(DIST_TESTPGMS_DM)
	cp build.dmcp5/src/c47-dmcp5/C47.pg5 $(DIST_DIR_DM)
	cp res/dmcp5/SwissMicros/DM42_qspi_3.x.bin $(DIST_DIR_DM)/resources
	zip -r $(DIST_DIR_DM)/resources/C47.map.zip build.dmcp5/src/c47-dmcp5/C47.map
	cp res/dmcp5/install_C47_on_DM42n.txt $(DIST_DIR_DM)
	zip -r c47-dmcp5.zip $(DIST_DIR_DM)
	rm -rf $(DIST_DIR_DM)

dist_dmcpr47: DIST_DIR_DM = $(DMCPR47_DIST_DIR)
dist_dmcpr47: dmcpr47 $(DIST_TESTPGMS_DM)
	cp build.dmcp/src/c47-dmcp/R47.pgm build.dmcp/src/c47-dmcp/R47_qspi.bin $(DMCPR47_DIST_DIR)
	cp res/keymaps/keymap_R47.bin $(DMCPR47_DIST_DIR)
	zip -r $(DMCPR47_DIST_DIR)/resources/R47.map.zip build.dmcp/src/c47-dmcp/C47.map
	cp $(BUILD_PC)/wiki/Installation-on-a-DM42.md $(DMCPR47_DIST_DIR)/install_C47_on_DM42_readme_on_wiki.txt
	zip -r r47-dmcp.zip $(DMCPR47_DIST_DIR)
	rm -rf $(DMCPR47_DIST_DIR)

dist_dmcp5r47: DIST_DIR_DM = $(DMCP5R47_DIST_DIR)
dist_dmcp5r47: dmcp5r47 $(DIST_TESTPGMS_DM)
	mkdir -p $(DMCP5R47_DIST_DIR)/resources/
	cp build.dmcp5/src/c47-dmcp5/R47.pg5 $(DMCP5R47_DIST_DIR)
	cp res/keymaps/keymap_R47.bin $(DMCP5R47_DIST_DIR)/resources
	cp res/dmcp5/SwissMicros/DM42_qspi_3.x.bin $(DMCP5R47_DIST_DIR)/resources
	zip -r $(DMCP5R47_DIST_DIR)/resources/R47.map.zip build.dmcp5/src/c47-dmcp5/C47.map
	cp res/dmcp5/install_R47_on_DM32.txt $(DMCP5R47_DIST_DIR)/resources
	cp res/dmcp5/update_R47.txt $(DMCP5R47_DIST_DIR)
	cp res/combo/R47_combo.py $(DMCP5R47_DIST_DIR)/
	cp res/combo/DMCP5_flash_3.56.bin $(DMCP5R47_DIST_DIR)/
	cd $(DMCP5R47_DIST_DIR) && python3 R47_combo.py $(VERSION)
	rm $(DMCP5R47_DIST_DIR)/R47_combo.py
	rm $(DMCP5R47_DIST_DIR)/DMCP5_flash_3.56.bin
	zip -r r47-dmcp5.zip $(DMCP5R47_DIST_DIR)
	rm -rf $(DMCP5R47_DIST_DIR)
