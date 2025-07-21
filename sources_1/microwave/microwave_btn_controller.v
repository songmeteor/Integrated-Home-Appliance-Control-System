`timescale 1ns / 1ps

module microwave_btn_controller(
    input       clk,
    input       reset,
    input       btnU,
    input       btnL,
    input       btnC,
    input       btnD,
    input [2:0] mode,
    output reg [13:0] run_time
    );

    // parameter ∆ƒ¿œ∏∂¥Ÿ ¡§¿««ÿ¡‡æﬂµ ?? 
    parameter IDLE   = 3'b000,
              SET    = 3'b001,
              RUN    = 3'b010,
              STOP   = 3'b011,
              FINISH = 3'b100;   

    reg [26:0]  tick_counter = 0;

    wire tick_1s = (tick_counter == 100_000_000-1);  

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick_counter <= 0;
        end else if (tick_counter == 100_000_000-1)
            tick_counter <= 0;
        else
            tick_counter <= tick_counter + 1;
    end

    always @ (posedge clk, posedge reset) begin
        if(reset) begin
            run_time <= 0;
        end else begin
            if(btnU && (run_time < 14'd5930) && (mode == SET)) run_time <= run_time + 14'd30;
            else if(btnD && (run_time > 30) && (mode == SET))   run_time <= run_time - 14'd30;
            else if((run_time > 0) && tick_1s && (mode == RUN))run_time <= run_time - 1;
            else                                               run_time <= run_time;
        end
    end

endmodule
