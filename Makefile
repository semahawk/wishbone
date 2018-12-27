wave_file = wave.vcd

compiler ?= iverilog
compiler_opts ?= -g2012 -DWAVE_FILE='"$(wave_file)"'
runtime ?= vvp
viewer ?= gtkwave

files = $(wildcard *.sv)

main: $(files)
	$(compiler) $(compiler_opts) -o $@ $(files)

.PHONY: run
run: main
	$(runtime) $<

.PHONY: wave
wave: run
	$(viewer) $(wave_file)

.PHONY: clean
clean:
	rm -rf main $(wave_file)
