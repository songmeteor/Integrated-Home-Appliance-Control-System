`timescale 1ns / 1ps

module microwave_fnd_controller(
    input        clk,
    input        reset,
    input [2:0]  mode,
    input [13:0] input_data, 
    output reg [7:0] seg_data,
    output reg [3:0] an       
    );

    parameter IDLE   = 3'b000,
              SET    = 3'b001,
              RUN    = 3'b010,
              STOP   = 3'b011,
              FINISH = 3'b100;    

    wire [1:0] w_sel;
    wire [3:0] w_d1;
    wire [3:0] w_d10;
    wire [3:0] w_d100;
    wire [3:0] w_d1000;

    wire [7:0] w_seg_num;
    wire [3:0] w_an_num; 

    wire [7:0] w_seg_ani;
    wire [3:0] w_an_ani;

    wire [7:0] w_seg_run;
    wire [3:0] w_an_run;

    wire [7:0] w_seg_finish;
    wire [3:0] w_an_finish;  
    
    microwave_bin2bcd u_microwave_bin2bcd(
        .in_data(input_data),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000)
    );

    microwave_fnd_digit_select u_microwave_fnd_digit_select(
        .clk(clk),
        .reset(reset),
        .sel(w_sel)
    );

    microwave_fnd_anim u_microwave_fnd_anim(
        .clk(clk),
        .reset(reset),
        .seg(w_seg_ani),
        .an(w_an_ani)
    );    


    microwave_fnd_display u_microwave_fnd_display(
        .digit_sel(w_sel),
        .d1(w_d1),
        .d10(w_d10),
        .d100(w_d100),
        .d1000(w_d1000),
        .an(w_an_num),
        .seg(w_seg_num)
    );

    microwave_fnd_run_display u_microwave_fnd_run_display(
        .clk(clk),
        .reset(reset),
        .an_num(w_an_num),
        .seg_num(w_seg_num),
        .an_ani(w_an_ani),
        .seg_ani(w_seg_ani),

        .an(w_an_run),
        .seg(w_seg_run)     
    );
    
    microwave_fnd_finish_display n_microwave_fnd_finish_display(
        .clk(clk),
        .reset(reset),
        .an_num(w_an_num), 

        .an(w_an_finish),
        .seg(w_seg_finish)     
    );        

    //MUX
    always @(*) begin
        case (mode)
            IDLE : begin
                seg_data = 8'b11111111;
                an = 4'b1111;
            end
            SET : begin
                seg_data = w_seg_num;
                an       = w_an_num;
            end            
            RUN : begin
                seg_data = w_seg_run;
                an       = w_an_run;
            end
            STOP : begin
                seg_data = w_seg_num;
                an       = w_an_num;
            end
            FINISH : begin
                seg_data = w_seg_finish;
                an       = w_an_finish;
            end
            default: begin
            seg_data = 8'b11111111; 
            an       = 4'b1111;
        end                                    
        endcase
    end
endmodule


module microwave_bin2bcd(
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


module microwave_fnd_digit_select(
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

module microwave_fnd_anim(
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


module microwave_fnd_display(
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

//run
module microwave_fnd_run_display(
    input           clk,
    input           reset,
    input [3:0]     an_num,
    input [7:0]     seg_num,
    input [3:0]     an_ani,
    input [7:0]     seg_ani,

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
            0 : begin     // 남은시간
                seg = seg_num;
                an  = an_num;
            end

            1: begin     // 서클
                seg = seg_ani;
                an  = an_ani;
            end
        endcase
    end    
endmodule

//finish
module microwave_fnd_finish_display(
    input           clk,
    input           reset,
    input [3:0]     an_num, 

    output reg [3:0] an,
    output reg [7:0] seg     
);

    reg [26:0]  tick_counter = 0;
    reg         finish_toggle = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick_counter <= 0;
        end else if (tick_counter == 100_000_000-1) begin
            tick_counter <= 0;
            finish_toggle <= !finish_toggle;
        end
        else
            tick_counter <= tick_counter + 1;
    end


    always @(*) begin
        case (finish_toggle)
            0 : begin     // 남은시간
                seg = 8'b11111111;
                an  = 4'b1111;
            end

            1: begin     // 서클
                seg = 8'b11000000;
                an  = an_num;
            end
        endcase
    end    
endmodule

