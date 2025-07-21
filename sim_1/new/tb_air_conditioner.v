`timescale 1ns / 1ps

module tb_air_conditioner();
    reg clk;
    reg reset;
    reg btnU;
    reg btnC;
    reg btnD;
    reg btnL;
    reg RsRx;
    reg echo;

    wire       RsTx;
    wire       trig;
    wire [7:0] seg;
    wire [3:0] an;
    wire       dc_motor;
    wire [1:0] in1_in2;
    wire       buzzer;

    wire dht11_data;    


    air_conditioner u_air_conditioner(
        .clk(clk),
        .reset(reset),
        .btnU(btnU),
        .btnC(btnC),
        .btnD(btnD),
        .btnL(btnL),
        .RsRx(RsRx),
        .echo(echo),

        .RsTx(RsTx),
        .trig(trig),
        .seg(seg),
        .an(an),
        .dc_motor(dc_motor),
        .in1_in2(in1_in2),
        .buzzer(buzzer),    

        .dht11_data(dht11_data)
    );


endmodule
