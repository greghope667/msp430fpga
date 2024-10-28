module decoder_tb();

  reg clk;
  reg srst;

  wire [15:0] rom [0:15];
  assign rom[0] = 16'h4315;  // mov #1, r5
  assign rom[1] = 16'h4326;  // mov #2, r6
  assign rom[2] = 16'h4337;  // mov #-1, r7
  assign rom[3] = 16'h4378;  // mov.b #ff, r8
  assign rom[4] = 16'h4749;  // mov.b r7, r9
  assign rom[5] = 16'h4634;  // mov @r6+, r4
  assign rom[6] = 16'h4634;  // mov @r6+, r4
  assign rom[7] = 16'h4035;  // mov #x1234, r5
  assign rom[8] = 16'h1234;
  assign rom[9] = 16'h4216;  // mov &10, r6
  assign rom[10] = 16'h000a;
  assign rom[11] = 16'h4300;  // br #0

  initial begin
    clk = 0;
    srst = 1;

    $dumpfile("decoder_tb.vcd");
    $dumpvars(0, decoder_tb);

    #4 srst = 0;
    #100 $finish;
  end
  initial forever #1 clk=~clk;

  /* verilator lint_off UNUSEDSIGNAL */
  wire bytemode;
  wire [1:0] As;
  wire [3:0] regno;
  wire reg_store, reg_inc;
  wire s_store, s_read;
  wire ram_store, ram_read;

  wire [15:0] reg_bus;
  wire [15:0] flags;

  reg [15:0] data_bus;
  reg [15:0] s;
  /* verilator lint_on UNUSEDSIGNAL */

  always @(posedge clk) if (s_store) s <= ram_read ? data_bus : reg_bus;

  reg [3:0] ram_address;
  always @(posedge clk) ram_address <= reg_bus[4:1] + (ram_read ? data_bus[4:1] : 0);

  always @(*) begin
    if (ram_read) data_bus = rom[ram_address];
    else if (s_read) data_bus = s;
    else data_bus = 'x;
  end

  decoder decoder(
    .clk(clk), .srst(srst), .data_in(data_bus),
    .bytemode(bytemode),
    .As(As), .regno(regno), .reg_store(reg_store), .reg_inc(reg_inc),
    .s_store(s_store), .s_read(s_read),
    .ram_store(ram_store), .ram_read(ram_read)
  );

  registers registers(
    .clk(clk), .srst(srst), .data_in(data_bus),
    .bytemode(bytemode),
    .As(As), .regno(regno), .store(reg_store), .post_inc(reg_inc),
    .alu_flags_store(0), .alu_flags(0), .flags(flags),
    .sp_dec(0),
    .value(reg_bus)
  );

endmodule
