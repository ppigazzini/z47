# Build *.p47 and *.rtf from each *.p47u source in this directory and
# its immediate child directories.
#
# Paths come from this file, so the working directory does not matter:
# 
#    $ cd res/PROGRAMS && make
#    $ make -f res/PROGRAMS/Makefile
#    $ make -C res/PROGRAMS

.PHONY: all clean index
.DELETE_ON_ERROR:

HERE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# Prefer a t47 or rejig binary in the repository root, but fall back to the PATH.
T47 ?= $(or $(wildcard $(abspath $(HERE)/../../t47)),$(shell command -v t47),$(shell command -v t47.sh))
REJIG ?= $(or $(wildcard $(abspath $(HERE)/../../rejig)),$(shell command -v rejig))

P47U := $(wildcard $(HERE)/*.p47u $(HERE)/*/*.p47u)
P47  := $(P47U:.p47u=.p47)
RTF  := $(P47U:.p47u=.rtf)

all: $(P47) $(RTF) index

# Rebuild the program index from the .p47u '@ Index:'/'@ Author:'/'@ Version:' headers.
index:
	python3 $(HERE)/mkindex.py

clean:
	rm -f $(P47) $(RTF)

$(HERE)/%.p47: $(HERE)/%.p47u
	$(REJIG) $< -o $@

$(HERE)/%.rtf: $(HERE)/%.p47
	$(T47) --reset -e "readp $(abspath $<); xportp {$(notdir $*)} $(abspath $@)"
