module top(
  input         clk_25mhz,
  input   [6:0] btn,
  output  [7:0] led,
  output        wifi_gpio0
);

  wire clk;
  assign clk = clk_25mhz;

  wire rst_n;
  assign rst_n = btn[0];

  assign wifi_gpio0 = 1'b1;

  /// Application

  reg [31:0] counter;
  assign led = counter[26:19];

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) counter <= 0;
    else counter <= counter + 1;
  end

endmodule