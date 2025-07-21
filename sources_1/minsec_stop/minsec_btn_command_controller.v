`timescale 1ns / 1ps

module minsec_btn_command_controller(
    input clk,
    input reset,  //          
    input btnU,
    input btnC,
    input btnD, 
    input [4:0] hour_count,
    input [5:0] min_count,
    input [12:0] sec_count,
    input [13:0] stopwatch_count,    
    output reg [13:0] seg_data, 
    output reg clear,
    output reg run_stop,
    output reg anim_mode
    );

    //mode
    parameter IDLE = 3'b000;
    parameter MINSEC = 3'b001;
    parameter STOPWATCH = 3'b010;

    reg prev_btnU = 0;
    reg prev_btnC = 0;
    reg prev_btnD = 0;
    reg r_run_stop;
    reg [2:0] r_mode = IDLE;
    reg [5:0] stop_idle_sec = 0;
    reg [26:0] tick_counter = 0;

    wire tick_1s = (tick_counter == 100_000_000-1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick_counter <= 0;
        end else if (tick_counter == 100_000_000-1)
            tick_counter <= 0;
        else
            tick_counter <= tick_counter + 1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset || r_mode != STOPWATCH || r_run_stop)
            stop_idle_sec <= 0;
        else if (tick_1s)
            stop_idle_sec <= stop_idle_sec + 1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            r_run_stop <= 0;
        else
            r_run_stop <= run_stop;  
    end

    always @ (posedge clk, posedge reset) begin
        if(reset) begin
            r_mode <= IDLE;
            prev_btnU <= 0;
        end else begin
            if(btnU && !prev_btnU)
                r_mode <= (r_mode == STOPWATCH) ? IDLE : r_mode + 1;
            else if (r_mode == STOPWATCH && !run_stop && stop_idle_sec >= 30)
                r_mode <= IDLE;
            prev_btnU <= btnU;  
        end
    end

    always @ (posedge clk, posedge reset) begin
        if(reset)
            anim_mode <= 1;
        else begin
            if(r_mode == IDLE)
                anim_mode <= 1;
            else
                anim_mode <= 0;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            run_stop <= 0;
            prev_btnC <= 0;
        end else begin
            if (btnC && !prev_btnC)
                run_stop <= ~run_stop;

            prev_btnC <= btnC;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clear     <= 0;
            prev_btnD <= 0;
        end else begin
            if (btnD && !prev_btnD)
                clear <= 1;
            else
                clear <= 0;

            prev_btnD <= btnD;
        end
    end

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            seg_data <= 14'd0;
        end else begin
            case (r_mode)
                IDLE: begin
                    seg_data <= hour_count; 
                end
                MINSEC: begin
                    seg_data <= {100 * min_count + sec_count}; 
                end
                STOPWATCH: begin
                    seg_data <= stopwatch_count;
                end
                default: seg_data <= 14'd0;
            endcase
        end
    end

endmodule
