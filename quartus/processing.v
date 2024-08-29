`include "parameter.v"
module image_read #(
    parameter WIDTH = 10,
    HEIGHT = 5,
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
  initial begin
    totalMemory[0]   = 8'had;
    totalMemory[1]   = 8'h72;
    totalMemory[2]   = 8'h22;
    totalMemory[3]   = 8'haf;
    totalMemory[4]   = 8'h75;
    totalMemory[5]   = 8'h25;
    totalMemory[6]   = 8'ha1;
    totalMemory[7]   = 8'h68;
    totalMemory[8]   = 8'h1a;
    totalMemory[9]   = 8'h93;
    totalMemory[10]  = 8'h5a;
    totalMemory[11]  = 8'he;
    totalMemory[12]  = 8'h97;
    totalMemory[13]  = 8'h5f;
    totalMemory[14]  = 8'h15;
    totalMemory[15]  = 8'h8e;
    totalMemory[16]  = 8'h56;
    totalMemory[17]  = 8'h10;
    totalMemory[18]  = 8'h84;
    totalMemory[19]  = 8'h4e;
    totalMemory[20]  = 8'ha;
    totalMemory[21]  = 8'h7d;
    totalMemory[22]  = 8'h46;
    totalMemory[23]  = 8'h6;
    totalMemory[24]  = 8'h72;
    totalMemory[25]  = 8'h3b;
    totalMemory[26]  = 8'h1;
    totalMemory[27]  = 8'h65;
    totalMemory[28]  = 8'h2d;
    totalMemory[29]  = 8'h0;
    totalMemory[30]  = 8'ha8;
    totalMemory[31]  = 8'h6d;
    totalMemory[32]  = 8'h1d;
    totalMemory[33]  = 8'had;
    totalMemory[34]  = 8'h73;
    totalMemory[35]  = 8'h24;
    totalMemory[36]  = 8'had;
    totalMemory[37]  = 8'h74;
    totalMemory[38]  = 8'h26;
    totalMemory[39]  = 8'ha9;
    totalMemory[40]  = 8'h70;
    totalMemory[41]  = 8'h24;
    totalMemory[42]  = 8'ha7;
    totalMemory[43]  = 8'h6e;
    totalMemory[44]  = 8'h25;
    totalMemory[45]  = 8'h9d;
    totalMemory[46]  = 8'h65;
    totalMemory[47]  = 8'h1e;
    totalMemory[48]  = 8'h91;
    totalMemory[49]  = 8'h5a;
    totalMemory[50]  = 8'h16;
    totalMemory[51]  = 8'h85;
    totalMemory[52]  = 8'h4f;
    totalMemory[53]  = 8'he;
    totalMemory[54]  = 8'h78;
    totalMemory[55]  = 8'h41;
    totalMemory[56]  = 8'h4;
    totalMemory[57]  = 8'h6b;
    totalMemory[58]  = 8'h34;
    totalMemory[59]  = 8'h0;
    totalMemory[60]  = 8'ha7;
    totalMemory[61]  = 8'h6c;
    totalMemory[62]  = 8'h1e;
    totalMemory[63]  = 8'ha0;
    totalMemory[64]  = 8'h66;
    totalMemory[65]  = 8'h19;
    totalMemory[66]  = 8'ha0;
    totalMemory[67]  = 8'h67;
    totalMemory[68]  = 8'h1a;
    totalMemory[69]  = 8'ha2;
    totalMemory[70]  = 8'h69;
    totalMemory[71]  = 8'h1d;
    totalMemory[72]  = 8'ha5;
    totalMemory[73]  = 8'h6c;
    totalMemory[74]  = 8'h23;
    totalMemory[75]  = 8'ha4;
    totalMemory[76]  = 8'h6c;
    totalMemory[77]  = 8'h26;
    totalMemory[78]  = 8'ha4;
    totalMemory[79]  = 8'h6e;
    totalMemory[80]  = 8'h2a;
    totalMemory[81]  = 8'ha2;
    totalMemory[82]  = 8'h6b;
    totalMemory[83]  = 8'h2a;
    totalMemory[84]  = 8'h9f;
    totalMemory[85]  = 8'h68;
    totalMemory[86]  = 8'h29;
    totalMemory[87]  = 8'h9d;
    totalMemory[88]  = 8'h65;
    totalMemory[89]  = 8'h29;
    totalMemory[90]  = 8'haa;
    totalMemory[91]  = 8'h70;
    totalMemory[92]  = 8'h22;
    totalMemory[93]  = 8'hb3;
    totalMemory[94]  = 8'h7a;
    totalMemory[95]  = 8'h2d;
    totalMemory[96]  = 8'hb2;
    totalMemory[97]  = 8'h7a;
    totalMemory[98]  = 8'h2d;
    totalMemory[99]  = 8'h9d;
    totalMemory[100] = 8'h65;
    totalMemory[101] = 8'h1a;
    totalMemory[102] = 8'h84;
    totalMemory[103] = 8'h4c;
    totalMemory[104] = 8'h3;
    totalMemory[105] = 8'h84;
    totalMemory[106] = 8'h4b;
    totalMemory[107] = 8'h6;
    totalMemory[108] = 8'h85;
    totalMemory[109] = 8'h4e;
    totalMemory[110] = 8'hc;
    totalMemory[111] = 8'h8c;
    totalMemory[112] = 8'h55;
    totalMemory[113] = 8'h14;
    totalMemory[114] = 8'h97;
    totalMemory[115] = 8'h5f;
    totalMemory[116] = 8'h20;
    totalMemory[117] = 8'ha1;
    totalMemory[118] = 8'h69;
    totalMemory[119] = 8'h2c;
    totalMemory[120] = 8'hbd;
    totalMemory[121] = 8'h83;
    totalMemory[122] = 8'h37;
    totalMemory[123] = 8'hbc;
    totalMemory[124] = 8'h82;
    totalMemory[125] = 8'h38;
    totalMemory[126] = 8'hba;
    totalMemory[127] = 8'h81;
    totalMemory[128] = 8'h37;
    totalMemory[129] = 8'hb5;
    totalMemory[130] = 8'h7d;
    totalMemory[131] = 8'h33;
    totalMemory[132] = 8'ha6;
    totalMemory[133] = 8'h6f;
    totalMemory[134] = 8'h25;
    totalMemory[135] = 8'h98;
    totalMemory[136] = 8'h61;
    totalMemory[137] = 8'h1b;
    totalMemory[138] = 8'h89;
    totalMemory[139] = 8'h52;
    totalMemory[140] = 8'h10;
    totalMemory[141] = 8'h87;
    totalMemory[142] = 8'h50;
    totalMemory[143] = 8'h10;
    totalMemory[144] = 8'h88;
    totalMemory[145] = 8'h52;
    totalMemory[146] = 8'h13;
    totalMemory[147] = 8'h84;
    totalMemory[148] = 8'h4e;
    totalMemory[149] = 8'h10;
  end

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
  assign ctrl_done = (pixelDataCount == WIDTH * HEIGHT / 2 - 1) ? 1'b1 : 1'b0;

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

`ifdef DEFAULT
      DATA_R0 = tempRedValue[WIDTH*rowIndex+colIndex];
      DATA_G0 = tempRedValue[WIDTH*rowIndex+colIndex];
      DATA_B0 = tempRedValue[WIDTH*rowIndex+colIndex];
      DATA_R1 = tempRedValue[WIDTH*rowIndex+colIndex+1];
      DATA_G1 = tempRedValue[WIDTH*rowIndex+colIndex+1];
      DATA_B1 = tempRedValue[WIDTH*rowIndex+colIndex+1];
`endif
    end
  end

endmodule
