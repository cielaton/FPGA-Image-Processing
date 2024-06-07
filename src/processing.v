`include "parameter.v"
module image_read #(
    parameter WIDTH = 768,
    HEIGHT = 512,
    INPUT_FILE = "../images/kodim24.hex",
    STARTUP_DELAY = 100,  //Delay during startup time
    HSYNC_DELAY = 160,  //Hsync pulse delay
    BRIGHTNESS_VALUE = 100,  //For brightness operation
    THRESHOLD = 90,  //For threshold operation
    SIGN = 1  /*
              For brightness operation.
              SIGN = 0 -> Brightness subtraction
              SIGN = 1 -> Brightness addition
              */
) (
    input HCLK,  // Clock
    input HRESET,  // Reset (active low)
    output VSYNC,  // Indicate whether the entire image is transmitted
    output reg HSYNC,  // Indicate whether one line of the image is transmitted

    output reg [7:0] DATA_R0,  // 8 bit Red data (even)
    output reg [7:0] DATA_G0,  // 8 bit Green data (even)
    output reg [7:0] DATA_B0,  // 8 bit Blue data (even)
    output reg [7:0] DATA_R1,  // 8 bit Red data (odd)
    output reg [7:0] DATA_G1,  // 8 bit Green data (odd)
    output reg [7:0] DATA_B1,  // 8 bit Blue data (odd)
    // We will process and transmit 2 pixels in parallel for faster processing
    output ctrl_done  // Done flag
);

  parameter sizeOfWidth = 8;  // Data width
  parameter imageDataLenght = WIDTH * HEIGHT * 3;  // Lenght in bytes, each byte represent one of Red, Green, Blue value

  // local parameters for FSM
  localparam ST_IDLE = 2'b00;  // Idle state
  localparam ST_VSYNC = 2'b01;  // State for creating vsync
  localparam ST_HSYNC = 2'b10;  // State for creating hsync
  localparam ST_DATA = 2'b11;  // State for data processing

  reg [1:0] currentState, nextState;
  reg start;  // Signal the FSM begin to operate
  reg HRESETDelay;  // Use to create start signal
  reg vsyncControlSignal, hsyncControlSignal;
  reg [8:0] vsyncControlCounter, hsyncControlCounter;
  reg dataProcessingControlSignal;

  reg [7:0] totalMemory[0:imageDataLenght - 1];  // Memory to store 8-bit data image 

  // Temporary memory to save image data
  integer tempBMP[0:imageDataLenght - 1];
  integer tempRedValue[0:WIDTH * HEIGHT - 1];
  integer tempGreenValue[0:WIDTH * HEIGHT - 1];
  integer tempBlueValue[0:WIDTH * HEIGHT - 1];

  integer i, j;  // Counting variables

  integer
      tempConBriR0,
      tempConBriR1,
      tempConBriG0,
      tempConBriG1,
      tempConBriB0,
      tempConBriB1;  // Temporary variables in contrast and brightness operation

  integer
      tempInvThre,
      tempInvThre1,
      tempInvThre2,
      tempInvThre4;  // Temporary variables in invert and threshold operation

  reg [ 9:0] rowIndex;
  reg [10:0] colIndex;
  reg [18:0] pixelDataCount;  // For creating the done flag

  // --- READING IMAGE ---
  initial $readmemh(INPUT_FILE, totalMemory, 0, imageDataLenght - 1);

  always @(start) begin
    if (start == 1'b1) begin
      // Read image hex value into temporary varibale
      for (i = 0; i < WIDTH * HEIGHT * 3; i = i + 1) begin
        tempBMP[i] = totalMemory[i][7:0];
      end

      // Matlab script to convert from bitmap image to hex process from the last row to the first row, so the verilog code need to operate the same.
      for (i = 0; i < HEIGHT; i = i + 1) begin
        for (j = 0; j < WIDTH; j = j + 1) begin
          tempRedValue[WIDTH*i+j]   = tempBMP[WIDTH*3*(HEIGHT-i-1)+3*j+0];
          tempGreenValue[WIDTH*i+j] = tempBMP[WIDTH*3*(HEIGHT-i-1)+3*j+1];
          tempBlueValue[WIDTH*i+j]  = tempBMP[WIDTH*3*(HEIGHT-i-1)+3*j+2];
        end
      end
    end
  end

  //--- BEGIN TO READ IMAGE FILE ONCE RESET WAS HIGH ---

  always @(posedge HCLK, negedge HRESET) begin
    if (!HRESET) begin
      start <= 0;
      HRESETDelay <= 0;
    end else begin
      HRESETDelay <= HRESET;
      if (HRESET == 1'b1 && HRESETDelay == 1'b0) start <= 1'b1;
      else start <= 1'b0;
    end
  end

  /*--- FSM for reading RGB888 data from memory ---
    --- Creating hsync and vsync pulse --- */

  always @(posedge HCLK, negedge HRESET) begin
    if (~HRESET) currentState <= ST_IDLE;
    else currentState <= nextState;
  end

  //--- State transition ---

  always @(*) begin
    case (currentState)
      ST_IDLE: begin
        if (start) nextState = ST_VSYNC;
        else nextState = ST_IDLE;
      end
      ST_VSYNC: begin
        if (vsyncControlCounter == STARTUP_DELAY) nextState = ST_HSYNC;
        else nextState = ST_VSYNC;
      end
      ST_HSYNC: begin
        if (hsyncControlCounter == HSYNC_DELAY) nextState = ST_DATA;
        else nextState = ST_HSYNC;
      end
      ST_DATA: begin
        if (ctrl_done) nextState = ST_IDLE;
        else begin
          if (colIndex == WIDTH - 2) nextState = ST_HSYNC;
          else nextState = ST_DATA;
        end
      end
    endcase
  end

  //--- Counting for time period of vsync, hsync, data processing ---

  always @(*) begin
    vsyncControlSignal = 0;
    hsyncControlSignal = 0;
    dataProcessingControlSignal = 0;

    case (currentState)
      ST_VSYNC: vsyncControlSignal = 1;
      ST_HSYNC: hsyncControlSignal = 1;
      ST_DATA:  dataProcessingControlSignal = 1;
    endcase
  end

  // Counter for vsync, hsync
  always @(posedge HCLK, negedge HRESET) begin
    begin
      if (~HRESET) begin
        vsyncControlCounter <= 0;
        hsyncControlCounter <= 0;
      end else begin
        if (vsyncControlSignal) vsyncControlCounter <= vsyncControlCounter + 1;
        else vsyncControlCounter <= 0;
        if (hsyncControlSignal) hsyncControlCounter <= hsyncControlCounter + 1;
        else hsyncControlCounter <= 0;
      end
    end
  end

  // Counting column and row index for reading memory
  always @(posedge HCLK, negedge HRESET) begin
    if (~HRESET) begin
      rowIndex <= 0;
      colIndex <= 0;
    end else begin
      if (dataProcessingControlSignal) begin
        if (colIndex == WIDTH - 2) begin
          rowIndex <= rowIndex + 1;
          colIndex <= 0;
        end else colIndex <= colIndex + 2;  // Reading 2 pixels in parallel
      end
    end
  end

  //--- Data counting ---

  always @(posedge HCLK, negedge HRESET) begin
    if (~HRESET) pixelDataCount <= 0;
    else begin
      if (dataProcessingControlSignal) pixelDataCount <= pixelDataCount + 1;
    end
  end

  assign VSYNC = vsyncControlSignal;
  assign ctrl_done = (pixelDataCount == 196607) ? 1'b1 : 1'b0;

  //--- Image processing ---

  always @(posedge HCLK) begin
    HSYNC   = 1'b0;
    DATA_R0 = 0;
    DATA_G0 = 0;
    DATA_B0 = 0;
    DATA_R1 = 0;
    DATA_G1 = 0;
    DATA_B1 = 0;

    if (dataProcessingControlSignal) begin
      HSYNC = 1'b1;
`ifdef BRIGHTNESS_OPERATION
      // BRIGHTNESS ADDING OPERATION
      if (SIGN == 1) begin
        tempConBriR0 = tempRedValue[WIDTH*rowIndex+colIndex] + BRIGHTNESS_VALUE;
        if (tempConBriR0 > 255) DATA_R0 = 255;
        else DATA_R0 = tempRedValue[WIDTH*rowIndex+colIndex] + BRIGHTNESS_VALUE;

        tempConBriR1 = tempRedValue[WIDTH*rowIndex+colIndex+1] + BRIGHTNESS_VALUE;
        if (tempConBriR1 > 255) DATA_R1 = 255;
        else DATA_R1 = tempRedValue[WIDTH*rowIndex+colIndex+1] + BRIGHTNESS_VALUE;

        tempConBriG0 = tempGreenValue[WIDTH*rowIndex+colIndex] + BRIGHTNESS_VALUE;
        if (tempConBriG0 > 255) DATA_G0 = 255;
        else DATA_G0 = tempGreenValue[WIDTH*rowIndex+colIndex] + BRIGHTNESS_VALUE;

        tempConBriG1 = tempGreenValue[WIDTH*rowIndex+colIndex+1] + BRIGHTNESS_VALUE;
        if (tempConBriG1 > 255) DATA_G1 = 255;
        else DATA_G1 = tempGreenValue[WIDTH*rowIndex+colIndex+1] + BRIGHTNESS_VALUE;

        tempConBriB0 = tempBlueValue[WIDTH*rowIndex+colIndex] + BRIGHTNESS_VALUE;
        if (tempConBriB0 > 255) DATA_B0 = 255;
        else DATA_B0 = tempBlueValue[WIDTH*rowIndex+colIndex] + BRIGHTNESS_VALUE;

        tempConBriB1 = tempBlueValue[WIDTH*rowIndex+colIndex+1] + BRIGHTNESS_VALUE;
        if (tempConBriB1 > 255) DATA_B1 = 255;
        else DATA_B1 = tempBlueValue[WIDTH*rowIndex+colIndex+1] + BRIGHTNESS_VALUE;
      end  // BRIGHTNESS SUBTRACTION OPERATION
      else begin
        tempConBriR0 = tempRedValue[WIDTH*rowIndex+colIndex] - BRIGHTNESS_VALUE;
        if (tempConBriR0 < 0) DATA_R0 = 0;
        else DATA_R0 = tempRedValue[WIDTH*rowIndex+colIndex] - BRIGHTNESS_VALUE;

        tempConBriR1 = tempRedValue[WIDTH*rowIndex+colIndex+1] - BRIGHTNESS_VALUE;
        if (tempConBriR1 < 0) DATA_R1 = 0;
        else DATA_R1 = tempRedValue[WIDTH*rowIndex+colIndex+1] - BRIGHTNESS_VALUE;

        tempConBriG0 = tempGreenValue[WIDTH*rowIndex+colIndex] - BRIGHTNESS_VALUE;
        if (tempConBriG0 < 0) DATA_G0 = 0;
        else DATA_G0 = tempGreenValue[WIDTH*rowIndex+colIndex] - BRIGHTNESS_VALUE;

        tempConBriG1 = tempGreenValue[WIDTH*rowIndex+colIndex+1] - BRIGHTNESS_VALUE;
        if (tempConBriG1 < 0) DATA_G1 = 0;
        else DATA_G1 = tempGreenValue[WIDTH*rowIndex+colIndex+1] - BRIGHTNESS_VALUE;

        tempConBriB0 = tempBlueValue[WIDTH*rowIndex+colIndex] - BRIGHTNESS_VALUE;
        if (tempConBriB0 < 0) DATA_B0 = 0;
        else DATA_B0 = tempBlueValue[WIDTH*rowIndex+colIndex] - BRIGHTNESS_VALUE;

        tempConBriB1 = tempBlueValue[WIDTH*rowIndex+colIndex+1] - BRIGHTNESS_VALUE;
        if (tempConBriB1 < 0) DATA_B1 = 0;
        else DATA_B1 = tempBlueValue[WIDTH*rowIndex+colIndex+1] - BRIGHTNESS_VALUE;
      end
`endif

`ifdef INVERT_OPERATION
      tempInvThre2 = (tempRedValue[WIDTH*rowIndex+colIndex] + tempGreenValue[WIDTH*rowIndex+colIndex] + tempBlueValue[WIDTH*rowIndex+colIndex]) / 3;
      DATA_R0 = 255 - tempInvThre2;
      DATA_G0 = 255 - tempInvThre2;
      DATA_B0 = 255 - tempInvThre2;

      tempInvThre4 = (tempRedValue[WIDTH*rowIndex+colIndex + 1] + tempGreenValue[WIDTH*rowIndex+colIndex + 1] + tempBlueValue[WIDTH*rowIndex+colIndex + 1]) / 3;
      DATA_R1 = 255 - tempInvThre4;
      DATA_G1 = 255 - tempInvThre4;
      DATA_B1 = 255 - tempInvThre4;
`endif

`ifdef THRESHOLD_OPERATION
      tempInvThre = (tempRedValue[WIDTH*rowIndex+colIndex] + tempGreenValue[WIDTH*rowIndex+colIndex] + tempBlueValue[WIDTH*rowIndex+colIndex]) / 3;
      if (tempInvThre > THRESHOLD) begin
        DATA_R0 = 255;
        DATA_G0 = 255;
        DATA_B0 = 255;
      end else begin
        DATA_R0 = 0;
        DATA_G0 = 0;
        DATA_B0 = 0;
      end

      tempInvThre1 = (tempRedValue[WIDTH*rowIndex+colIndex+1] + tempGreenValue[WIDTH*rowIndex+colIndex+1] + tempBlueValue[WIDTH*rowIndex+colIndex+1]) / 3;
      if (tempInvThre1 > THRESHOLD) begin
        DATA_R1 = 255;
        DATA_G1 = 255;
        DATA_B1 = 255;
      end else begin
        DATA_R1 = 0;
        DATA_G1 = 0;
        DATA_B1 = 0;
      end
`endif
    end
  end

endmodule
