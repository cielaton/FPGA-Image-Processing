module image_write #(
    parameter WIDTH = 768,
    HEIGHT = 512,
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
    output reg write_done
);

  // --- Header data for bmp file ---
  reg [7:0] BMP_header[0:BMP_HEADER_NUM];
  initial begin
    BMP_header[0]  = 66;
    BMP_header[1]  = 77;
    BMP_header[2]  = 54;
    BMP_header[3]  = 0;
    BMP_header[4]  = 18;
    BMP_header[5]  = 0;
    BMP_header[6]  = 0;
    BMP_header[7]  = 0;
    BMP_header[8]  = 0;
    BMP_header[9]  = 0;
    BMP_header[11] = 0;
    BMP_header[10] = 54;
    BMP_header[12] = 0;
    BMP_header[13] = 0;
    BMP_header[14] = 40;
    BMP_header[15] = 0;
    BMP_header[16] = 0;
    BMP_header[17] = 0;
    BMP_header[18] = 0;
    BMP_header[19] = 3;
    BMP_header[20] = 0;
    BMP_header[21] = 0;
    BMP_header[22] = 0;
    BMP_header[23] = 2;
    BMP_header[24] = 0;
    BMP_header[25] = 0;
    BMP_header[26] = 1;
    BMP_header[27] = 0;
    BMP_header[28] = 24;
    BMP_header[29] = 0;
    BMP_header[30] = 0;
    BMP_header[31] = 0;
    BMP_header[32] = 0;
    BMP_header[33] = 0;
    BMP_header[34] = 0;
    BMP_header[35] = 0;
    BMP_header[36] = 0;
    BMP_header[37] = 0;
    BMP_header[38] = 0;
    BMP_header[39] = 0;
    BMP_header[40] = 0;
    BMP_header[41] = 0;
    BMP_header[42] = 0;
    BMP_header[43] = 0;
    BMP_header[44] = 0;
    BMP_header[45] = 0;
    BMP_header[46] = 0;
    BMP_header[47] = 0;
    BMP_header[48] = 0;
    BMP_header[49] = 0;
    BMP_header[50] = 0;
    BMP_header[51] = 0;
    BMP_header[52] = 0;
    BMP_header[53] = 0;
  end
endmodule
