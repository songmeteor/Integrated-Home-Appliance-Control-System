`timescale 1ns / 1ps

module buzzer_controller (
    input clk,
    input reset,

    input pulse_U,
    input pulse_D,
    input pulse_L,
    input pulse_run, //button_c

    input [9:0] distance,

    output wire buzzer
);

    // 1ms 틱 생성기
    reg [16:0] ms_count;
    reg tick_1ms;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ms_count <= 0;
            tick_1ms <= 0;
        end else begin
            if (ms_count >= 99999) begin // 100MHz / 1kHz
                ms_count <= 0;
                tick_1ms <= 1;
            end else begin
                ms_count <= ms_count + 1;
                tick_1ms <= 0;
            end
        end
    end

    // --- beep 동작 (pulse_U, D, L, R) ---
    reg beep_active;
    reg [1:0] beep_step;    // 현재 소리의 단계 -> 3step을 가짐
    reg [11:0] beep_cnt;    // 현재 단계의 경과시간(ms)
    reg [11:0] beep_target; // 각 단계의 지속시간(기본:100ms)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            beep_active <= 0;
            beep_step <= 0;
            beep_cnt <= 0;
            beep_target <= 100;
        end else if ((pulse_U || pulse_D || pulse_L) && !beep_active) begin
            beep_active <= 1;
            beep_step <= 0;
            beep_cnt <= 0;
            beep_target <= 100;
        end else if (beep_active) begin
            if (tick_1ms) begin
                if (beep_cnt >= beep_target - 1) begin
                    beep_cnt <= 0;
                    beep_step <= beep_step + 1;
                    beep_target <= 100; // 100ms 고정
                    if (beep_step == 3) begin
                        beep_active <= 0;
                    end
                end else begin
                    beep_cnt <= beep_cnt + 1;
                end
            end
        end
    end

    wire [17:0] beep_div_val = (beep_step == 0) ? 18'd50000 :  // 1kHz (도)
                              (beep_step == 1) ? 18'd25000 :  // 2kHz (미)
                              (beep_step == 2) ? 18'd16667 :  // 3kHz (솔)
                                                    18'd0;

    reg [17:0] beep_div_cnt;    //현재 주기의 카운터
    reg beep_buz;   //실제 부저 출력신호(PWM)
    
    //beep_active 상태에서 beep_div_val주기마다 beep_buz 토글-> 사각파 생성
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            beep_div_cnt <= 0;
            beep_buz <= 0;
        end else if (beep_active && beep_div_val != 0) begin
            if (beep_div_cnt >= beep_div_val - 1) begin
                beep_div_cnt <= 0;
                beep_buz <= ~beep_buz;  //토글 사각파 생성
            end else begin
                beep_div_cnt <= beep_div_cnt + 1;
            end
        end else begin
            beep_div_cnt <= 0;
            beep_buz <= 0;
        end
    end

    // --- open 동작 (pulse_run) ---
    reg open_active;
    reg [2:0] open_step;
    reg [11:0] open_cnt;
    reg [11:0] open_target;
    reg open_buz;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            open_active <= 0;
            open_step <= 0;
            open_cnt <= 0;
            open_target <= 100;
        end else if (pulse_run && !open_active) begin
            open_active <= 1;
            open_step <= 0;
            open_cnt <= 0;
            open_target <= 100;
        end else if (open_active) begin
            if (tick_1ms) begin
                if (open_cnt >= open_target - 1) begin
                    open_cnt <= 0;
                    open_step <= open_step + 1;
                    if (open_step == 3)
                        open_target <= 3000;
                    else
                        open_target <= 100;

                    if (open_step == 4) begin
                        open_active <= 0;
                    end
                end else begin
                    open_cnt <= open_cnt + 1;
                end
            end
        end
    end

    wire [17:0] open_div_val = (open_step == 0) ? 18'd191213 :  // 도 (약 523Hz)
                              (open_step == 1) ? 18'd151661 :  // 미 (약 659Hz)
                              (open_step == 2) ? 18'd127551 :  // 솔 (약 784Hz)
                              (open_step == 3) ? 18'd90156  :  // 시 (약 988Hz)
                                                    18'd0;

    reg [17:0] open_div_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            open_div_cnt <= 0;
            open_buz <= 0;
        end else if (open_active && open_div_val != 0) begin
            if (open_div_cnt >= open_div_val - 1) begin
                open_div_cnt <= 0;
                open_buz <= ~open_buz;
            end else begin
                open_div_cnt <= open_div_cnt + 1;
            end
        end else begin
            open_div_cnt <= 0;
            open_buz <= 0;
        end
    end

    // --- distance 동작 (distance <= 5cm) ---
    reg distance_active;
    reg [1:0] distance_step;  // 0~3 : beep!beep!
    reg [11:0] distance_cnt;
    reg [11:0] distance_target;

    wire distance_trigger = (distance <= 10'd5); 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            distance_active <= 0;
            distance_step <= 0;
            distance_cnt <= 0;
            distance_target <= 100;
        end else if (distance_trigger && !distance_active && !beep_active && !open_active) begin
            distance_active <= 1;
            distance_step <= 0;
            distance_cnt <= 0;
            distance_target <= 100;
        end else if (distance_active) begin
            if (tick_1ms) begin
                if (distance_cnt >= distance_target - 1) begin
                    distance_cnt <= 0;
                    distance_step <= distance_step + 1;
                    distance_target <= 100;

                    if (distance_step == 3) begin
                        distance_active <= 0; // 모든 단계 끝나면 종료
                    end
                end else begin
                    distance_cnt <= distance_cnt + 1;
                end
            end
        end
    end

    wire [17:0] distance_div_val = (distance_step == 0) ? 18'd39810 :   // 미
                                (distance_step == 1) ? 18'd37500 :   // 파
                                (distance_step == 2) ? 18'd39810 :   // 미
                                (distance_step == 3) ? 18'd37500 :   // 파
                                                        18'd0;

    reg [17:0] distance_div_cnt;
    reg distance_buz;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            distance_div_cnt <= 0;
            distance_buz <= 0;
        end else if (distance_active && distance_div_val != 0) begin
            if (distance_div_cnt >= distance_div_val - 1) begin
                distance_div_cnt <= 0;
                distance_buz <= ~distance_buz;
            end else begin
                distance_div_cnt <= distance_div_cnt + 1;
            end
        end else begin
            distance_div_cnt <= 0;
            distance_buz <= 0;
        end
    end
        // --- 최종 부저 출력 ---
    // alarm이 우선, 다음 beep, 다음 open 순으로 우선순위 부여
    assign buzzer = distance_active ? distance_buz : 
                    (beep_active ? beep_buz :
                    (open_active ? open_buz : 1'b0));

endmodule

