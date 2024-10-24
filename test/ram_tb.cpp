#include <verilated.h>
#include "obj_dir/Vram.h"
#include <verilated_vcd_c.h>

int main(int argc, char** argv)
{
    VerilatedContext context{};
    context.traceEverOn(true);
    context.commandArgs(argc, argv);
    context.timeprecision(-6);
    context.timeunit(-9);

    VerilatedVcdC tfp{};
    Vram top{&context, "Ram"};

    top.trace(&tfp, 0);
    tfp.open("ram_tb.vcd");

    top.clk = 0;
    top.store = 0;

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

    auto store = [&](uint16_t address, uint16_t value, bool bytemode=false){
        top.store = 1;
        top.bytemode = bytemode;
        top.address = address;
        top.data_in = value;
        step();
    };

    auto load = [&](uint16_t address, uint16_t expected, bool bytemode=false){
        top.store = 0;
        top.bytemode = bytemode;
        top.address = address,
        step();
        if (top.data_out != expected) {
            std::printf(
                "Mismatch at step %zu: expected %x actual %x\n",
                context.time(), expected, top.data_out
            );
        }
    };

    store(0x4, 0x1020);
    store(0x6, 0x0304);
    load(0x4, 0x1020);
    load(0x6, 0x0304);
    store(0x5, 0xaa, true);
    load(0x4, 0xaa20);

    tfp.dump(context.time());
    top.final();
    tfp.close();
}