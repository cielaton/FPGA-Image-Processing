module transmitter (
    input clk,
    reset,
    transmit,
    input [7:0] data,
    output reg TxD
);
  reg [ 4:0] bitCounter;  // Count the number of bits that has been sent
  reg [31:0] counter;  // The number of clock ticks, used to divide the internal clock

  reg currentState, nextState;

  reg [9:0] rightShiftReg;  // Hold the value that currently being sent

  reg shift, load, clear;  // Operations

  always @(posedge clk) begin
    if (reset) begin
      currentState <= 0;
      counter <= 0;
      bitCounter <= 0;
    end else begin
      counter = counter + 1;
      if (counter >= 5208) begin
        currentState <= nextState;
        counter <= 0;

        if (load) rightShiftReg <= {1'b1, data[7:0], 1'b0};
        if (clear) bitCounter = 0;
        if (shift) begin
          rightShiftReg <= rightShiftReg >> 1;
          bitCounter <= bitCounter + 1;
        end
      end
    end
  end

  // State machine for the transmitter
  always @(currentState or bitCounter or transmit) begin
    load  <= 0;
    shift <= 0;
    clear <= 0;
    TxD   <= 1;

    case (currentState)
      0: begin
        if (transmit == 1) begin
          nextState <= 1;
          load <= 1;
          shift <= 0;
          clear <= 0;
        end else begin
          nextState <= 0;
          TxD <= 1;
        end
      end
      1: begin
        if (bitCounter >= 9) begin
          nextState <= 0;
          clear <= 1;
        end else begin
          nextState <= 1;
          shift <= 1;
          TxD <= rightShiftReg[0];
        end
      end
    endcase
  end
endmodule
