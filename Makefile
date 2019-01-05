DUT ?= $(shell find -maxdepth 1 -type d -name "wb_*" -printf '%P\n' -quit)

wave_file = wave.vcd
wave_save_file = wave.gtkw

compiler ?= iverilog
compiler_opts ?= -g2012 -DWAVE_FILE='"$(wave_file)"'
runtime ?= vvp
viewer ?= gtkwave

files = $(shell find -name "*.sv")

$(DUT)/main: $(files)
	$(compiler) $(compiler_opts) -s$(DUT)_tb -o $@ $(files)

.PHONY: run
run: $(DUT)/main
	(cd $(DUT); $(runtime) main)

.PHONY: wave
wave: run
	(cd $(DUT); $(viewer) $(wave_file) $(wave_save_file))

.PHONY: clean
clean:
	rm -rf **/main $(wave_file)
