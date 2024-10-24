module registers(
  input clk,
  input srst,

  input   [3:0] regno,
  input         store,
  input  [15:0] data_in,
  output [15:0] value,

  // Access modes
  input [1:0] As,
  input       bytemode,
  input       post_inc,
  input       sp_dec,

  // Flags updated from ALU operation
  input       alu_flags_store,
  input [3:0] alu_flags,

  // External access to special registers
  output [15:0] flags
);
  // Special registers
  localparam [3:0]  PC = 0;
  localparam [3:0]  SP = 1;
  localparam [3:0]  SR = 2;
  localparam [3:0] CG2 = 3;

  // Storage
  reg [15:0] regs [0:15];

  // Read requested register (always)
  reg [15:0] read_value;

  always @(*) begin
    case (regno)
      SP:      read_value = sp_value;
      SR: case (As)
        0:     read_value = regs[SR];
        1:     read_value = 16'd0;
        2:     read_value = 16'd4;
        3:     read_value = 16'd8;
      endcase
      CG2: case (As)
        0:     read_value = 16'd0;
        1:     read_value = 16'd1;
        2:     read_value = 16'd2;
        3:     read_value = -16'd1;
      endcase
      default: read_value = regs[regno];
    endcase
  end

  assign value = read_value;
  
  // Store to registers
  reg [15:0] store_value;

  always @(*) begin
    if (post_inc) begin
      if ((regno > SP) & bytemode) store_value = read_value + 1;
      else                         store_value = read_value + 2;
    end
    else store_value = bytemode ? { 8'b0, data_in[7:0] } : data_in[15:0];
  end

  always @(posedge clk) begin
    if (srst) begin
      regs[PC] <= 0;
      regs[SR] <= 0;
    end
    else if (store | post_inc) regs[regno] <= store_value;
  end

  // Stack pointer decrement handling
  wire [15:0] sp_value;
  reg         sp_dec_done;

  assign sp_value = (sp_dec & ~sp_dec_done) ? regs[SP] - 2 : regs[SP];
  always @(posedge clk) begin
    sp_dec_done <= sp_dec;
    if (sp_dec & ~sp_dec_done) regs[SP] <= regs[SP] - 2;
  end

  // Status register flags handling
  wire [15:0] sr_updated;
  assign flags = regs[SR];

  assign sr_updated[ 2:0] = alu_flags[ 2:0];
  assign sr_updated[ 7:3] = regs[SR] [ 7:3];
  assign sr_updated[   8] = alu_flags[   3];
  assign sr_updated[15:9] = regs[SR] [15:9];

  always @(posedge clk) begin
    if (alu_flags_store) regs[SR] <= sr_updated;
  end
endmodule
