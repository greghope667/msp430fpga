module example_tb(
  output mod8
);

  reg       clk;
  reg       rst_n;
  reg [7:0] count;

  assign mod8 = (count[2:0] == 0);

  initial begin
    clk = 0;
    rst_n = 0;

    $dumpfile("example_tb.vcd");
    $dumpvars(0, example_tb);

    #4 rst_n = 1;
  end
  initial forever #1 clk=~clk;

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) count <= 0;
    else count <= count + 1;

    if (count == 255) $finish;
  end

endmodule
