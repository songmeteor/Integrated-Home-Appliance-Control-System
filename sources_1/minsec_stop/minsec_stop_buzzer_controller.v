`timescale 1ns / 1ps

module minsec_stop_buzzer_controller(
    input           clk,
    input           reset,
    input           btnU,
    input           btnC,
    input           btnD,

    output          buzzer
    );

    localparam S_IDLE       = 1'b0; 
    localparam S_PLAY_SOUND = 1'b1; 

    localparam DUR_100MS = 24'd10_000_000; 

    localparam DIV_CLICK = 16'd38222;

    reg current_state, next_state;

    reg [23:0] duration_timer;
    reg [15:0] frequency_counter;
    reg        buzzer_internal;

    wire any_button_pressed;
    reg  any_button_pressed_prev;
    wire button_tick;

    assign any_button_pressed = btnU | btnC | btnD;
    assign button_tick = any_button_pressed && !any_button_pressed_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            any_button_pressed_prev <= 1'b0;
        end else begin
            any_button_pressed_prev <= any_button_pressed;
        end
    end


    always @(*) begin
        next_state = current_state; 
        case (current_state)
            S_IDLE: begin
                if (button_tick) begin
                    next_state = S_PLAY_SOUND; 
                end
            end
            S_PLAY_SOUND: begin
                if (duration_timer == 1) begin 
                    next_state = S_IDLE;      
                end
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            duration_timer <= 0;
        end else begin
            if (current_state == S_IDLE && next_state == S_PLAY_SOUND) begin
                duration_timer <= DUR_100MS;
            end
            else if (duration_timer > 0) begin
                duration_timer <= duration_timer - 1;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            frequency_counter <= 0;
            buzzer_internal   <= 1'b0;
        end else begin
            if (current_state == S_PLAY_SOUND) begin
                if (frequency_counter >= DIV_CLICK - 1) begin
                    frequency_counter <= 0;
                    buzzer_internal   <= ~buzzer_internal; 
                end else begin
                    frequency_counter <= frequency_counter + 1;
                end
            end else begin
                frequency_counter <= 0; 
                buzzer_internal   <= 1'b0;
            end
        end
    end

    assign buzzer = (current_state == S_PLAY_SOUND) ? buzzer_internal : 1'b0;

endmodule