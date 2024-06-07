`include "parameter.v"

module simulation ();
  reg HCLK, HRESET;
  wire vsync, hsync;
  wire [7:0] data_R0;
  wire [7:0] data_G0;
  wire [7:0] data_B0;
  wire [7:0] data_R1;
  wire [7:0] data_G1;
  wire [7:0] data_B1;
  wire done;

  image_read #(
      .INPUT_FILE(`INPUT_FILE_NAME)
  ) imageReadComponent (
      .HCLK(HCLK),
      .HRESET(HRESET),
      .VSYNC(vsync),
      .HSYNC(hsync),
      .DATA_R0(data_R0),
      .DATA_G0(data_G0),
      .DATA_B0(data_B0),
      .DATA_R1(data_R1),
      .DATA_G1(data_G1),
      .DATA_B1(data_B1),
      .ctrl_done(done)
  );

  image_write #(
      .OUTPUT_FILE(`OUTPUT_FILE_NAME)
  ) imageWriteComponent (
      .HCLK(HCLK),
      .HRESET(HRESET),
      .HSYNC(hsync),
      .DATA_WRITE_R0(data_R0),
      .DATA_WRITE_G0(data_G0),
      .DATA_WRITE_B0(data_B0),
      .DATA_WRITE_R1(data_R1),
      .DATA_WRITE_G1(data_G1),
      .DATA_WRITE_B1(data_B1),
      .write_done()
  );

  // --- Test vectors ---
  initial begin
    HCLK = 0;
    forever #10 HCLK = ~HCLK;
  end

  initial begin
    HRESET = 0;
    #25 HRESET = 1;
  end
endmodule
