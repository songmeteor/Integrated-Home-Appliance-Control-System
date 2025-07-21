`timescale 1ns / 1ps

module microwave_top(
    input        clk,
    input        reset,
    input        btnU,
    input        btnL,
    input        btnC,
    input        btnD,
    input        door,
    input  [1:0] top_mode,
    output [7:0] seg,
    output [3:0] an,
    output       buzzer,
    output [1:0] in1_in2,
    output       servo, 
    output       dc_motor 
    );

    wire w_btnU, w_btnL, w_btnC, w_btnD;
    wire [13:0] w_run_time;
    wire [2:0]  w_mode;

    microwave_debounce_pushbutton u_microwave_btnU(.clk(clk), .noise_btn(btnU), .clean_btn(w_btnU));
    microwave_debounce_pushbutton u_microwave_btnL(.clk(clk), .noise_btn(btnL), .clean_btn(w_btnL));   
    microwave_debounce_pushbutton u_microwave_btnC(.clk(clk), .noise_btn(btnC), .clean_btn(w_btnC));   
    microwave_debounce_pushbutton u_microwave_btnD(.clk(clk), .noise_btn(btnD), .clean_btn(w_btnD));      

    microwave_fsm u_microwave_fsm(
        .clk     (clk),
        .reset   (reset),
        .btnU    (w_btnU),
        .btnL    (w_btnL),
        .btnC    (w_btnC),
        .btnD    (w_btnD),
        .top_mode(top_mode),
        .door    (door),   
        .run_time(w_run_time),
        .mode    (w_mode)
        );

    microwave_btn_controller u_microwave_btn_controller(
        .clk        (clk),
        .reset      (reset),
        .btnU       (w_btnU),
        .btnL       (w_btnL),
        .btnC       (w_btnC),
        .btnD       (w_btnD),
        .mode       (w_mode),
        .run_time   (w_run_time)
        );

    microwave_fnd_controller u_microwave_fnd_controller(
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .input_data(w_run_time), 
        .seg_data(seg),
        .an(an)       
        );

    microwave_dc_motor_controller u_microwave_dc_motor_controller(
        .clk(clk),
        .mode(w_mode),
        .dc_motor(dc_motor),
        .in1_in2(in1_in2) 
        );

    microwave_servo_controller u_microwave_servo_controller(
        .clk(clk),    
        .reset(reset),  
        .door(door),   
        .servo(servo)   
    ); 

    microwave_buzzer_controller u_microwave_buzzer_controller(
        .clk(clk),
        .reset(reset),
        .btnU(w_btnU),
        .btnL(w_btnL),
        .btnC(w_btnC),
        .btnD(w_btnD),
        .door(door), 
        .mode(w_mode),
        .buzzer(buzzer)
        );                              
endmodule
