module image_write #(
    parameter WIDTH = 10,
    HEIGHT = 5,
    OUTPUT_FILE = "../images/output.bmp",
    BMP_HEADER_NUM = 54  // Header for the bmp file
) (
    input HCLK,  // Clock
    HRESET,  // Reset (active low)
    input HSYNC,  // Hsync pulse
    input [7:0] DATA_WRITE_R0,  // 8 bit Red data (odd)
    DATA_WRITE_G0,  // 8 bit Green data (odd)
    DATA_WRITE_B0,  // 8 bit Blue data (odd)
    DATA_WRITE_R1,  // 8 bit Red data (even)
    DATA_WRITE_G1,  // 8 bit Green data (even)
    DATA_WRITE_B1,  // 8 bit Blue data (even)
    output reg write_done,
    output reg write_file_done
);
  integer bmpHeader[0:BMP_HEADER_NUM - 1];
  reg [7:0] bmpOut[0:WIDTH*HEIGHT*3-1];  // Temporary memory for the output image
  reg [18:0] pixelDataCount;  // For creating the done flag
  wire done;  // Done flag

  // Counting variables
  integer i;
  integer rowIndex, colIndex;
  integer k;
  integer file;

  // --- Header data for bmp file ---
  initial begin
    bmpHeader[0]  = 66;
    bmpHeader[1]  = 77;
    bmpHeader[2]  = 54;
    bmpHeader[3]  = 0;
    bmpHeader[4]  = 18;
    bmpHeader[5]  = 0;
    bmpHeader[6]  = 0;
    bmpHeader[7]  = 0;
    bmpHeader[8]  = 0;
    bmpHeader[9]  = 0;
    bmpHeader[11] = 0;
    bmpHeader[10] = 54;
    bmpHeader[12] = 0;
    bmpHeader[13] = 0;
    bmpHeader[14] = 40;
    bmpHeader[15] = 0;
    bmpHeader[16] = 0;
    bmpHeader[17] = 0;
    bmpHeader[18] = 0;
    bmpHeader[19] = 3;
    bmpHeader[20] = 0;
    bmpHeader[21] = 0;
    bmpHeader[22] = 0;
    bmpHeader[23] = 2;
    bmpHeader[24] = 0;
    bmpHeader[25] = 0;
    bmpHeader[26] = 1;
    bmpHeader[27] = 0;
    bmpHeader[28] = 24;
    bmpHeader[29] = 0;
    bmpHeader[30] = 0;
    bmpHeader[31] = 0;
    bmpHeader[32] = 0;
    bmpHeader[33] = 0;
    bmpHeader[34] = 0;
    bmpHeader[35] = 0;
    bmpHeader[36] = 0;
    bmpHeader[37] = 0;
    bmpHeader[38] = 0;
    bmpHeader[39] = 0;
    bmpHeader[40] = 0;
    bmpHeader[41] = 0;
    bmpHeader[42] = 0;
    bmpHeader[43] = 0;
    bmpHeader[44] = 0;
    bmpHeader[45] = 0;
    bmpHeader[46] = 0;
    bmpHeader[47] = 0;
    bmpHeader[48] = 0;
    bmpHeader[49] = 0;
    bmpHeader[50] = 0;
    bmpHeader[51] = 0;
    bmpHeader[52] = 0;
    bmpHeader[53] = 0;
  end

  // Row and column counting 
  always @(posedge HCLK, negedge HRESET) begin
    if (!HRESET) begin
      rowIndex <= 0;
      colIndex <= 0;
    end else begin

      if (HSYNC) begin
        if (colIndex == WIDTH / 2 - 1) begin
          colIndex <= 0;
          rowIndex <= rowIndex + 1;
        end else colIndex <= colIndex + 1;
      end
    end
  end

  // Writing data to the temp memory
  always @(posedge HCLK, negedge HRESET) begin
    if (!HRESET) begin
      for (k = 0; k < WIDTH * HEIGHT * 3; k = k + 1) begin
        bmpOut[k] <= 0;
      end
    end else begin
      if (HSYNC) begin
        bmpOut[WIDTH*3*(HEIGHT-rowIndex-1)+6*colIndex+2] <= DATA_WRITE_R0;
        bmpOut[WIDTH*3*(HEIGHT-rowIndex-1)+6*colIndex+1] <= DATA_WRITE_G0;
        bmpOut[WIDTH*3*(HEIGHT-rowIndex-1)+6*colIndex+0] <= DATA_WRITE_B0;
        bmpOut[WIDTH*3*(HEIGHT-rowIndex-1)+6*colIndex+5] <= DATA_WRITE_R1;
        bmpOut[WIDTH*3*(HEIGHT-rowIndex-1)+6*colIndex+4] <= DATA_WRITE_G1;
        bmpOut[WIDTH*3*(HEIGHT-rowIndex-1)+6*colIndex+3] <= DATA_WRITE_B1;
      end
    end
  end

  // Data counting
  always @(posedge HCLK, negedge HRESET) begin
    begin
      if (~HRESET) pixelDataCount <= 0;
      else if (HSYNC) pixelDataCount <= pixelDataCount + 1;
    end
  end

  assign done = (pixelDataCount == WIDTH*HEIGHT/2-1) ? 1'b1 : 1'b0; // Set the done flag once all pixels were processed


  always @(posedge HCLK, negedge HRESET) begin
    begin
      if (~HRESET) write_done <= 0;
      else write_done <= done;
    end
  end

  // --- Write .bmp file ---
  initial file = $fopen(OUTPUT_FILE, "wb+");

  always @(write_done) begin
    if (write_done == 1'b1) begin
      // Write the header
      for (i = 0; i < BMP_HEADER_NUM; i = i + 1) begin
        $fwrite(file, "%c", bmpHeader[i][7:0]);
      end

      for (i = 0; i < WIDTH * HEIGHT * 3; i = i + 6) begin
        // Write the image data to the file
        $fwrite(file, "%c", bmpOut[i+0][7:0]);
        $fwrite(file, "%c", bmpOut[i+1][7:0]);
        $fwrite(file, "%c", bmpOut[i+2][7:0]);
        $fwrite(file, "%c", bmpOut[i+3][7:0]);
        $fwrite(file, "%c", bmpOut[i+4][7:0]);
        $fwrite(file, "%c", bmpOut[i+5][7:0]);

        $display("%h", bmpOut[i+0][7:0]);
        $display("%h", bmpOut[i+1][7:0]);
        $display("%h", bmpOut[i+2][7:0]);
        $display("%h", bmpOut[i+3][7:0]);
        $display("%h", bmpOut[i+4][7:0]);
        $display("%h", bmpOut[i+5][7:0]);
      end

      write_file_done = 1'b1;
    end
  end

endmodule
