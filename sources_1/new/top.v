`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input btnU,
    input btnC,
    input btnL,
    input btnR,
    input btnD,
    input door,
    input RsRx,
    input echo,

    output            trig,
    output            RsTx,
    output reg        buzzer,
    output reg [7:0]  seg,
    output reg [3:0]  an,
    output reg [15:0] led,
    output reg [1:0]  in1_in2,
    output            servo,
    output reg        dc_motor,

    inout dht11_data
     );

    parameter minsec_stop = 2'b00,
              microwave   = 2'b01,
              air_conditioner = 2'b10;

    wire w_btnR;

    wire [7:0] w_minsec_stop_seg;
    wire [3:0] w_minsec_stop_an;
    wire       w_minsec_stop_buzzer;

    wire [7:0] w_microwave_stop_seg;
    wire [3:0] w_microwave_stop_an;
    wire       w_microwave_buzzer;
    wire [1:0] w_microwave_in1_in2;
    wire       w_microwave_dc_motor;

    wire [7:0] w_air_conditioner_seg;
    wire [3:0] w_air_conditioner_an;
    wire       w_air_conditioner_dc_motor;
    wire [1:0] w_air_conditioner_in1_in2;
    wire       w_air_conditioner_buzzer;
    wire [15:0] w_air_conditioner_led;

    wire [1:0] state;

    debounce_pushbutton u_btnR(.clk(clk), .noise_btn(btnR), .clean_btn(w_btnR));          

    minsec_stop_top u_minsec_stop_top(
        .clk  (clk),
        .reset(reset),         
        .btnU (btnU),   
        .btnC (btnC),   
        .btnD (btnD),   
        .seg  (w_minsec_stop_seg),
        .an   (w_minsec_stop_an),
        .buzzer (w_minsec_stop_buzzer)
    );

    microwave_top u_microwave_top(
        .clk  (clk),
        .reset(reset),
        .btnU (btnU),
        .btnL (btnL),
        .btnC (btnC),
        .btnD (btnD),
        .door (door),
        .top_mode(state),

        .seg(w_microwave_stop_seg),
        .an(w_microwave_stop_an),
        .buzzer(w_microwave_buzzer),
        .in1_in2(w_microwave_in1_in2),
        .servo(servo), 
        .dc_motor(w_microwave_dc_motor) 
    );

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
        .seg(w_air_conditioner_seg),
        .an(w_air_conditioner_an),
        .dc_motor(w_air_conditioner_dc_motor),
        .in1_in2(w_air_conditioner_in1_in2),       
        .buzzer(w_air_conditioner_buzzer),
        .dht11_data(dht11_data)
    );

    top_fsm u_top_fsm(
        .clk(clk),
        .reset(reset),
        .btnR(w_btnR),

        .state(state)
    );

    always@(*) begin
        case(state)
            minsec_stop : begin
                seg = w_minsec_stop_seg;
                an = w_minsec_stop_an;
                buzzer = w_minsec_stop_buzzer;
                led[15:13] = 3'b100;
                led[12:0] = 0;
                in1_in2 = 0;
                dc_motor = 0;
            end
            microwave : begin
                seg = w_microwave_stop_seg;
                an = w_microwave_stop_an; 
                buzzer = w_microwave_buzzer; 
                in1_in2 = w_microwave_in1_in2;    
                dc_motor = w_microwave_dc_motor;
                led[15:13] = 3'b010;
                led[12:0] = 0;
            end
            air_conditioner : begin
                seg = w_air_conditioner_seg;
                an = w_air_conditioner_an;
                dc_motor = w_air_conditioner_dc_motor;
                in1_in2 = w_air_conditioner_in1_in2;
                buzzer = w_air_conditioner_buzzer;
                led[15:13] = 3'b001;
                led[12:0] = 0;        
            end 
            default : begin
                seg = w_minsec_stop_seg;
                an = w_minsec_stop_an;
                buzzer = w_minsec_stop_buzzer;
                led = 0;
                dc_motor = w_microwave_dc_motor;
                in1_in2 = 0;                
            end                       
        endcase
    end
endmodule


module top_fsm(
    input clk,
    input reset,
    input btnR,

    output [1:0] state
);

    parameter minsec_stop = 2'b00,
              microwave   = 2'b01,
              air_conditioner = 2'b10;

    reg [1:0] current_state = minsec_stop; 
    reg [1:0] next_state;
   
    assign state = current_state;

    always @ (posedge clk, posedge reset) 
    begin
        if(reset) current_state <= minsec_stop;
        else      current_state <= next_state;
    end    

    always@(*) begin
        case(current_state)
            minsec_stop : begin
                if(btnR) next_state = microwave;
                else next_state = minsec_stop;
            end
            microwave : begin
                if(btnR) next_state = air_conditioner;
                else next_state = microwave;                
            end
            air_conditioner : begin
                if(btnR) next_state = minsec_stop;
                else next_state = air_conditioner;                
            end
            default : next_state =  minsec_stop;                      
        endcase
    end 
endmodule