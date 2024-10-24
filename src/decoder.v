module decoder(
  input clk,
  input srst,

  input [15:0] data_in,

  output reg bytemode,

  // Register control lines
  output reg [1:0] As,
  output reg [3:0] regno,
  output reg       reg_store,
  output reg       reg_inc,

  // RAM control
  output reg ram_store,
  output reg ram_read,

  // Temp registers
  output reg s_store,
  output reg s_read
);
  // States
  localparam IDLE = 0;
  localparam FETCH = 1;
  localparam DECODE = 2;
  localparam MOVSOURCE = 3;
  localparam MOVDEST = 4;
  localparam ERROR = 5;

  reg [2:0] current_state;
  reg [2:0] next_state;

  always @(posedge clk) begin
    if (srst) current_state <= IDLE;
    else current_state <= next_state;
  end

  // Instruction register
  /* verilator lint_off UNUSEDSIGNAL */
  reg [15:0] instruction;
  /* verilator lint_on UNUSEDSIGNAL */
  always @(posedge clk) if (current_state == DECODE) instruction <= data_in;

  // State transitions
  always @(*) begin
    next_state = ERROR;
    case (current_state)
      IDLE: next_state = FETCH;
      FETCH: next_state = DECODE;
      DECODE: begin
        // TODO: handle other instructions
        next_state = MOVSOURCE;
      end
      MOVSOURCE: next_state = MOVDEST;
      MOVDEST: next_state = FETCH;
    endcase
  end

  // Control lines
  always @(*) begin
    bytemode  = 0;
    As        = 0;
    regno     = 0;
    reg_store = 0;
    reg_inc   = 0;
    ram_store = 0;
    ram_read  = 0;
    s_store   = 0;
    s_read    = 0;

    case (current_state)
      FETCH: begin
        regno   = 0; // PC
        As      = 2'b11; // @Rn+
        reg_inc = 1;
      end
      DECODE: begin
        ram_read = 1;
      end
      MOVSOURCE: begin
        regno    = instruction[11:8];
        As       = instruction [5:4];
        bytemode = instruction   [6];
        s_store  = 1;
      end
      MOVDEST: begin
        regno     = instruction [3:0];
        As        = { 1'b0, instruction[7] };
        bytemode  = instruction   [6];
        reg_store = 1;
        s_read    = 1;
      end
    endcase
  end

endmodule
