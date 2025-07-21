`timescale 1ns / 1ps

//----------------- debounce_pushbutton -----------------
module microwave_debounce_pushbutton (
    input clk,   // 100MHz clock input 
    input noise_btn,   // input to increase 10% duty cycle 
    output clean_btn     // debounce inc button
);

 wire w_clk4hz_enable;   // slow clock enable signal for debouncing FFs
 reg[27:0] r_counter_debounce=0;  // counter for creating slow clock enable signals 
 wire w_Q1_DFF1, w_Q2_DFF2;  // temporary flip-flop signals for debouncing the increasing button
 reg[1:0] r_motor_dir; 
  // Debouncing 2 buttons for inc/dec duty cycle 
  // Firstly generate slow clock enable for debouncing flip-flop (4Hz)
  
 always @(posedge clk)
 begin
   r_counter_debounce <= r_counter_debounce + 1;
   if (r_counter_debounce >= 10000000)   
    r_counter_debounce <= 0;
 end

 // 0.00000001sec(10ns) x 25000000 = 0.25sec(250ms)
 // 250ms가 되면 4Hz의 1주기를 나타내는 w_clk4hz_enable이 1로 set하여
 // DFF의 4Hz clock이 동작 되도록 한다. 
 assign w_clk4hz_enable = r_counter_debounce == 10000000 ? 1:0;

 microwave_dff u_microwave_DFF1(clk,w_clk4hz_enable,noise_btn,w_Q1_DFF1);
 microwave_dff u_microwave_DFF2(clk,w_clk4hz_enable,w_Q1_DFF1, w_Q2_DFF2); 
 assign clean_btn =  w_Q1_DFF1 & (~w_Q2_DFF2) & w_clk4hz_enable;
 
 endmodule