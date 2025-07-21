`timescale 1ns / 1ps

module minsec_stop_fnd_controller(
    input clk,
    input reset,
    input anim_mode,
    input [13:0] input_data,
    output [7:0] seg_data,
    output [3:0] an     // 자릿수 선택
    );

    wire [1:0] w_sel;
    wire [3:0] w_d1;
    wire [3:0] w_d10;
    wire [3:0] w_d100;
    wire [3:0] w_d1000;
    wire [7:0] w_seg_anim;
    wire [3:0] w_an_anim;
    wire [7:0] w_seg_num;
    wire [3:0] w_an_num;

    minsec_stop_fnd_digit_select u_minsec_stop_fnd_digit_select(
        .clk(clk),
        .reset(reset),
        .sel(w_sel)
    );

    minsec_stop_bin2bcd u_minsec_stop_bin2bcd(
        .in_data(input_data),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)
    );

    minsec_stop_fnd_display u_minsec_stop_fnd_display(
        .digit_sel(w_sel),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000),
        .an(w_an_num),
        .seg(w_seg_num)
    );

    minsec_stop_fnd_anim u_minsec_stop_fnd_anim(
        .clk(clk),
        .reset(reset),
        .seg(w_seg_anim),
        .an(w_an_anim)
    );

    assign seg_data = anim_mode ? w_seg_anim : w_seg_num;
    assign an = anim_mode ? w_an_anim : w_an_num;
endmodule


//1ms 마다 fnd를 display 하기 위해 digit 1자리씩 선택
module minsec_stop_fnd_digit_select(
    input clk,
    input reset,
    output reg [1:0] sel
);

    reg [16:0] r_1ms_counter = 0;
    reg [1:0] r_digit_sel = 0;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_1ms_counter <= 0;
            r_digit_sel <= 0;
            sel <= 0; 
        end else begin
            if(r_1ms_counter == 100_000-1) begin
                r_1ms_counter <= 0;
                r_digit_sel <= r_digit_sel + 1;
                sel <= r_digit_sel;
            end else begin
               r_1ms_counter <= r_1ms_counter + 1;
            end
        end
    end
endmodule


//bin2bcd
// 입력 : bin 14bit인 이유 최대 9999까지 표현 값이 들어 있기 ??문
// 0~9999 천/백/십/일 자리 숫자 0~9 까지로 BCD 4bit로 표현
// 출력 : bcd
module minsec_stop_bin2bcd(
    input [13:0] in_data,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100,
    output [3:0] d1000
);

    assign d1 = in_data % 10;
    assign d10 = (in_data / 10) % 10;
    assign d100 = (in_data / 100) % 10;
    assign d1000 = (in_data / 1000) % 10;

endmodule

module minsec_stop_fnd_display(
    input [1:0] digit_sel,
    input [3:0] d1,
    input [3:0] d10,
    input [3:0] d100,
    input [3:0] d1000,
    output reg [3:0] an,
    output reg [7:0] seg
); 

    reg [3:0] bcd_data;

    always @(digit_sel) begin
        case(digit_sel)
            2'b00: begin bcd_data = d1; an = 4'b1110; end
            2'b01: begin bcd_data = d10; an = 4'b1101; end
            2'b10: begin bcd_data = d100; an = 4'b1011; end
            2'b11: begin bcd_data = d1000; an = 4'b0111; end
            default: begin bcd_data = 4'b0000; an = 4'b1111; end
        endcase
    end

    always @(bcd_data) begin
        case(bcd_data)
            4'd0: seg = 8'b11000000;
            4'd1: seg = 8'b11111001;
            4'd2: seg = 8'b10100100;
            4'd3: seg = 8'b10110000;
            4'd4: seg = 8'b10011001;
            4'd5: seg = 8'b10010010;
            4'd6: seg = 8'b10000010;
            4'd7: seg = 8'b11111000;
            4'd8: seg = 8'b10000000;
            4'd9: seg = 8'b10010000;
            default: seg = 8'b11111111;
        endcase
    end    
endmodule


module minsec_stop_fnd_anim(
    input clk,
    input reset,
    output reg [7:0] seg,
    output reg [3:0] an
);
    reg [3:0] anim_step = 0;
    reg [26:0] counter = 0;  

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            anim_step <= 0;
            counter <= 0;
        end else begin
            if (counter == 10_000_000 - 1) begin
                counter <= 0;
                anim_step <= (anim_step == 11) ? 0 : anim_step + 1;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always @(*) begin
        seg = 8'b11111111; 
        an = 4'b1111;      

        case(anim_step)
            0: begin an = 4'b0111; seg = 8'b11011111; end 
            1: begin an = 4'b0111; seg = 8'b11111110; end 
            2: begin an = 4'b1011; seg = 8'b11111110; end 
            3: begin an = 4'b1101; seg = 8'b11111110; end 
            4: begin an = 4'b1110; seg = 8'b11111110; end 
            5: begin an = 4'b1110; seg = 8'b11111101; end 
            6: begin an = 4'b1110; seg = 8'b11111011; end 
            7: begin an = 4'b1110; seg = 8'b11110111; end 
            8: begin an = 4'b1101; seg = 8'b11110111; end 
            9: begin an = 4'b1011; seg = 8'b11110111; end 
            10:begin an = 4'b0111; seg = 8'b11110111; end 
            11:begin an = 4'b0111; seg = 8'b11101111; end 
            default: begin an = 4'b1111; seg = 8'b11111111; end
        endcase
    end
endmodule