.PHONY: all clean sim test dmcp dmcp.r47 dmcp5 docs testPgms dist_windows dist_macos dist_linux dist_dmcp dist_dmcp5 dist_dmcp5r47

all: sim

EXE =
ifeq ($(OS),Windows_NT)
  EXE = .exe
endif

clean:
	rm -f wp43$(EXE)
	rm -f c47$(EXE)
	rm -f r47$(EXE)
	rm -rf wp43-windows* wp43-macos* wp43-linux* wp43-dm42*
	rm -rf c47-windows* c47-macos* c47-linux* c47-dmcp* r47-dmcp*
	rm -rf build build.sim build.dmcp build.dmcp5 build.rel

build.sim:
	meson setup build.sim --buildtype=debug -DRASPBERRY=`tools/onARaspberry`

build.rel:
	meson setup build.rel --buildtype=release -DCI_COMMIT_TAG=$(CI_COMMIT_TAG)

build.dmcp:
	meson setup build.dmcp --cross-file=src/c47-dmcp/cross_arm_gcc.build -DDMCPVERSION=dmcp -DCI_COMMIT_TAG=$(CI_COMMIT_TAG)

build.dmcp5:
	meson setup build.dmcp5 --cross-file=src/c47-dmcp5/cross_arm_gcc.build -DDMCPVERSION=dmcp5 -DCI_COMMIT_TAG=$(CI_COMMIT_TAG)

sim: build.sim
	cd build.sim && ninja sim
	cp build.sim/src/c47-gtk/c47$(EXE) ./
	cp build.sim/src/generateCatalogs/softmenuCatalogs.h src/generated/
	cp build.sim/src/generateConstants/constantPointers.* src/generated/
	cp build.sim/src/ttf2RasterFonts/rasterFontsData.c src/generated/

test: build.sim
	cd build.sim && ninja test

dmcp: build.dmcp
	cd build.dmcp && ninja dmcp

dmcpr47: build.dmcp
	cd build.dmcp && ninja dmcp_r47

dmcp5: build.dmcp5
	cd build.dmcp5 && ninja dmcp5

dmcp5r47: build.dmcp5
	cd build.dmcp5 && ninja dmcp5_r47
    
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
  LINUX_DIST_DIR = c47-linux
  DMCP_DIST_DIR = c47-dmcp
  DMCPR47_DIST_DIR = r47-dmcp
  DMCP5_DIST_DIR = c47-dmcp5
  DMCP5R47_DIST_DIR = r47-dmcp5
else
  WIN_DIST_DIR = c47-windows-$(CI_COMMIT_TAG)
  MAC_DIST_DIR = c47-macos-$(CI_COMMIT_TAG)
  LINUX_DIST_DIR = c47-linux-$(CI_COMMIT_TAG)
  DMCP_DIST_DIR = c47-dmcp-$(CI_COMMIT_TAG)
  DMCPR47_DIST_DIR = r47-dmcp-$(CI_COMMIT_TAG)
  DMCP5_DIST_DIR = c47-dmcp5-$(CI_COMMIT_TAG)
  DMCP5R47_DIST_DIR = r47-dmcp5-$(CI_COMMIT_TAG)
endif

dist_windows: testPgms build.rel/wiki
	cd build.rel && ninja sim
	mkdir -p $(WIN_DIST_DIR)/res/dmcp $(WIN_DIST_DIR)/res/tone
	cp build.rel/src/c47-gtk/c47.exe $(WIN_DIST_DIR)/
	cp res/tone/*.wav $(WIN_DIST_DIR)/res/tone/
	cp res/dmcp/testPgms.bin $(WIN_DIST_DIR)/res/dmcp/
	cp res/c47_pre.css $(WIN_DIST_DIR)/res/
	cp res/c47.reg $(WIN_DIST_DIR)/
	cp res/c47.cmd $(WIN_DIST_DIR)/
	cp -r res/PROGRAMS $(WIN_DIST_DIR)/res/
	cp res/C47.png $(WIN_DIST_DIR)/res/
	cp res/C47short.png $(WIN_DIST_DIR)/res/
	cp res/R47.png $(WIN_DIST_DIR)/res/
	cp res/R47short.png $(WIN_DIST_DIR)/res/
	cp res/fonts/C47__StandardFont.ttf $(WIN_DIST_DIR)/
	cp build.rel/wiki/Installation-on-Windows.md $(WIN_DIST_DIR)/readme.txt
	zip -r c47-windows.zip $(WIN_DIST_DIR)
	rm -rf $(WIN_DIST_DIR)

dist_macos: testPgms build.rel
	cd build.rel && ninja sim
	mkdir -p $(MAC_DIST_DIR)/res/dmcp
	cp build.rel/src/c47-gtk/c47 $(MAC_DIST_DIR)/
	cp res/dmcp/testPgms.bin $(MAC_DIST_DIR)/res/dmcp/
	cp res/c47_pre.css $(MAC_DIST_DIR)/res/
	cp res/C47.png $(MAC_DIST_DIR)/res/
	cp res/C47short.png $(MAC_DIST_DIR)/res/
	cp res/R47.png $(MAC_DIST_DIR)/res/
	cp res/R47short.png $(MAC_DIST_DIR)/res/
	cp res/fonts/C47__StandardFont.ttf $(MAC_DIST_DIR)/
	zip -r c47-macos.zip $(MAC_DIST_DIR)
	rm -rf $(MAC_DIST_DIR)

dist_linux: testPgms build.rel
	cd build.rel && ninja sim
	mkdir -p $(LINUX_DIST_DIR)/res/dmcp
	cp build.rel/src/c47-gtk/c47 $(LINUX_DIST_DIR)/
	cp res/dmcp/testPgms.bin $(LINUX_DIST_DIR)/res/dmcp/
	cp res/c47_pre.css $(LINUX_DIST_DIR)/res/
	cp res/C47.png $(LINUX_DIST_DIR)/res/
	cp res/C47short.png $(LINUX_DIST_DIR)/res/
	cp res/R47.png $(LINUX_DIST_DIR)/res/
	cp res/R47short.png $(LINUX_DIST_DIR)/res/
	cp res/fonts/C47__StandardFont.ttf $(LINUX_DIST_DIR)/
	zip -r c47-linux.zip $(LINUX_DIST_DIR)
	rm -rf $(LINUX_DIST_DIR)

dist_dmcp: dmcp testPgms build.rel/wiki
	mkdir -p $(DMCP_DIST_DIR)
	mkdir -p $(DMCP_DIST_DIR)/resources
	cp build.dmcp/src/c47-dmcp/C47.pgm build.dmcp/src/c47-dmcp/C47_qspi.bin $(DMCP_DIST_DIR)
	cp -r res/offimg/Egypt/ $(DMCP_DIST_DIR)/offimg
	cp -r res/offimg/Norway/ $(DMCP_DIST_DIR)/offimg
	cp -r res/offimg/Netherlands/ $(DMCP_DIST_DIR)/offimg
	cp -r res/offimg/From\ WP43/ $(DMCP_DIST_DIR)/offimg
	cp -r res/offimg/General/ $(DMCP_DIST_DIR)/offimg
	cp -r res/offimg/HP\ related/ $(DMCP_DIST_DIR)/offimg
	cp -r res/offimg/C47/ $(DMCP_DIST_DIR)/offimg
	cp -r res/PROGRAMS $(DMCP_DIST_DIR)
	cp res/dmcp/DM42_keymap.bin $(DMCP_DIST_DIR)
	zip -r $(DMCP_DIST_DIR)/resources/C47.map.zip build.dmcp/src/c47-dmcp/C47.map
	cp res/dmcp/testPgms.bin res/dmcp/testPgms.txt $(DMCP_DIST_DIR)/resources
	cp build.rel/wiki/Installation-on-a-DM42.md $(DMCP_DIST_DIR)/readme.txt
	zip -r c47-dmcp.zip $(DMCP_DIST_DIR)
	rm -rf $(DMCP_DIST_DIR)

dist_dmcp5: dmcp5 testPgms build.rel/wiki
	mkdir -p $(DMCP5_DIST_DIR)
	mkdir -p $(DMCP5_DIST_DIR)/resources
	cp build.dmcp5/src/c47-dmcp5/C47.pg5 build.dmcp5/src/c47-dmcp5/C47_qspi.bin $(DMCP5_DIST_DIR)
	cp -r res/offimg/Egypt/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/offimg/Norway/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/offimg/Netherlands/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/offimg/From\ WP43/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/offimg/General/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/offimg/HP\ related/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/offimg/C47/ $(DMCP5_DIST_DIR)/offimg
	cp -r res/PROGRAMS $(DMCP5_DIST_DIR)
	cp res/dmcp5/DM42_keymap.bin $(DMCP5_DIST_DIR)
	cp res/dmcp5/R47_keymap.bin $(DMCP5_DIST_DIR)
	cp res/dmcp5/SwissMicros/DM42_qspi_3.x.bin $(DMCP5_DIST_DIR)
	zip -r $(DMCP5_DIST_DIR)/resources/C47.map.zip build.dmcp5/src/c47-dmcp5/C47.map
	cp res/dmcp5/testPgms.bin res/dmcp5/testPgms.txt $(DMCP5_DIST_DIR)/resources
	cp build.rel/wiki/Installation-on-a-DM42.md $(DMCP5_DIST_DIR)/readme.txt
	zip -r c47-dmcp5.zip $(DMCP5_DIST_DIR)
	rm -rf $(DMCP5_DIST_DIR)

dist_dmcpr47: dmcpr47 testPgms build.rel/wiki
	mkdir -p $(DMCPR47_DIST_DIR)
	mkdir -p $(DMCPR47_DIST_DIR)/resources
	cp build.dmcp/src/c47-dmcp/R47.pgm build.dmcp/src/c47-dmcp/R47_qspi.bin $(DMCPR47_DIST_DIR)
	cp -r res/offimg/Egypt/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/offimg/Norway/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/offimg/Netherlands/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/offimg/From\ WP43/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/offimg/General/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/offimg/HP\ related/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/offimg/C47/ $(DMCPR47_DIST_DIR)/offimg
	cp -r res/PROGRAMS $(DMCPR47_DIST_DIR)
	cp res/dmcp/DM42_keymap.bin $(DMCPR47_DIST_DIR)
	cp res/dmcp/R47_keymap.bin $(DMCPR47_DIST_DIR)
	zip -r $(DMCPR47_DIST_DIR)/resources/R47.map.zip build.dmcp/src/c47-dmcp/C47.map
	cp res/dmcp/testPgms.bin res/dmcp/testPgms.txt $(DMCPR47_DIST_DIR)/resources
	cp build.rel/wiki/Installation-on-a-DM42.md $(DMCPR47_DIST_DIR)/readme.txt
	zip -r r47-dmcp.zip $(DMCPR47_DIST_DIR)
	rm -rf $(DMCPR47_DIST_DIR)


dist_dmcp5r47: dmcp5r47 testPgms build.rel/wiki
	mkdir -p $(DMCP5R47_DIST_DIR)
	mkdir -p $(DMCP5R47_DIST_DIR)/resources
	cp build.dmcp5/src/c47-dmcp5/R47.pg5 $(DMCP5R47_DIST_DIR)
	cp -r res/offimg/Egypt/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/offimg/Norway/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/offimg/Netherlands/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/offimg/From\ WP43/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/offimg/General/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/offimg/HP\ related/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/offimg/C47/ $(DMCP5R47_DIST_DIR)/offimg
	cp -r res/PROGRAMS $(DMCP5R47_DIST_DIR)
	cp res/dmcp5/DM42_keymap.bin $(DMCP5R47_DIST_DIR)
	cp res/dmcp5/R47_keymap.bin $(DMCP5R47_DIST_DIR)
	cp res/dmcp5/SwissMicros/DM42_qspi_3.x.bin $(DMCP5R47_DIST_DIR)
	zip -r $(DMCP5R47_DIST_DIR)/resources/R47.map.zip build.dmcp5/src/c47-dmcp5/C47.map
	cp res/dmcp5/testPgms.bin res/dmcp5/testPgms.txt $(DMCP5R47_DIST_DIR)/resources
	cp build.rel/wiki/Installation-on-a-DM42.md $(DMCP5R47_DIST_DIR)/readme.txt
	cp res/dmcp5/install_R47_on_DM32.txt $(DMCP5R47_DIST_DIR)
	zip -r r47-dmcp5.zip $(DMCP5R47_DIST_DIR)
	rm -rf $(DMCP5R47_DIST_DIR)
