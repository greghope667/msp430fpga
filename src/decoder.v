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
  localparam [3:0] PC = 0;
  //localparam [3:0] SP = 1;

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

  // Load states
  localparam LOAD_IDLE = 0; // Rn out
  localparam LOAD_INDEXPC = 1; // pc+ -> MAR
  localparam LOAD_INDEXREG = 2; // Rn+MDR -> MAR
  localparam LOAD_INDIRECT = 3; // Rn -> MAR
  localparam LOAD_INCREMENT = 4; // Rn+ -> MAR
  localparam LOAD_DONE = 5; // MDR out

  reg [2:0] current_load_state;
  reg [2:0] next_load_state;

  always @(posedge clk) begin
    if (srst) current_load_state <= LOAD_IDLE;
    else current_load_state <= next_load_state;
  end

  wire load_done;
  assign load_done =
      (current_load_state == LOAD_DONE)
    | (current_load_state == LOAD_IDLE);

  // Instruction register
  reg  [15:0] instruction_reg;
  wire [15:0] instruction;

  assign instruction = current_state == DECODE ? data_in : instruction_reg;
  always @(posedge clk) if (current_state == DECODE) instruction_reg <= data_in;

  // State transitions
  always @(*) begin
    next_state = ERROR;

    case (current_state)
      IDLE: next_state = FETCH;
      FETCH: next_state = DECODE;
      DECODE: begin
        if (instruction[15:12] == 4'h4)
          next_state = MOVSOURCE;
        else
          next_state = IDLE;
      end
      MOVSOURCE: next_state = load_done ? MOVDEST : MOVSOURCE;
      MOVDEST: next_state = FETCH;
    endcase
  end

  // Load state transitons
  reg       do_load;
  reg [3:0] do_load_regno;
  reg [1:0] do_load_as;

  always @(*) begin
    next_load_state = LOAD_IDLE;

    if (do_load) begin
      if ((do_load_regno) == 2 & do_load_as[1])
        next_load_state = LOAD_IDLE;
      else if (do_load_regno == 3)
        next_load_state = LOAD_IDLE;
      else begin
        case (do_load_as)
          0: next_load_state = LOAD_IDLE;
          1: next_load_state = LOAD_INDEXPC;
          2: next_load_state = LOAD_INDIRECT;
          3: next_load_state = LOAD_INCREMENT;
        endcase
      end
    end

    case (current_load_state)
      LOAD_INDEXPC:   next_load_state = LOAD_INDEXREG;
      LOAD_INDEXREG:  next_load_state = LOAD_DONE;
      LOAD_INDIRECT:  next_load_state = LOAD_DONE;
      LOAD_INCREMENT: next_load_state = LOAD_DONE;
    endcase
  end

  always @(*) begin
    do_load       = 0;
    do_load_regno = 0;
    do_load_as    = 0;

    case (next_state)
      MOVSOURCE: begin
        do_load       = current_state != next_state;
        do_load_regno = instruction[11:8];
        do_load_as    = instruction [5:4];
      end
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
        regno     = PC;
        reg_inc   = 1;
      end
      DECODE: begin
        ram_read  = 1;
      end
      MOVSOURCE: begin
        regno     = instruction[11:8];
        As        = instruction [5:4];
        bytemode  = instruction   [6];
        s_store   = 1;
      end
      MOVDEST: begin
        regno     = instruction [3:0];
        As        = { 1'b0, instruction[7] };
        bytemode  = instruction   [6];
        reg_store = 1;
        s_read    = 1;
      end
    endcase

    case (current_load_state)
      LOAD_INDEXPC: begin
        regno    = 0;
        reg_inc  = 1;
      end
      LOAD_INDEXREG: begin
        regno    = do_load_regno;
        As       = do_load_as;
        ram_read = 1;
      end
      LOAD_INDIRECT: begin
        regno    = do_load_regno;
        As       = do_load_as;
      end
      LOAD_INCREMENT: begin
        regno    = do_load_regno;
        As       = do_load_as;
        reg_inc  = 1;
      end
      LOAD_DONE: begin
        ram_read = 1;
      end
    endcase
  end
endmodule
