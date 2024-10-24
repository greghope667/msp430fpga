module ram
  # ( parameter ADDR_WIDTH = 12 )
(
  input clk,
  input store,
  input bytemode,

  input [ADDR_WIDTH-1:0] address,

  input  [15:0] data_in,
  output [15:0] data_out
);
  wire parity;
  assign parity = address[0];

  wire [ADDR_WIDTH-2:0] addr_i;
  assign addr_i = address[ADDR_WIDTH-1:1];

/* Storage is in two banks, each 16-bit word is split in half.
 * lsb (7:0) stored in 'even', msb (15:8) in 'odd'
 * 'cross_' here indicates moving data between the lsb of the
 * data bus and the 'odd' memory bank */
  wire cross_;
  reg  load_cross;
  assign cross_ = parity & bytemode;
  always @(posedge clk) load_cross <= cross_;

  // Store modes
  wire store_low, store_high, store_cross;
  assign store_cross = store & parity;
  assign store_low = store & ~store_cross;
  assign store_high = store & ~bytemode;

  // Banks and output
  wire [7:0] data_even, data_odd;

  bank #(ADDR_WIDTH-1) even(
    .clk(clk),
    .store(store_low),
    .address(addr_i),
    .data_in(data_in[7:0]),
    .data_out(data_even)
  );

  bank #(ADDR_WIDTH-1) odd(
    .clk(clk),
    .store(store_cross|store_high),
    .address(addr_i),
    .data_in(cross_ ? data_in[7:0] : data_in[15:8]),
    .data_out(data_odd)
  );

  assign data_out [7:0] = load_cross ? data_odd : data_even;
  assign data_out[15:8] = data_odd;
endmodule

/* This bank of ram is a FPGA memory block.
 * Splitting off this component helps (me) make sure this will
 * get synthesised as a memory bank and not accidentally end up
 * with thousands of flip-flops */

/* verilator lint_off MULTITOP */
/* verilator lint_off DECLFILENAME */

module bank
  # ( parameter ADDR_WIDTH = 1 )
(
  input clk,
  input store,

  input [ADDR_WIDTH-1:0] address,

  input      [7:0] data_in,
  output reg [7:0] data_out
);
  reg [7:0] storage [0:(1<<ADDR_WIDTH)-1];

  always @(posedge clk) begin
    if (store) storage[address] <= data_in;
    else data_out <= storage[address];
  end
endmodule
