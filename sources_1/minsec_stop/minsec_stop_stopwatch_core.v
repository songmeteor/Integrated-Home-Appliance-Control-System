`timescale 1ns / 1ps

module minsec_stop_stopwatch_core(
    input clear,
    input clk,
    input reset,
    input run_stop,
    output reg[4:0] hour_count,
    output reg[5:0] min_count,
    output reg[12:0] sec_count,
    output reg[13:0] stopwatch_count
    );

    reg [19:0] counter = 0;
    reg [6:0] ms10_counter = 0;

    always @(posedge clk or posedge reset) begin
        if (reset || clear) begin
            counter         <= 0;
            ms10_counter    <= 0;
            sec_count       <= 0;
            min_count       <= 0;
            hour_count      <= 0;
            stopwatch_count <= 0;
        end
        else if (counter < 1_000_000-1) begin
            counter <= counter + 1;
        end
        else begin
            counter <= 0;

            if (ms10_counter == 99) begin
                ms10_counter <= 0;
                if(sec_count == 59) begin
                    sec_count <= 0;
                        if(min_count == 59) begin
                            min_count <= 0;
                        end else begin
                            min_count <= min_count + 1;
                        end
                end else begin
                    sec_count <= sec_count + 1;
                end

            end else begin
                ms10_counter <= ms10_counter + 1;
            end

            if (run_stop) begin
                if (stopwatch_count < 5999)
                    stopwatch_count <= stopwatch_count + 1;
                else
                    stopwatch_count <= 0;
            end
        end
    end
endmodule
