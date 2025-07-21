`timescale 1ns / 1ps

module microwave_servo_controller(
    input           clk,    
    input           reset,  
    input           door,   
    output          servo   
);

parameter PWM_PERIOD = 2_000_000; 
parameter DUTY_0_DEG = 50_000;    
parameter DUTY_90_DEG = 150_000;   

reg [19:0] pwm_counter;    
reg [19:0] duty_cycle;    
reg        door_prev;     
reg        servo_out;     

assign servo = servo_out;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pwm_counter <= 0;
        duty_cycle  <= DUTY_0_DEG; 
        door_prev   <= 0;
        servo_out   <= 0;
    end else begin
        if (pwm_counter < PWM_PERIOD) begin
            pwm_counter <= pwm_counter + 1;
        end else begin
            pwm_counter <= 0;
        end

        if (pwm_counter < duty_cycle) begin
            servo_out <= 1;
        end else begin
            servo_out <= 0;
        end

        door_prev <= door;

        if (door == 1 && door_prev == 0) begin
            duty_cycle <= DUTY_90_DEG; 
        end
        // ??? ???? (1 -> 0): ?? ????
        else if (door == 0 && door_prev == 1) begin
            duty_cycle <= DUTY_0_DEG; 
        end
    end
end

endmodule