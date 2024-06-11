define HELP_TEXT
Please choose one of the following targets:
  run-tests      - clean, build, and test all benchmarks for the specified TARGET mode (host,standalone,simple)
  all-clean      - clean all benchmark directories for all TARGET modes
  spike-build    - build RISC-V Spike simulator extensions for bringup-bench

Within individual directories, the following Makefile targets are also available:
  clean          - delete all generated files
  build          - build the binary
  test           - run the standard test on the binary

Note that benchmark builds must be parameterized with the build MODE, such as:
  TARGET=host       - build benchmarks to run on a Linux host
  TARGET=standalone - build benchmarks to run in standalone mode (a virtual bare-metal CPU)
  TARGET=simple     - build benchmarks to run on the RISC-V Simple_System simulation testing environment

Example benchmark builds:
  make TARGET=host clean build test
  make TARGET=standalone build
  make TARGET=simple clean
  make all-clean
  make TARGET=simple run-tests
endef

export HELP_TEXT

error:
	@echo "$$HELP_TEXT"

#
# END of user-modifiable variables
#
BMARKS = ackermann anagram banner blake2b boyer-moore-search bubble-sort c-interp checkers cipher dhrystone distinctness donut fft-int flood-fill frac-calc fy-shuffle gcd-list hanoi heapsort kepler life longdiv lz-compress mandelbrot max-subseq mersenne minspan natlog nr-solver parrondo pascal pi-calc primal-test quine rabinkarp-search rho-factor shortest-path sieve simple-grep skeleton spelt2num strange topo-sort totient weekday

OPT_CFLAGS = -O6 -g

ifeq ($(TARGET), host)
TARGET_CC = gcc
TARGET_CFLAGS = -DTARGET_HOST
TARGET_LIBS =
TARGET_SIM =
TARGET_DIFF = diff
TARGET_EXE = $(PROG).host
TARGET_CLEAN =
TARGET_BMARKS = $(BMARKS)
TARGET_CONFIGURED = 1
else ifeq ($(TARGET), standalone)
TARGET_CC = gcc
TARGET_CFLAGS = -DTARGET_SA
TARGET_LIBS =
TARGET_SIM =
TARGET_DIFF = diff
TARGET_EXE = $(PROG).sa
TARGET_CLEAN =
TARGET_BMARKS = $(BMARKS)
TARGET_CONFIGURED = 1
else ifeq ($(TARGET), simple)
TARGET_CC = riscv32-unknown-elf-gcc
TARGET_CFLAGS = -DTARGET_SIMPLE -march=rv32imc -mabi=ilp32 -static -mcmodel=medany -Wall -g -Os -fvisibility=hidden -nostdlib -nostartfiles -ffreestanding  -MMD
TARGET_LIBS = -lgcc
TARGET_SIM = ../target/simple_sim.sh ../../Snowflake-IoT.alt/ibex/build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system
TARGET_DIFF = mv ibex_simple_system.log FOO; diff
TARGET_EXE = $(PROG).elf
TARGET_CLEAN = *.d ibex_simple_system_pcount.csv
TARGET_BMARKS = banner blake2b boyer-moore-search bubble-sort cipher dhrystone distinctness fft-int flood-fill frac-calc fy-shuffle gcd-list hanoi heapsort kepler life longdiv mandelbrot max-subseq mersenne minspan natlog nr-solver parrondo pascal primal-test rabinkarp-search shortest-path sieve simple-grep skeleton strange topo-sort totient weekday
TARGET_CONFIGURED = 1
else ifeq ($(TARGET), spike)
TARGET_CC = riscv32-unknown-elf-gcc
#TARGET_CC = riscv32-unknown-elf-clang
TARGET_AR = riscv32-unknown-elf-ar
TARGET_CFLAGS = -DTARGET_SPIKE -march=rv32imc -mabi=ilp32 -static -mcmodel=medlow -Wall -g -Os -fvisibility=hidden -nostdlib -nostartfiles -ffreestanding # -MMD -mcmodel=medany 
TARGET_LIBS = -lgcc
TARGET_SIM = ../../riscv-isa-sim/build/spike --isa=RV32IMC --extlib=../target/simple_mmio_plugin.so -m0x100000:0x40000 --device=simple_mmio_plugin,0x20000,x
TARGET_DIFF = diff
TARGET_EXE = $(PROG).elf
TARGET_CLEAN = *.d ibex_simple_system_pcount.csv
TARGET_BMARKS = banner blake2b boyer-moore-search bubble-sort cipher dhrystone distinctness fft-int flood-fill frac-calc fuzzy-match fy-shuffle gcd-list grad-descent hanoi heapsort indirect-test kadane kepler knapsack life longdiv mandelbrot max-subseq mersenne minspan murmur-hash natlog nr-solver parrondo pascal primal-test qsort-demo rabinkarp-search regex-parser shortest-path sieve simple-grep skeleton strange topo-sort totient weekday
TARGET_CONFIGURED = 1



else
# default is an unconfigured
TARGET_CONFIGURED = 0
endif

CFLAGS = -Wall $(OPT_CFLAGS) -Wno-strict-aliasing $(TARGET_CFLAGS) $(LOCAL_CFLAGS)
OBJS = $(LOCAL_OBJS) ../common/libmin.o ../common/libtarg.o
LIBS = $(LOCAL_LIBS) $(TARGET_LIBS)

build: $(TARGET_EXE)

%.o: %.c
	$(TARGET_CC) $(CFLAGS) -I../common/ -o $(notdir $@) -c $<

$(TARGET_EXE): $(OBJS)
ifeq ($(TARGET), host)
	$(TARGET_CC) $(CFLAGS) -o $@ $(notdir $^) $(LIBS)
else ifeq ($(TARGET), standalone)
	$(TARGET_CC) $(CFLAGS) -o $@ $(notdir $^) $(LIBS)
else ifeq ($(TARGET), simple)
	$(TARGET_CC) $(CFLAGS) -T ../target/simple-map.ld $(notdir $^) ../target/simple-crt0.S -o $@ $(LIBS)
else
	$(error MODE is not defined (add: TARGET={host|sa}).)
endif

clean:
	rm -f $(PROG).host $(PROG).sa $(PROG).elf *.o core mem.out *.log FOO $(LOCAL_CLEAN) $(TARGET_CLEAN)


#
# top-level Makefile interfaces
#

run-tests:
ifeq ($(TARGET_CONFIGURED), 0)
	@echo "'run-tests' command requires a TARGET definition." ; \
	echo "" ; \
	echo "$$HELP_TEXT"
else
	@for _BMARK in $(TARGET_BMARKS) ; do \
	  cd $$_BMARK ; \
	  echo "--------------------------------" ; \
	  echo "Running "$$_BMARK" in TARGET="$$TARGET ; \
	  echo "--------------------------------" ; \
	  $(MAKE) TARGET=$$TARGET clean build test || exit 1; \
	  cd .. ; \
	done
endif 

clean-all all-clean: clean
	@for _BMARK in $(BMARKS) ; do \
	  for _TARGET in host standalone simple spike ; do \
	    cd $$_BMARK ; \
	    echo "--------------------------------" ; \
	    echo "Cleaning "$$_BMARK" in TARGET="$$_TARGET ; \
	    echo "--------------------------------" ; \
	    $(MAKE) TARGET=$$_TARGET clean ; \
	    cd .. ; \
	  done \
	done


