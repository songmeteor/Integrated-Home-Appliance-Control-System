`timescale 1ns / 1ps

module air_conditioner(
    input clk,
    input reset,
    input btnU,
    input btnC,
    input btnD,
    input btnL,
    input RsRx,
    input echo,

    output       RsTx,
    output       trig,
    output [7:0] seg,
    output [3:0] an,
    output       dc_motor,
    output [1:0] in1_in2,
    output       buzzer,    

    inout dht11_data
    );

    wire w_btnU, w_btnL, w_btnC, w_btnD;
    wire [9:0] w_distance;
    wire [1:0] w_mode;
    wire [7:0] w_humidity;
    wire [7:0] w_current_temperature;
    wire [7:0] w_target_temperature;
    wire [1:0] w_heat_cool_stop;
    wire [1:0] w_level;
    wire       w_ultrasonic_mode;

    debounce_pushbutton u_btnU(.clk(clk), .noise_btn(btnU), .clean_btn(w_btnU));
    debounce_pushbutton u_btnL(.clk(clk), .noise_btn(btnL), .clean_btn(w_btnL));   
    debounce_pushbutton u_btnC(.clk(clk), .noise_btn(btnC), .clean_btn(w_btnC));   
    debounce_pushbutton u_btnD(.clk(clk), .noise_btn(btnD), .clean_btn(w_btnD)); 

    ultrasonic_controller u_ultrasonic_controller(
        .clk  (clk),          
        .reset(reset),         
        .echo (echo),     

        .distance(w_distance),
        .trig    (trig) 
    );

    fsm_air_conditioner u_fsm_air_conditioner(
        .clk  (clk),
        .reset(reset),
        .btnC (w_btnC),

        .mode(w_mode)
    );

    dht11_controller u_dht11_controller(
        .clk  (clk),
        .reset(reset),

        .humidity            (w_humidity),
        .current_temperature (w_current_temperature),

        .dht11_data(dht11_data)
    );

    btn_controller u_btn_controller(
        .clk                (clk),
        .reset              (reset),
        .btnU               (w_btnU),
        .btnD               (w_btnD),
        .btnL               (w_btnL),
        .mode               (w_mode),
        .current_temperature(w_current_temperature),
        .humidity           (w_humidity), 

        .target_temperature(w_target_temperature),
        .heat_cool_stop    (w_heat_cool_stop),
        .level             (w_level),
        .ultrasonic_mode   (w_ultrasonic_mode)
    );

    fnd_controller u_fnd_controller(
        .clk                (clk),
        .reset              (reset),
        .mode               (w_mode), 
        .distance           (w_distance),
        .target_temperature (w_target_temperature),
        .current_temperature(w_current_temperature), 
        .humidity           (w_humidity),            
        .level              (w_level),
        .heat_cool_stop     (w_heat_cool_stop),           
        .ultrasonic_mode    (w_ultrasonic_mode),

        .seg_data(seg),
        .an      (an)
    ); 

    dc_motor_controller u_dc_motor_controller(
        .clk           (clk),
        .reset         (reset),
        .distance      (w_distance),
        .mode          (w_mode),
        .heat_cool_stop(w_heat_cool_stop),
        .level         (w_level),

        .dc_motor(dc_motor),
        .in1_in2 (in1_in2)     
    );

    uart_controller u_uart_controller(
        .clk                (clk),
        .reset              (reset),
        .ultrasonic_mode    (w_ultrasonic_mode),
        .humidity           (w_humidity),
        .current_temperature(w_current_temperature),
        .distance           (w_distance),
        
        .tx(RsTx)
    );

    buzzer_controller u_buzzer_controller(
        .clk(clk),
        .reset(reset),
        .pulse_U(w_btnU),
        .pulse_D(w_btnD),
        .pulse_L(w_btnL),
        .pulse_run(w_btnC),
        .distance(w_distance),
        .buzzer(buzzer)
    );
endmodule
