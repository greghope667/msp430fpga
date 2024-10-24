#include <verilated.h>
#include "obj_dir/Vregisters.h"
#include <verilated_vcd_c.h>

int main(int argc, char** argv)
{
    VerilatedContext context{};
    context.traceEverOn(true);
    context.commandArgs(argc, argv);
    context.timeprecision(-6);
    context.timeunit(-9);

    VerilatedVcdC tfp{};
    Vregisters top{&context, "Registers"};

    top.trace(&tfp, 0);
    tfp.open("registers_tb.vcd");

    top.clk = 0;
    top.srst = 0;

    top.store = 0;
    top.As = 0;
    top.bytemode = 0;
    top.post_inc = 0;
    top.sp_dec = 0;
    top.alu_flags_store = 0;

    auto step = [&]{
        top.eval();
        tfp.dump(context.time());
        context.timeInc(1);
        top.clk = 1;
        top.eval();
        tfp.dump(context.time());
        context.timeInc(1);
        top.clk = 0;
    };

    auto check = [&](size_t value, size_t expected) {
        if (value != expected)
            std::printf(
                "Mismatch at step %zu: expected %zu actual %zu\n", 
                (size_t)context.time(), expected, value
            );
    };

    // Word write
    top.regno = 5;
    top.store = true;
    top.data_in = 0x1234;
    step();
    check(top.value, 0x1234);

    // Word ptr inc
    top.store = false;
    top.post_inc = true;
    for (int i=0; i<5; i++) {
        check(top.value, 0x1234 + 2*i);
        step();
    }

    // Byte write
    top.regno = 6;
    top.store = true;
    top.bytemode = true;
    top.data_in = 0x4321;
    top.post_inc = false;
    step();
    check(top.value, 0x21);

    // Byte ptr inc
    top.store = false;
    top.post_inc = true;
    for (int i=0; i<5; i++) {
        check(top.value, 0x21 + i);
        step();
    }

    // Stack ptr write
    top.regno = 1;
    top.store = true;
    top.bytemode = false;
    top.data_in = 0x5678;
    top.post_inc = false;
    step();
    check(top.value, 0x5678);

    // Stack ptr dec
    top.store = false;
    top.sp_dec = true;
    top.eval();
    for (int i=0; i<3; i++) {
        check(top.value, 0x5676);
        step();
    }
    top.sp_dec = false;
    step();
    top.sp_dec = true;
    top.eval();
    for (int i=0; i<3; i++) {
        check(top.value, 0x5674);
        step();
    }

    // Constants
    top.As = 0;
    top.regno = 3;
    top.eval();
    check(top.value, 0);
    top.As = 1;
    top.regno = 3;
    top.eval();
    check(top.value, 1);

    top.final();
    tfp.close();
}