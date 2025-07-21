`timescale 1ns / 1ps

module uart_controller(
    input           clk,
    input           reset,
    input           ultrasonic_mode,
    input   [7:0]   humidity,
    input   [7:0]   current_temperature,
    input   [9:0]   distance,
    
    output          tx
    );

    wire        w_tick_1Hz;
    wire        w_tx_start;
    wire [7:0]  w_tx_data;
    wire        w_tx_busy;
    wire        w_tx_done;

    tick_generator #(
        .INPUT_FREQ(100_000_000),
        .TICK_HZ(1)
    ) u_tick_1Hz(
        .clk  (clk),
        .reset(reset),
        .tick (w_tick_1Hz)
    );

    data_sender u_data_sender(
        .clk          (clk),
        .reset        (reset),
        .start_trigger(w_tick_1Hz),
        .tx_done      (w_tx_done),
        .tx_busy      (w_tx_busy),
        
        .ultrasonic_mode    (ultrasonic_mode),
        .humidity           (humidity),
        .current_temperature(current_temperature),
        .distance           (distance),
        
        .tx_start(w_tx_start),
        .tx_data (w_tx_data)
    );

    uart_tx u_uart_tx(
        .clk     (clk),
        .reset   (reset),
        .tx_data (w_tx_data),
        .tx_start(w_tx_start),
        
        .tx     (tx),
        .tx_busy(w_tx_busy),
        .tx_done(w_tx_done)
    );
  
endmodule

module data_sender(
    input           clk,
    input           reset,
    input           start_trigger, 
    input           tx_done,
    input           tx_busy,
    input           ultrasonic_mode,
    input   [7:0]   humidity,
    input   [7:0]   current_temperature,
    input   [9:0]   distance,

    output reg       tx_start,
    output reg [7:0] tx_data
);

    localparam IDLE = 2'b00, 
               PREPARE = 2'b01, 
               SENDING = 2'b10;

    localparam TX_BUFFER_SIZE = 14; // "H:XX, T:YY\n\r" -> 13 chars           

    reg [1:0] state;

    reg [7:0] tx_buffer [0:TX_BUFFER_SIZE-1];
    reg [3:0] tx_idx; 
    reg [3:0] tx_len; 

    localparam ASCII_H  = "H";
    localparam ASCII_T  = "T";
    localparam ASCII_D  = "D";
    localparam ASCII_COLON = ":";
    localparam ASCII_COMMA = ",";
    localparam ASCII_SPACE = " ";
    localparam ASCII_NL = 8'h0A; 
    localparam ASCII_CR = 8'h0D; 

    function [7:0] to_ascii(input [3:0] digit);
        begin 
            to_ascii = digit + 8'h30; 
        end
    endfunction

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx_start <= 0;
            tx_idx <= 0;
        end else begin
            tx_start <= 0; 

            case (state)
                IDLE: begin
                    if (start_trigger && !tx_busy) begin
                        state <= PREPARE;
                    end
                end

                PREPARE: begin 
                    if (ultrasonic_mode == 0) begin 
                        tx_buffer[0]  <= ASCII_H;
                        tx_buffer[1]  <= ASCII_COLON;
                        tx_buffer[2]  <= to_ascii(humidity / 10);
                        tx_buffer[3]  <= to_ascii(humidity % 10);
                        tx_buffer[4]  <= ASCII_COMMA;
                        tx_buffer[5]  <= ASCII_SPACE;
                        tx_buffer[6]  <= ASCII_T;
                        tx_buffer[7]  <= ASCII_COLON;
                        tx_buffer[8]  <= to_ascii(current_temperature / 10);
                        tx_buffer[9]  <= to_ascii(current_temperature % 10);
                        tx_buffer[10] <= ASCII_NL;
                        tx_buffer[11] <= ASCII_CR;
                        tx_len        <= 12;
                    end else begin 
                        // "D:XXX\n\r"
                        tx_buffer[0] <= ASCII_D;
                        tx_buffer[1] <= ASCII_COLON;
                        tx_buffer[2] <= to_ascii(distance / 100);
                        tx_buffer[3] <= to_ascii((distance % 100) / 10);
                        tx_buffer[4] <= to_ascii(distance % 10);
                        tx_buffer[5] <= ASCII_NL;
                        tx_buffer[6] <= ASCII_CR;
                        tx_len       <= 7;
                    end
                    tx_idx <= 0; 
                    state <= SENDING; 
                end

                SENDING: begin
                    if (tx_idx == 0 || tx_done) begin
                        if (tx_idx < tx_len) begin
                            tx_data <= tx_buffer[tx_idx];
                            tx_start <= 1; 
                            tx_idx <= tx_idx + 1;
                        end else begin
                            state <= IDLE; 
                        end
                    end
                end
            endcase
        end
    end
endmodule


module tick_generator #(
    parameter integer INPUT_FREQ = 100_000_000,    //100MHz
    parameter integer TICK_HZ = 1000    //1000Hz --> 1ms
 ) ( 
    input clk,
    input reset,
    output reg tick
 );   
 
    parameter TICK_COUNT =  INPUT_FREQ / TICK_HZ;   // 100_000

    reg [$clog2(TICK_COUNT)-1:0] r_tick_counter =0;  // 16 bits

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_tick_counter <= 0;
            tick <= 0;
        end else begin
            if ( r_tick_counter == TICK_COUNT-1  ) begin
                r_tick_counter <= 0;
                tick <= 1'b1;
            end else begin
                r_tick_counter = r_tick_counter + 1;
                tick <= 1'b0;
            end 
        end 
    end 
endmodule

module uart_tx # (parameter
        BAUD_RATE = 9600
) (
    input       clk,
    input       reset,
    input [7:0] tx_data,
    input       tx_start,
    
    output reg  tx,
    output reg  tx_busy,
    output reg  tx_done
    );

    parameter IDLE      = 2'b00,
              START_BIT = 2'b01,
              DATA_BITS = 2'b10,
              STOP_BIT  = 2'b11;

    parameter DIVIDER_COUNT = 100_000_000 / BAUD_RATE;

    reg [15:0] r_baud_cnt;   // 10416번 count
    reg        r_baud_tick;
    reg [1:0]  r_state;      // 상태천이
    reg [3:0]  r_bit_cnt;    // 전송 비트수 : 8
    reg [7:0]  r_data_reg;   // 전송할 1 byte

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_baud_cnt  <= 0;
            r_baud_tick <= 0;    
        end else begin
            if(r_baud_cnt == DIVIDER_COUNT - 1) begin
                r_baud_cnt  <= 0;
                r_baud_tick <= 1;            
            end else begin
                r_baud_cnt  <= r_baud_cnt + 1;
                r_baud_tick <= 0;
            end       
        end
    end

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_state    <= IDLE;
            r_bit_cnt  <= 0;
            r_data_reg <= 0;
            tx_busy    <= 0;
            tx_done    <= 0;
            tx         <= 1;                           
        end else begin
            case(r_state)
                IDLE : begin
                    tx_done <= 0;
                    if(tx_start) begin
                        r_state    <= START_BIT;
                        r_data_reg <= tx_data;
                        tx_busy    <= 1;
                        r_bit_cnt  <= 0;
                    end
                end
                START_BIT : begin
                    if(r_baud_tick) begin
                        tx      <= 0; // start bit
                        r_state <= DATA_BITS;
                    end
                end
                DATA_BITS : begin
                    if(r_baud_tick) begin
                        tx <= r_data_reg[r_bit_cnt]; // 
                        if(r_bit_cnt == 4'd7) begin
                            r_state <= STOP_BIT;    
                        end else begin
                            r_bit_cnt <= r_bit_cnt + 1;
                        end
                    end
                end
                STOP_BIT : begin
                    if(r_baud_tick) begin
                        tx      <= 1;
                        tx_done <= 1'b1; // 1byte 전송완료
                        tx_busy <= 1'b0; // 전송중이 아님
                        r_state <= IDLE;
                    end
                end
                default : begin
                    r_state <= IDLE;
                end                                                                
            endcase
        end
    end 
endmodule
