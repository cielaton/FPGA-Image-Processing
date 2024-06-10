module FPGA_Image_Processing (
    input  clk,
    input  resetButton,
    input  increaseBrightness,
    input  decreaseBrightness,
    input  threshold,
    input  invert,
    output TxD,
    output started,
    output doneProcessing,
    output isTransmitted,
    output increaseBrightnessOut,
    output decreaseBrightnessOut,
    output thresholdOut,
    output invertOut

);

  wire vsync, hsync;
  wire [7:0] data_R0;
  wire [7:0] data_G0;
  wire [7:0] data_B0;
  wire [7:0] data_R1;
  wire [7:0] data_G1;
  wire [7:0] data_B1;
  wire done;
  wire [7:0] transmitData;
  wire TxD_done;
  wire write_done;

  assign increaseBrightnessOut = increaseBrightness;
  assign decreaseBrightnessOut = decreaseBrightness;
  assign thresholdOut = threshold;
  assign invertOut = invert;

  image_read imageReadComponent (
      .HCLK(clk),
      .HRESET(resetButton),
      .VSYNC(vsync),
      .HSYNC(hsync),
      .DATA_R0(data_R0),
      .DATA_G0(data_G0),
      .DATA_B0(data_B0),
      .DATA_R1(data_R1),
      .DATA_G1(data_G1),
      .DATA_B1(data_B1),
      .started(started),
      .ctrl_done(doneProcessing),
      .increaseBrightness(increaseBrightness),
      .decreaseBrightness(decreaseBrightness),
      .threshold(threshold),
      .invert(invert)
  );

  UART_transmitter transmitter (
      .clk(clk),
      .TxD_start(TxD_start),
      .TxD_data(transmitData),
      .TxD(TxD),
      .TxD_done(TxD_done)
  );

  image_write imageWriteComponent (
      .HCLK(clk),
      .HRESET(resetButton),
      .HSYNC(hsync),
      .DATA_WRITE_R0(data_R0),
      .DATA_WRITE_G0(data_G0),
      .DATA_WRITE_B0(data_B0),
      .DATA_WRITE_R1(data_R1),
      .DATA_WRITE_G1(data_G1),
      .DATA_WRITE_B1(data_B1),
      .write_done(write_done),
      .isTransmitted(isTransmitted),
      .transmitData(transmitData),
      .TxD_done(TxD_done),
      .TxD_start(TxD_start)
  );


endmodule

