`include "parameter.v"

module image_read #(
    WIDTH = 768,
    HEIGHT = 512,
    INPUT_FILE = "../images/main.hex",
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
endmodule
