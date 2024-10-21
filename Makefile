.PHONY: build prog clean

VFILES=src/top.v

cpu.json: synth.ys $(VFILES)
	yosys -q -l yosys.log synth.ys 

ulx3s_out.config: cpu.json
	nextpnr-ecp5 --85k --json cpu.json \
		--package CABGA381 \
		--lpf ulx3s_v20.lpf \
		-q --Werror -l nextpnr.log \
		--textcfg ulx3s_out.config 

ulx3s.bit: ulx3s_out.config
	ecppack ulx3s_out.config ulx3s.bit

build: ulx3s.bit

prog: ulx3s.bit
	fujprog ulx3s.bit

clean:
	rm -rf cpu.json ulx3s_out.config ulx3s.bit
