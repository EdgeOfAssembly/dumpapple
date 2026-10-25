# dumpapple - Apple IIgs 65816 disassembler
# Needs Capstone 6 (W65C816 modes). Set CAPSTONE_PREFIX if it is not in ~/.local.
CXX ?= g++
# Capstone >= 6.0.0 Alpha11 is required (W65C816 LONG_M/LONG_X modes).  It is
# taken ONLY from CAPSTONE_PREFIX (default ~/.local); a system Capstone 5 is
# never used, for any target.
CAPSTONE_PREFIX ?= $(HOME)/.local
CAPSTONE_INC := $(CAPSTONE_PREFIX)/include
CAPSTONE_LIBS := $(firstword $(wildcard $(CAPSTONE_PREFIX)/lib64/libcapstone.a $(CAPSTONE_PREFIX)/lib/libcapstone.a))
CAPSTONE_CFLAGS := -I$(CAPSTONE_INC) -I$(CAPSTONE_INC)/capstone

CXXFLAGS ?= -O2
CXXFLAGS += -std=c++20 -Wall -Wextra $(CAPSTONE_CFLAGS)
ASAN_FLAGS = -std=c++20 -Wall -Wextra -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer $(CAPSTONE_CFLAGS)

SRCS = src/omf.cpp src/decode.cpp src/hints.cpp src/analyze.cpp src/emit.cpp
HDRS = $(wildcard src/*.h)

all: dumpapple

check-capstone:
	@test -f "$(CAPSTONE_INC)/capstone/capstone.h" || { echo "error: Capstone headers not found in $(CAPSTONE_INC) (set CAPSTONE_PREFIX; need Capstone >= 6.0.0 Alpha11)"; exit 1; }
	@test -n "$(CAPSTONE_LIBS)" || { echo "error: libcapstone.a not found under $(CAPSTONE_PREFIX)/lib64 or /lib (need Capstone >= 6.0.0 Alpha11)"; exit 1; }
	@printf '#include <capstone/capstone.h>\n#if CS_API_MAJOR < 6 || (CS_API_MAJOR == 6 && CS_API_MINOR == 0 && CS_VERSION_PRE_RELEASE < CS_VERSION_ALPHA11)\n#error need Capstone >= 6.0.0 Alpha11\n#endif\n' | $(CXX) -E -I$(CAPSTONE_INC) -x c++ - -o /dev/null 2>/dev/null || { echo "error: Capstone in $(CAPSTONE_PREFIX) is older than 6.0.0 Alpha11"; exit 1; }

dumpapple: $(SRCS) src/main.cpp $(HDRS) | check-capstone
	$(CXX) $(CXXFLAGS) -o $@ $(SRCS) src/main.cpp $(CAPSTONE_LIBS)

dumpapple-asan: $(SRCS) src/main.cpp $(HDRS) | check-capstone
	$(CXX) $(ASAN_FLAGS) -o $@ $(SRCS) src/main.cpp $(CAPSTONE_LIBS)

# Fuzz harness: libFuzzer when built with clang (FUZZ_ENGINE=libfuzzer),
# otherwise a standalone ASan/UBSan mutation driver (gcc).
fuzz/fuzz_dumpapple: fuzz/fuzz_dumpapple.cpp $(SRCS) $(HDRS) | check-capstone
ifeq ($(FUZZ_ENGINE),libfuzzer)
	clang++ -std=c++20 -g -O1 -fsanitize=fuzzer,address,undefined $(CAPSTONE_CFLAGS) -o $@ fuzz/fuzz_dumpapple.cpp $(SRCS) $(CAPSTONE_LIBS)
else
	$(CXX) $(ASAN_FLAGS) -DSTANDALONE_FUZZ -o $@ fuzz/fuzz_dumpapple.cpp $(SRCS) $(CAPSTONE_LIBS)
endif

tools/mkomf: tools/mkomf.cpp
	$(CXX) -std=c++20 -O2 -Wall -Wextra -o $@ $<

test: dumpapple tools/mkomf
	mkdir -p tests/omf tests/progs tests/out
	./tests/run_tests.sh

fuzz: fuzz/fuzz_dumpapple
	./fuzz/fuzz_dumpapple -runs=$${FUZZ_RUNS:-20000} tests/progs/*.bin tests/omf/*.omf

fuzz-roundtrip: dumpapple
	./tests/fuzz_roundtrip.sh $${FUZZ_ITERS:-300} $${DA:-./dumpapple}

# Gold-set scorecard from a private fixtures clone (never copied into this repo):
#   make scorecard DA_FIXTURES=/path/to/dumpapple-fixtures
scorecard: dumpapple
	@if [ -z "$(DA_FIXTURES)" ]; then echo "scorecard: DA_FIXTURES not set, skipped"; exit 0; fi; \
	set -e; R=tests/out/scorecard; rm -rf $$R; mkdir -p $$R; \
	cp -r "$(DA_FIXTURES)/tools" "$(DA_FIXTURES)/out" $$R/; ln -sf "$(CURDIR)/dumpapple" tests/out/dumpapple; \
	(cd $$R && python3 tools/run_entries.py >/dev/null); \
	sed -i "s/4df732f/$$(git rev-parse --short HEAD)/" $$R/scorecard.md; \
	python3 tests/scorecard_notes.py $$R; \
	python3 tests/scorecard_hints.py $$R "$(CURDIR)/dumpapple" >> $$R/scorecard.md; \
	sed -n '/^| entry/,$$p' $$R/scorecard.md

clean:
	rm -f dumpapple dumpapple-asan fuzz/fuzz_dumpapple tools/mkomf
	rm -rf tests/out

.PHONY: all test fuzz fuzz-roundtrip scorecard clean check-capstone
