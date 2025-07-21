`timescale 1ns / 1ps

module dc_motor_controller(
    input       clk,
    input       reset,
    input [9:0] distance,
    input [1:0] mode,
    input [1:0] heat_cool_stop,
    input [1:0] level,

    output reg       dc_motor,
    output reg [1:0] in1_in2     
    );

    parameter IDLE   = 2'b00,
              AUTO   = 2'b01,
              MANUAL = 2'b10;

    parameter LEVEL0 = 2'b00,
              LEVEL1 = 2'b01,
              LEVEL2 = 2'b10,
              LEVEL3 = 2'b11;

    parameter DUTY_MANUAL = 5,
              DUTY_LEVEL1 = 3,
              DUTY_LEVEL2 = 5,  
              DUTY_LEVEL3 = 7;                                    

    reg [3:0] r_counter_PWM = 0;
    reg [3:0] r_DUTY_CYCLE;

    //  distance가 5cm 이하이면 모터 정지
    //  mode가 AUTO: LEVEL0 일때 모터 정지, 이후 레벨 3까지 레벨 높을 수록 모터 속도 빠르게
    //  mode가 MANUAL : heat이면 모터 역방향, cool 이면 모터 정방향 속도는 고정    

    always @(*) begin
        case (level)
            LEVEL0 : begin
                r_DUTY_CYCLE = 0;
            end
            LEVEL1 : begin
                r_DUTY_CYCLE = DUTY_LEVEL1;            
            end
            LEVEL2 : begin
                r_DUTY_CYCLE = DUTY_LEVEL2; 
            end
            LEVEL3 : begin
                r_DUTY_CYCLE = DUTY_LEVEL3;
            end
            default : begin
                r_DUTY_CYCLE = 0;
            end                                    
        endcase
    end       

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_counter_PWM <= 0;
        end else begin
            r_counter_PWM <= r_counter_PWM + 1;
            if (r_counter_PWM >= 9) 
                r_counter_PWM <= 0;            
        end
    end 

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            dc_motor <= 0;
            in1_in2  <= 2'b11; 
        end else begin
            if(distance <= 5) begin
                dc_motor <= 0;
                in1_in2  <= 2'b11; 
            end else if(mode == AUTO) begin
                dc_motor <= r_counter_PWM < r_DUTY_CYCLE;
                in1_in2  <= 2'b10; 
            end else if(mode == MANUAL) begin
                dc_motor <= r_counter_PWM < DUTY_MANUAL;
                if(heat_cool_stop == 0) begin  // heat
                    in1_in2 <= 2'b10; 
                end else if(heat_cool_stop == 1) begin  // cool
                    in1_in2 <= 2'b01; 
                end else begin       //stop
                    in1_in2 <= 2'b11;
                end
            end else begin 
                dc_motor <= 0;
                in1_in2  <= 2'b11;
            end
        end
    end
endmodule
