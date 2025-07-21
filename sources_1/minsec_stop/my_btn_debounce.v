`timescale 1ns / 1ps

module my_btn_debounce(
    input clk,
    input reset,
    input noise_btn,
    input tick, 
    output reg clean_btn
);

    parameter DEBOUNCE_TICKS = 10; 
    reg [$clog2(DEBOUNCE_TICKS)-1:0] counter;
    reg previous_btn_state;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter <= 0;
            clean_btn <= 0;
            previous_btn_state <= 0;
        end else begin
            if(noise_btn != previous_btn_state) begin
                previous_btn_state <= noise_btn;
                counter <= DEBOUNCE_TICKS;
            end 
            else if (counter != 0 && tick) begin
                counter <= counter - 1;
                if (counter == 1)
                    clean_btn <= noise_btn;
            end
        end
    end
endmodule
