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

# Prefer a t47 binary, then c47, then r47.
# Look in the repository root first, but fall back to the PATH.
T47 ?= $(shell \
	if [ -x "$(HERE)/../../t47" ]; then \
		printf '"%s"' "$(HERE)/../../t47"; \
	elif command -v t47 >/dev/null 2>&1; then \
		command -v t47; \
	elif [ -x "$(HERE)/../../c47" ]; then \
		printf '"%s" --headless' "$(HERE)/../../c47"; \
	elif command -v c47 >/dev/null 2>&1; then \
		printf '%s --headless' "$$(command -v c47)"; \
	elif [ -x "$(HERE)/../../r47" ]; then \
		printf '"%s" --headless' "$(HERE)/../../r47"; \
	elif command -v r47 >/dev/null 2>&1; then \
		printf '%s --headless' "$$(command -v r47)"; \
	fi)

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
