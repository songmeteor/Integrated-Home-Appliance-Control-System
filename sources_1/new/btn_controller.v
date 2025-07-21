`timescale 1ns / 1ps

module btn_controller(
    input       clk,
    input       reset,
    input       btnU,
    input       btnD,
    input       btnL,
    input [1:0] mode,
    input [7:0] current_temperature,
    input [7:0] humidity, 

    output reg [7:0] target_temperature,
    output     [1:0] heat_cool_stop,
    output reg [1:0] level,
    output reg       ultrasonic_mode
    );

    parameter IDLE   = 2'b00,
              AUTO   = 2'b01,
              MANUAL = 2'b10;

    parameter LEVEL0 = 2'b00,
              LEVEL1 = 2'b01,
              LEVEL2 = 2'b10,
              LEVEL3 = 2'b11;               
 
    always @ (posedge clk, posedge reset) begin
        if(reset) begin
            target_temperature <= 24;
        end else begin
            if(btnU && (target_temperature < 8'd35) && (mode == MANUAL)) target_temperature <= target_temperature + 8'd1;
            else if(btnD && (target_temperature > 8'd18) && (mode == MANUAL)) target_temperature <= target_temperature - 8'd1;
            else  target_temperature <= target_temperature;
        end
    end 

    always @ (posedge clk, posedge reset) begin
        if(reset) begin
            ultrasonic_mode <= 0;
        end else begin
            if(btnL) begin
                ultrasonic_mode <= !ultrasonic_mode;
            end else begin
                ultrasonic_mode <= ultrasonic_mode;
            end
        end
    end

    assign heat_cool_stop = (target_temperature > current_temperature) ? 0 : ((target_temperature < current_temperature) ? 1 : 2);

    always @(*) begin
        if(current_temperature >= 24 && current_temperature <= 27 && humidity >= 40 && humidity <= 60)
        level = LEVEL0;
        else if (current_temperature >= 22 && current_temperature <= 29 && humidity >= 30 && humidity <= 70)
        level = LEVEL1;
        else if (current_temperature >= 20 && current_temperature <= 31 && humidity >= 20 && humidity <= 80)
        level = LEVEL2;
        else level = LEVEL3;                
    end

endmodule
