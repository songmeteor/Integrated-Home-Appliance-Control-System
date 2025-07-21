`timescale 1ns / 1ps

module fsm_air_conditioner(
    input clk,
    input reset,
    input btnC,
    output reg [1:0] mode
    );

    parameter IDLE   = 2'b00,
              AUTO   = 2'b01,
              MANUAL = 2'b10; 

    reg [1:0] current_state;
    reg [1:0] next_state;

    always @ (posedge clk, posedge reset) 
    begin
        if(reset) current_state <= IDLE;
        else      current_state <= next_state;
    end 

    always @(*) begin
        case (current_state)
        IDLE : begin
            next_state = AUTO;
        end
        AUTO : begin
            if(btnC) next_state = MANUAL;
            else next_state = AUTO;
        end
        MANUAL : begin
            if(btnC) next_state = AUTO;
            else next_state = MANUAL;
        end
        default : begin
            next_state = IDLE;
        end                
        endcase
    end

    always @(*) begin
        case (current_state)
        IDLE : begin
            mode = IDLE;
        end
        AUTO : begin
            mode = AUTO;
        end
        MANUAL : begin
            mode = MANUAL;
        end
        default : begin
            mode = IDLE;
        end                
        endcase
    end    

endmodule
