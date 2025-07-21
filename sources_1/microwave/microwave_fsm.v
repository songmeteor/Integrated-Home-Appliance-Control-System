`timescale 1ns / 1ps

module microwave_fsm(
    input        clk,
    input        reset,
    input        btnU,
    input        btnL,
    input        btnC,
    input        btnD,
    input [1:0]  top_mode,
    input        door,   // close : 0 , open : 1
    input [13:0] run_time,
    output reg [2:0] mode
    );

    parameter IDLE   = 3'b000,
              SET    = 3'b001,
              RUN    = 3'b010,
              STOP   = 3'b011,
              FINISH = 3'b100;

    reg [26:0]  tick_counter = 0;
    reg [3:0]   finish_counter = 0; 
    reg [2:0]   current_state, next_state;

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
        if (reset || (current_state != FINISH))
            finish_counter <= 0;
        else if (tick_1s)
            finish_counter <= finish_counter + 1;
    end    
    
    always @(*) begin
        case (current_state)
            IDLE : begin
                if(btnC && (top_mode == 2'b01)) next_state = SET;
                else     next_state = IDLE;
            end
            SET : begin
                if(btnC && !door && (run_time != 0)) next_state = RUN;
                else              next_state = SET;
            end
            RUN : begin
                if(door)                next_state = STOP;
                else if(btnL)           next_state = SET;
                else if(btnC)           next_state = STOP;
                else if(run_time == 0)  next_state = FINISH;
                else                    next_state = RUN;
            end
            STOP : begin
                if(btnC && !door) next_state = RUN;
                else              next_state = STOP;
            end
            FINISH : begin
                if(finish_counter >= 5) next_state = SET;
                else                    next_state = FINISH;
            end
            default : begin
                next_state = IDLE;
            end                                                
        endcase
    end

    always @ (posedge clk, posedge reset) 
    begin
        if(reset) current_state <= IDLE;
        else      current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE : begin
               mode = IDLE;
            end
            SET : begin
                mode = SET;
            end
            RUN : begin
                mode = RUN;
            end
            STOP : begin
                mode = STOP;
            end
            FINISH : begin
                mode = FINISH;
            end
            default : begin
                mode = IDLE;
            end                                                
        endcase        
    end
endmodule
