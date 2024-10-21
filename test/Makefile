VFLAGS:=--trace --Wall --timing -I../src

obj_dir/V%: %.v
	verilator --binary $(VFLAGS) $<

%.vcd: obj_dir/V%
	./$<

clean:
	rm -f *.vcd
	rm -r obj_dir