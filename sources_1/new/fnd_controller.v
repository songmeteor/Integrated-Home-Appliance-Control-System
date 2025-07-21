`timescale 1ns / 1ps

module fnd_controller(
    input       clk,
    input       reset,
    input [1:0] mode,  // IDLE , AUTO, MANUAL
    input [9:0] distance,
    input [7:0] target_temperature,
    input [7:0] current_temperature,  // 무조건 두자리 양수
    input [7:0] humidity,             // 무조건 두자리 양수
    input [1:0] level,
    input [1:0] heat_cool_stop,      // heat = 0, cool = 1 , stop = 2
    input       ultrasonic_mode,

    output reg [7:0] seg_data,
    output reg [3:0] an
    );

    parameter IDLE   = 2'b00,
              AUTO   = 2'b01,
              MANUAL = 2'b10;

    wire [1:0]  w_sel;
    wire [3:0]  w_d1;
    wire [3:0]  w_d10;
    wire [3:0]  w_d100;
    wire [3:0]  w_d1000;

    wire [7:0]  w_seg_level;
    wire [3:0]  w_an_level;
    wire [7:0]  w_seg_num;
    wire [3:0]  w_an_num;
    wire [7:0]  w_seg_hc;
    wire [3:0]  w_an_hc;    

    wire [7:0]  w_seg_auto;
    wire [3:0]  w_an_auto;
    wire [7:0]  w_seg_manual;
    wire [3:0]  w_an_manual;    

    reg [13:0] w_input_data;

    bin2bcd u_bin2bcd(
        .in_data(w_input_data),

        .d1     (w_d1),
        .d10    (w_d10),
        .d100   (w_d100),
        .d1000  (w_d1000)
    );

    fnd_digit_select u_fnd_digit_select(
        .clk  (clk),
        .reset(reset),

        .sel  (w_sel)
    );                  

    fnd_display u_fnd_display(
        .digit_sel(w_sel),
        .d1       (w_d1),
        .d10      (w_d10),
        .d100     (w_d100),
        .d1000    (w_d1000),

        .an       (w_an_num),
        .seg      (w_seg_num)
    );

    fnd_level u_fnd_level(
        .digit_sel(w_sel),
        .level    (level),

        .seg      (w_seg_level),
        .an       (w_an_level)
    );

    fnd_heat_cool u_fnd_heat_cool(
        .digit_sel     (w_sel),
        .heat_cool_stop(heat_cool_stop),
        .seg           (w_seg_hc),
        .an            (w_an_hc)
    );

    fnd_auto u_fnd_auto(
        .clk      (clk),
        .reset    (reset),
        .an_num   (w_an_num),
        .seg_num  (w_seg_num),
        .an_level (w_an_level),
        .seg_level(w_seg_level),    

        .an (w_an_auto),
        .seg(w_seg_auto)             
    );

    fnd_manual u_fnd_manual(
        .clk    (clk),
        .reset  (reset),
        .an_num (w_an_num),
        .seg_num(w_seg_num),
        .an_hc  (w_an_hc),
        .seg_hc (w_seg_hc),    

        .an (w_an_manual),
        .seg(w_seg_manual)          
    ); 

    always @(*) begin
        if(ultrasonic_mode) begin
            w_input_data = distance;
        end else begin
            case(mode)
            IDLE :   w_input_data = 0;
            AUTO :   w_input_data = current_temperature * 100 + humidity;
            MANUAL : w_input_data = current_temperature * 100 + target_temperature;
            endcase        
        end

    end

    always @(*) begin
        if(ultrasonic_mode) begin
            seg_data = w_seg_num;
            an       = w_an_num;        
        end else begin
        case (mode)
            IDLE : begin
                seg_data = 8'b11111111;
                an = 4'b1111;
            end
            AUTO : begin
                seg_data = w_seg_auto;
                an       = w_an_auto;
            end            
            MANUAL : begin
                seg_data = w_seg_manual;
                an       = w_an_manual;
            end
            default: begin
                seg_data = 8'b11111111; 
                an       = 4'b1111;
            end                                    
        endcase
        end
    end    
endmodule


module bin2bcd(
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


module fnd_digit_select(
    input clk,
    input reset,
    output reg [1:0] sel
);

    reg [16:0] r_1ms_counter = 0;
    reg [1:0]  r_digit_sel = 0;

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


module fnd_display(
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
            2'b00: begin   bcd_data = d1;      an = 4'b1110; end
            2'b01: begin   bcd_data = d10;     an = 4'b1101; end
            2'b10: begin   bcd_data = d100;    an = 4'b1011; end
            2'b11: begin   bcd_data = d1000;   an = 4'b0111; end
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

module fnd_level(
    input [1:0] digit_sel,
    input [1:0] level,
    output reg [7:0] seg,
    output reg [3:0] an
);

    parameter LEVEL0 = 2'b00,
              LEVEL1 = 2'b01,
              LEVEL2 = 2'b10,
              LEVEL3 = 2'b11;  

    reg [7:0] select_level_display; 

    always @(*) begin
        case (level) 
        LEVEL0 : select_level_display = 8'b11000000;
        LEVEL1 : select_level_display = 8'b11111001;
        LEVEL2 : select_level_display = 8'b10100100;
        LEVEL3 : select_level_display = 8'b10110000;
        default : select_level_display = 8'b11111111;
        endcase
    end

    always @(*) begin
        case(digit_sel)
            2'b00: begin   seg = select_level_display; an = 4'b1110; end
            2'b01: begin   seg = 8'b11000001;          an = 4'b1101; end
            2'b10: begin   seg = 8'b10000110;          an = 4'b1011; end
            2'b11: begin   seg = 8'b11000111;          an = 4'b0111; end
            default: begin seg = 8'b11111111;          an = 4'b1111; end           
        endcase
    end
endmodule


module fnd_heat_cool(
    input [1:0] digit_sel,
    input [1:0] heat_cool_stop,

    output reg [7:0] seg,
    output reg [3:0] an
);
    parameter HEAT = 2'b00,
              COOL = 2'b01,
              STOP = 2'b10;  

    reg [7:0] select_hc_display [3:0]; 

    always @(*) begin
        case (heat_cool_stop) 
        HEAT : begin
            select_hc_display[0] = 8'b10000111; // T
            select_hc_display[1] = 8'b10001000; // A
            select_hc_display[2] = 8'b10000110; // E
            select_hc_display[3] = 8'b10001001; // H                                    
        end
        COOL : begin
            select_hc_display[0] = 8'b11000111; // L
            select_hc_display[1] = 8'b11000000; // O
            select_hc_display[2] = 8'b11000000; // O
            select_hc_display[3] = 8'b11000110; // C   
        end
        STOP : begin
            select_hc_display[0] = 8'b10001100; // P
            select_hc_display[1] = 8'b11000000; // O
            select_hc_display[2] = 8'b10000111; // T
            select_hc_display[3] = 8'b10010010; // S                 
        end        
        endcase
    end

    always @(*) begin
        case(digit_sel)
            2'b00: begin   seg = select_hc_display[0]; an = 4'b1110; end
            2'b01: begin   seg = select_hc_display[1]; an = 4'b1101; end
            2'b10: begin   seg = select_hc_display[2]; an = 4'b1011; end
            2'b11: begin   seg = select_hc_display[3]; an = 4'b0111; end
            default: begin seg = 8'b11111111;          an = 4'b1111; end           
        endcase
    end
endmodule


    // AUTO MODE : (온도 2자리 / 습도 2자리) , (현재 모터 level ex: LEV0) 번갈아 가면서 출력 
module fnd_auto(
    input       clk,
    input       reset,
    input [3:0] an_num,
    input [7:0] seg_num,
    input [3:0] an_level,
    input [7:0] seg_level,    

    output reg [3:0] an,
    output reg [7:0] seg          
);

    reg [26:0]  tick_counter = 0;
    reg [2:0]   fnd_toggle_counter = 0;
    reg         fnd_toggle;

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
        if (reset)
            fnd_toggle_counter <= 0;
        else if (tick_1s) begin
            if(fnd_toggle_counter == 5)
                fnd_toggle_counter <= 0;
            else
                fnd_toggle_counter <= fnd_toggle_counter + 1;    
        end
    end

    always @(*) begin
        if (fnd_toggle_counter < 3) 
            fnd_toggle = 1'b0; 
        else 
            fnd_toggle = 1'b1;
    end

    always @(*) begin
        case (fnd_toggle)
            0 : begin     // 온도 / 습도
                seg = seg_num;
                an  = an_num;
            end
            1: begin     // LEV0, LEV1, LEV2, LEV3
                seg = seg_level;
                an  = an_level;        
            end
        endcase
    end         
endmodule

//MANUAL MODE : 현재 온도 / 희망 온도 , COOL / HEAT 번갈아 가면서 출력 
module fnd_manual(
    input       clk,
    input       reset,
    input [3:0] an_num,
    input [7:0] seg_num,
    input [3:0] an_hc,
    input [7:0] seg_hc,    

    output reg [3:0] an,
    output reg [7:0] seg          
);

    reg [26:0]  tick_counter = 0;
    reg [2:0]   fnd_toggle_counter = 0;
    reg         fnd_toggle;

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
        if (reset)
            fnd_toggle_counter <= 0;
        else if (tick_1s) begin
            if(fnd_toggle_counter == 5)
                fnd_toggle_counter <= 0;
            else
                fnd_toggle_counter <= fnd_toggle_counter + 1;    
        end
    end

    always @(*) begin
        if (fnd_toggle_counter < 3) 
            fnd_toggle = 1'b0; 
        else 
            fnd_toggle = 1'b1;
    end

    always @(*) begin
        case (fnd_toggle)
            0 : begin     // 현재 온도 / 희망 온도
                seg = seg_num;
                an  = an_num;
            end
            1: begin     // COOL, HEAT
                seg = seg_hc;
                an  = an_hc;        
            end
        endcase
    end         
endmodule