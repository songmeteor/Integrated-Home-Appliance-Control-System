`timescale 1ns / 1ps

module microwave_dc_motor_controller(
    input clk,
    input [2:0] mode,
    output reg dc_motor,
    output reg [1:0] in1_in2 
    );

    parameter r_DUTY_CYCLE = 5;

    parameter IDLE   = 3'b000,
              SET    = 3'b001,
              RUN    = 3'b010,
              STOP   = 3'b011,
              FINISH = 3'b100;    

    reg[3:0] r_counter_PWM = 0;

    always @(posedge clk) begin
        r_counter_PWM <= r_counter_PWM + 1;
        if (r_counter_PWM >= 9) 
            r_counter_PWM <= 0;
    end    

    always @(*) begin
        if(mode == RUN) begin
            dc_motor = r_counter_PWM < r_DUTY_CYCLE ? 1:0;
            in1_in2 = 2'b10;
        end 
        else begin
            dc_motor = 0;
            in1_in2 = 2'b11;
        end
    end
endmodule
