`timescale 1ns / 1ps

module ultrasonic_controller (
    input         clk,          
    input         reset,         
    output        trig,         
    input         echo,         
    output  [9:0] distance
);

    localparam IDLE         = 2'b00;
    localparam TRIGGERING   = 2'b01;
    localparam WAITING_ECHO = 2'b10;
    localparam MEASURING    = 2'b11;

    localparam ECHO_TIMEOUT = 3_000_000; // 30ms 타임아웃을 위한 카운트 값

    reg [1:0] state = IDLE;

    reg [26:0] timer;     
    reg [21:0] echo_width_counter; 

    reg        trig_reg = 0;
    reg [9:0] distance_reg = 0;

    assign trig = trig_reg;
    assign distance = distance_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            timer <= 0;
            echo_width_counter <= 0;
            trig_reg <= 0;
            distance_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (timer < 5_000_0000) begin //500ms 대기(5_000_0000)
                        timer <= timer + 1;
                    end else begin
                        timer <= 0;
                        state <= TRIGGERING; 
                    end
                end

                TRIGGERING: begin
                    trig_reg <= 1; 
                    if (timer < 1000) begin  //10us HIGH 유지 후 LOW
                        timer <= timer + 1;
                    end else begin
                        trig_reg <= 0; 
                        timer <= 0;
                        state <= WAITING_ECHO; 
                    end
                end

                WAITING_ECHO: begin
                    if (echo) begin
                        state <= MEASURING; 
                        echo_width_counter <= 0;
                    end else if (timer >= ECHO_TIMEOUT) begin 
                        state <= IDLE; 
                    end else begin 
                        timer <= timer + 1; 
                    end
                end

                MEASURING: begin
                    if (echo) begin
                        echo_width_counter <= echo_width_counter + 1;
                    end else begin
                        distance_reg <= echo_width_counter / 5830;
                        state <= IDLE; // 다시 대기 상태로 복귀
                        timer <= 0;
                    end
                end
            endcase
        end
    end
endmodule