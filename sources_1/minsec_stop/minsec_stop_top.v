`timescale 1ns / 1ps

module minsec_stop_top(
    input clk,
    input reset,          
    input btnU,   
    input btnC,   
    input btnD,  
    output [7:0] seg,
    output [3:0] an,
    output       buzzer
    );

    wire w_btnU, w_btnC, w_btnD;
    wire [13:0] w_seg_data;
    wire w_tick;

    wire [4:0]  w_hour_count;
    wire [5:0]  w_min_count;
    wire [12:0] w_sec_count;
    wire [13:0] w_stopwatch_count;
    wire        w_clear;
    wire        w_run_stop;
    wire        w_anim_mode;

    minsec_stop_tick_generator u_minsec_stop_tick_generator(    
        .clk  (clk),
        .reset(reset),
        .tick (w_tick)
    );    

    my_btn_debounce u_btnU(
        .clk       (clk),
        .reset     (reset),
        .noise_btn (btnU),
        .tick      (w_tick), 
        .clean_btn (w_btnU)
    );

    my_btn_debounce u_btnC(
        .clk      (clk),
        .reset    (reset),
        .noise_btn(btnC),
        .tick     (w_tick), 
        .clean_btn(w_btnC)
    );

    my_btn_debounce u_btnD(
        .clk      (clk),
        .reset    (reset),
        .noise_btn(btnD),
        .tick     (w_tick), 
        .clean_btn(w_btnD)
    );

    minsec_stop_stopwatch_core u_minsec_stop_stopwatch_core(
        .clear          (w_clear),
        .clk            (clk),
        .reset          (reset),
        .run_stop       (w_run_stop),
        .hour_count     (w_hour_count),
        .min_count      (w_min_count),
        .sec_count      (w_sec_count),
        .stopwatch_count(w_stopwatch_count)
    );

    minsec_btn_command_controller u_minsec_btn_command_controller(
        .clk            (clk),
        .reset          (reset),   
        .btnU           (w_btnU),
        .btnC           (w_btnC),
        .btnD           (w_btnD), 
        .hour_count     (w_hour_count),
        .min_count      (w_min_count),
        .sec_count      (w_sec_count),
        .stopwatch_count(w_stopwatch_count),  
          
        .seg_data (w_seg_data),
        .clear    (w_clear),
        .run_stop (w_run_stop),
        .anim_mode(w_anim_mode)
    );

    minsec_stop_fnd_controller u_minsec_stop_fnd_controller(
        .clk       (clk),
        .reset     (reset),
        .input_data(w_seg_data),
        .anim_mode (w_anim_mode), 
        .seg_data  (seg),
        .an        (an)    
    );

    minsec_stop_buzzer_controller u_minsec_stop_buzzer_controller(
        .clk  (clk),
        .reset(reset),
        .btnU (w_btnU),
        .btnC (w_btnC),
        .btnD (w_btnD),
        .buzzer(buzzer)
    );        
endmodule