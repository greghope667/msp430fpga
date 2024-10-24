VFLAGS:=--trace --Wall --timing -I../src
CXXFLAGS:=-Os -I/usr/share/verilator/include

VCDS:=example_tb.vcd registers_tb.vcd

vcds: $(VCDS)

%_tb.vcd: obj_dir/V%_tb
	./$<

obj_dir/V%_tb: %_tb.v
	verilator --binary $(VFLAGS) $<

obj_dir/V%.mk: ../src/%.v
	verilator --cc $(VFLAGS) $<

obj_dir/libV%.a: obj_dir/V%.mk
	make -C obj_dir -f $(notdir $<)

obj_dir/V%_tb: %_tb.cpp obj_dir/libV%.a
	g++ $(CXXFLAGS) $^ obj_dir/libverilated.a -o $@

clean:
	rm -f *.vcd
	rm -r obj_dir
