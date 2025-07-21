`timescale 1ns / 1ps

module minsec_stop_tick_generator(    
    input clk,
    input reset,
    output reg tick
);

    parameter INPUT_FREQ = 100_000_000;
    parameter TICK_HZ = 1000;
    parameter TICK_COUNT = INPUT_FREQ / TICK_HZ; // 100_000

    reg [$clog2(TICK_COUNT)-1:0] r_tick_count = 0;

    always @ (posedge clk, posedge reset) begin
        if(reset) begin
            r_tick_count <= 0;
            tick <= 0;
        end else begin
            if(r_tick_count == TICK_COUNT-1) begin
                r_tick_count <= 0;
                tick <= 1'b1;
            end else begin
                r_tick_count <= r_tick_count + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule
