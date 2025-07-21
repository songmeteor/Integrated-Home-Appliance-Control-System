`timescale 1ns / 1ps

//-------------------  DFF -----------------------
// Debouncing DFFs for push buttons on FPGA
// 4Hz 주파수의 1주기가 250ms 100MHz/4 --> 25,000,000cycle을 count하면 
// w_clk4hz_enable이 1로 set되어 en이 1로 mapping 된다. 
module microwave_dff (
    input clk,
    input en,
    input D,
    output reg Q
);  

  always @(posedge clk)
  begin 
  if (en == 1) // slow clock enable signal 
    Q <= D;
  end 
endmodule