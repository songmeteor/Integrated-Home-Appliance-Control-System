  `timescale 1ns / 1ps

// module dht11_controller(
//     input               clk,
//     input               reset,
//     output reg [7:0]    humidity,
//     output reg [7:0]    current_temperature,
//     inout               dht11_data
// );

//     // 상태 정의
//     localparam IDLE         = 3'd0,
//                LOW_18MS     = 3'd1,
//                HIGH_30US    = 3'd2,
//                LOW_80US     = 3'd3,
//                HIGH_80US    = 3'd4,
//                READ_DATA    = 3'd5;

//     // 데이터 읽기 내부 상태
//     localparam WAIT_POSEDGE = 1'b0,
//                WAIT_NEGEDGE = 1'b1;

//     // 내부 레지스터
//     reg [2:0]  current_state, next_state;
//     reg [21:0] count_microsec;
//     reg        count_enable;
//     reg        dht11_drive;       // 0 또는 Z
//     reg [5:0]  data_count;
//     reg [39:0] temp_data;
//     reg        read_state, next_read_state; // next_read_state 추가

//     wire       dht_pedge, dht_nedge;
//     wire       clk_1us;

//     // 데이터 버스 드라이브
//     assign dht11_data = dht11_drive ? 1'b0 : 1'bz;

//     // 모듈 인스턴스 (기존과 동일)
//     edge_detector ed_inst ( .clk(clk), .reset(reset), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge) );
//     s_tick_generator #( .INPUT_FREQ(100_000_000), .TICK_HZ(1_000_000) ) tg_us ( .clk(clk), .reset(reset), .tick(clk_1us) );

//     // =======================================================
//     // 1) 순차 논리 블록들 (Sequential Logic)
//     // =======================================================

//     // 상태 레지스터
//     always @(posedge clk or posedge reset) begin
//         if (reset) current_state <= IDLE;
//         else       current_state <= next_state;
//     end

//     // 마이크로초 카운터 (clk_1us 틱으로 카운트)
//     always @(posedge clk or posedge reset) begin
//         if (reset)                count_microsec <= 0;
//         else if (count_enable && clk_1us) count_microsec <= count_microsec + 1;
//         else if (!count_enable)   count_microsec <= 0;
//     end

//     // 데이터 처리 관련 레지스터
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             read_state          <= WAIT_POSEDGE;
//             data_count          <= 0;
//             temp_data           <= 0;
//             humidity            <= 0;
//             current_temperature <= 0;
//         end else begin
//             read_state <= next_read_state;

//             // READ_DATA 상태에서 비트 수신 시
//             if (current_state == READ_DATA && read_state == WAIT_NEGEDGE && dht_nedge) begin
//                 temp_data  <= { temp_data[38:0], (count_microsec < 45) ? 1'b0 : 1'b1 };
//                 data_count <= data_count + 1;
//             end

//             // 통신이 성공적으로 끝나면 최종 값 저장
//             if (next_state == IDLE && current_state == READ_DATA && data_count == 40) begin
//                 // 체크섬 검증 로직 (선택 사항이지만 추천)
//                 if (temp_data[7:0] == (temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8])) begin
//                     humidity            <= temp_data[39:32];
//                     current_temperature <= temp_data[23:16];
//                 end
//                 data_count <= 0; // 카운터 리셋
//             end else if (next_state == IDLE) begin // 통신 중간에 IDLE로 돌아가면 리셋
//                  data_count <= 0;
//             end
//         end
//     end

//     // =======================================================
//     // 2) 조합 논리 블록 (Combinational Logic)
//     // =======================================================
//     always @(*) begin
//         // 기본값 설정
//         next_state      = current_state;
//         next_read_state = read_state;
//         count_enable    = 1'b0;
//         dht11_drive     = 1'b0; // 기본적으로 Z 상태 (드라이브 비활성화)

//         case (current_state)
//             IDLE: begin
//                 dht11_drive  = 1'b0; // Z
//                 count_enable = 1'b1;
//                 if (count_microsec >= 22'd2_000_000) begin // 2초 대기
//                     next_state = LOW_18MS;
//                 end
//             end
//             LOW_18MS: begin
//                 dht11_drive  = 1'b1; // 0 드라이브
//                 count_enable = 1'b1;
//                 if (count_microsec >= 22'd20_000) begin // 20ms
//                     next_state = HIGH_30US;
//                 end
//             end
//             HIGH_30US: begin
//                 dht11_drive  = 1'b0; // Z
//                 count_enable = 1'b1;
//                 if (dht_nedge) begin
//                     next_state = LOW_80US;
//                 end else if (count_microsec >= 22'd100) begin // 100us 타임아웃
//                     next_state = IDLE; // 타임아웃 시 재시작
//                 end
//             end
//             LOW_80US: begin
//                 dht11_drive = 1'b0; // Z
//                 if (dht_pedge) next_state = HIGH_80US;
//             end
//             HIGH_80US: begin
//                 dht11_drive = 1'b0; // Z
//                 if (dht_nedge) next_state = READ_DATA;
//             end
//             READ_DATA: begin
//                 dht11_drive = 1'b0; // Z
//                 if (data_count >= 6'd40) begin
//                     next_state = IDLE;
//                 end else begin
//                     // count_enable 제어 로직
//                     if (read_state == WAIT_NEGEDGE) begin
//                         count_enable = 1'b1; // HIGH 구간 시간 측정
//                     end else begin
//                         count_enable = 1'b0; // LOW 구간은 시간 측정 안 함
//                     end

//                     // read_state 전이 로직
//                     if (read_state == WAIT_POSEDGE && dht_pedge) begin
//                         next_read_state = WAIT_NEGEDGE;
//                     end else if (read_state == WAIT_NEGEDGE && dht_nedge) begin
//                         next_read_state = WAIT_POSEDGE;
//                     end
//                 end
//             end
//         endcase
//     end
// endmodule


// // ================= edge_detector =================
// module edge_detector(
//     input  wire clk,
//     input  wire reset,
//     input  wire cp,
//     output reg  p_edge,
//     output reg  n_edge
// );
//     reg cp_prev;
//     always @(posedge clk or posedge reset) begin
//         if (reset)      cp_prev <= 1'b0;
//         else            cp_prev <= cp;
//     end
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             p_edge <= 1'b0;
//             n_edge <= 1'b0;
//         end else begin
//             p_edge <= (~cp_prev & cp);
//             n_edge <= (cp_prev & ~cp);
//         end
//     end
// endmodule


// // ================= tick_generator =================
// module s_tick_generator #(
//     parameter integer INPUT_FREQ = 100_000_000,  // 100MHz
//     parameter integer TICK_HZ    = 1_000_000     // 1MHz → 1µs
// )(
//     input   clk,
//     input   reset,
//     output  reg tick
// );
//     localparam integer COUNT_MAX = INPUT_FREQ / TICK_HZ;
//     reg [$clog2(COUNT_MAX)-1:0] counter;

//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             counter <= 0;
//             tick    <= 1'b0;
//         end else if (counter == COUNT_MAX-1) begin
//             counter <= 0;
//             tick    <= 1'b1;
//         end else begin
//             counter <= counter + 1;
//             tick    <= 1'b0;
//         end
//     end
// endmodule

// `timescale 1ns / 1ps

// module dht11_controller(
//     input clk,
//     input reset,

//     output reg [7:0] humidity,
//     output reg [7:0] current_temperature,
    
//     inout dht11_data
// );
//     parameter IDLE = 3'b000,
//               LOW_18MS = 3'b001,
//               HIGH_30US = 3'b010,
//               LOW_80US = 3'b011,
//               HIGH_80US = 3'b100,
//               READ_DATA = 3'b101;

//     parameter WAIT_POSEDGE = 1'b0,
//               WAIT_NEGEDGE = 1'b1;

//     reg [2:0]  current_state, next_state;
//     reg        read_state;           
//     reg [21:0] count_microsec;
//     reg        count_microsec_enable;
//     reg        dht11_buffer;
//     reg [39:0] temp_data;
//     reg [5:0]  data_count;

//     wire clk_microsec;
//     wire dht_pedge, dht_nedge;

//     edge_detector_n ed(
//         .clk(clk), .reset(reset), .cp(dht11_data),
//         .p_edge(dht_pedge), .n_edge(dht_nedge)
//     );

//     tick_generator #(
//         .INPUT_FREQ(100_000_000),
//         .TICK_HZ(1000000)    //1Hz --> 1초에 한번 tick
//     ) u_tick_1Hz(
//         .clk(clk),
//         .reset(reset),
//         .tick(clk_microsec)        
//     );

//     always@(negedge clk, posedge reset) begin
//         if(reset) count_microsec = 0;
//         else if(clk_microsec && count_microsec_enable) count_microsec = count_microsec + 1;
//         else if(!count_microsec_enable) count_microsec = 0;
//     end

//     always @(negedge clk, posedge reset) begin
//         if(reset) current_state = IDLE;
//         else current_state = next_state;
//     end

//     assign dht11_data = dht11_buffer;

//     always @(posedge clk, posedge reset) begin
//         if(reset) begin
//             next_state = IDLE;
//             read_state = WAIT_POSEDGE;
//             temp_data = 0;
//             data_count = 0;
//         end else begin
//             case(current_state) 
//                 IDLE : begin
//                     if(count_microsec < 22'd3_000_000) begin
//                         count_microsec_enable = 1;
//                         dht11_buffer = 'bz;
//                     end else begin
//                         count_microsec_enable = 0;
//                         next_state = LOW_18MS;
//                     end
//                 end
//                 LOW_18MS : begin
//                     if(count_microsec < 22'd20_000) begin
//                         dht11_buffer = 0;
//                         count_microsec_enable = 1;
//                     end else begin
//                         count_microsec_enable = 0;
//                         next_state = HIGH_30US;
//                     end
//                 end 
//                 HIGH_30US : begin
//                     if(count_microsec < 22'd20_000) begin
//                         count_microsec_enable = 1;
//                         dht11_buffer = 'bz;
//                     end else if(dht_nedge) begin
//                         count_microsec_enable = 0;
//                         next_state = LOW_80US;
//                     end
//                 end
//                 LOW_80US : begin
//                     if(dht_pedge) begin
//                         next_state = HIGH_80US;
//                     end
//                 end
//                 HIGH_80US : begin
//                     if(dht_nedge) begin
//                         next_state = READ_DATA;
//                     end
//                 end
//                 READ_DATA : begin
//                     case(read_state) 
//                         WAIT_POSEDGE : begin
//                             if(dht_pedge) read_state = WAIT_NEGEDGE;
//                             count_microsec_enable = 0;
//                         end
//                         WAIT_NEGEDGE : begin
//                             if(dht_nedge) begin
//                                 if(count_microsec < 45) begin
//                                     temp_data = {temp_data[38:0], 1'b0};
//                                 end else begin
//                                     temp_data = {temp_data[38:0], 1'b1};
//                                 end
//                                 data_count = data_count + 1;
//                                 read_state = WAIT_POSEDGE;
//                             end else begin
//                                 count_microsec_enable = 1;
//                             end
//                         end
//                     endcase
//                     if(data_count >= 40) begin
//                         data_count = 0;
//                         next_state = IDLE;
//                         humidity = temp_data[39:32];
//                         current_temperature = temp_data[23:16]; 
//                     end
//                 end               
//             endcase
//         end
//     end

// endmodule

// module edge_detector_n (
//     input wire clk,
//     input wire reset,
//     input wire cp,
//     output reg p_edge,
//     output reg n_edge
// );

//     // 입력 신호 cp의 이전 상태를 저장하기 위한 레지스터
//     reg cp_prev;

//     // 클럭에 맞춰 cp의 현재 값을 cp_prev에 저장합니다.
//     // 리셋 시에는 0으로 초기화합니다.
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             cp_prev <= 1'b0;
//         end else begin
//             cp_prev <= cp;
//         end
//     end

//     // 현재 cp 값과 이전 값(cp_prev)을 비교하여 에지를 감지합니다.
//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             p_edge <= 1'b0;
//             n_edge <= 1'b0;
//         end else begin
//             // 상승 에지 감지 (이전: 0, 현재: 1)
//             p_edge <= ~cp_prev & cp;
            
//             // 하강 에지 감지 (이전: 1, 현재: 0)
//             n_edge <= cp_prev & ~cp;
//         end
//     end

// endmodule

//  module tick_generator #(
//     parameter integer INPUT_FREQ = 100_000_000,    //100MHz
//     parameter integer TICK_HZ = 1000    //1000Hz --> 1ms
//  ) ( 
//     input clk,
//     input reset,
//     output reg tick
//  );   
 
//     parameter TICK_COUNT =  INPUT_FREQ / TICK_HZ;   // 100_000

//     reg [$clog2(TICK_COUNT)-1:0] r_tick_counter =0;  // 16 bits

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             r_tick_counter <= 0;
//             tick <= 0;
//         end else begin
//             if ( r_tick_counter == TICK_COUNT-1  ) begin
//                 r_tick_counter <= 0;
//                 tick <= 1'b1;
//             end else begin
//                 r_tick_counter <= r_tick_counter + 1;
//                 tick <= 1'b0;
//             end 
//         end 
//     end 
// endmodule

module dht11_controller(
    input clk,
    input reset,

    output reg [7:0] humidity,
    output reg [7:0] current_temperature,
    inout dht11_data
    );

    parameter COUNT_1US = 100;
    parameter COUNT_1MS = 100_000;
    parameter COUNT_1S  = 100_000_000;
    parameter WAIT_SECOND = 3;

    localparam IDLE               = 4'b0000,
               START_LOW          = 4'b0001,
               START_HIGH         = 4'b0010,
               RESP_LOW           = 4'b0011,
               RESP_HIGH          = 4'b0100,
               WAIT_BIT_LOW_START = 4'b0101,
               DATA_WAIT_LOW_END  = 4'b0110, 
               DATA_MEASURE_HIGH  = 4'b0111, 
               DATA_PROCESS       = 4'b1000, 
               DATA_END           = 4'b1001,
               ERROR              = 4'b1111; 

    reg [3:0]  state;
    reg [23:0] timer_count;
    reg [28:0] second_counter;
    reg [39:0] data_buffer;
    reg [5:0]  bit_count;
    reg        dht_data_out;
    reg        dht_data_en;  

    assign dht11_data = dht_data_en ? dht_data_out : 1'bz;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state             <= IDLE;
            timer_count       <= 0;
            second_counter    <= 0;
            data_buffer       <= 0;
            bit_count         <= 0;
            dht_data_en       <= 1;
            dht_data_out      <= 1;
            humidity             <= 0;    
            current_temperature  <= 0;             
        end else begin
            case(state)
                IDLE : begin
                    dht_data_en  <= 1;
                    dht_data_out <= 1;
                    if (second_counter >= (WAIT_SECOND * COUNT_1S) - 1) begin
                        state <= START_LOW;
                        timer_count <= 0;
                        second_counter <= 0;
                        dht_data_out <= 0;
                    end else begin
                        second_counter <= second_counter + 1;
                    end
                end
                START_LOW : begin   //18ms 동안 LOW 출력
                    dht_data_en   <= 1;   // 출력 모드
                    dht_data_out  <= 0;                
                    if (timer_count < 20 * COUNT_1MS) begin
                        timer_count <= timer_count + 1;
                    end else begin
                        state <= START_HIGH;
                        timer_count <= 0;
                        dht_data_out <= 1;  
                    end            
                end
                START_HIGH : begin   //30us 동안 HIGH 출력
                    dht_data_en   <= 1;   // 여전히 출력 모드
                    dht_data_out  <= 1;
                    if (timer_count < 30 * COUNT_1US) begin
                        timer_count <= timer_count + 1;
                    end else begin
                        state <= RESP_LOW;
                        dht_data_en <= 0;  // 입력 모드
                        timer_count <= 0;
                    end            
                end
                RESP_LOW : begin
                    dht_data_en   <= 0;
                    if (dht11_data == 1'b0) begin
                        state <= RESP_HIGH;
                        timer_count <= 0;
                    end else if (timer_count > (200 * COUNT_1US)) begin // 200us 타임아웃
                        state <= ERROR;
                        timer_count <= 0;
                    end else begin
                        timer_count <= timer_count + 1;
                    end           
                end
                RESP_HIGH : begin
                    dht_data_en   <= 0;
                    if (dht11_data == 1'b1) begin
                        state <= WAIT_BIT_LOW_START;
                        bit_count <= 0;
                        timer_count <= 0;
                    end else if (timer_count > (300 * COUNT_1US)) begin // 300us 타임아웃
                        state <= ERROR;
                        timer_count <= 0;
                    end else begin
                        timer_count <= timer_count + 1;
                    end        
                end
                WAIT_BIT_LOW_START : begin
                    dht_data_en   <= 0;
                    if (dht11_data == 1'b0) begin
                        state       <= DATA_WAIT_LOW_END;
                        timer_count <= 0;
                    end else if (timer_count > (200 * COUNT_1US)) begin // 200us 타임아웃
                        state <= ERROR;
                        timer_count <= 0;
                    end else begin
                        timer_count <= timer_count + 1;
                    end               
                end
                DATA_WAIT_LOW_END : begin
                    dht_data_en   <= 0;
                    if (dht11_data == 1'b1) begin
                        state <= DATA_MEASURE_HIGH;
                        timer_count <= 0; 
                    end else if (timer_count > (200 * COUNT_1US)) begin // 200us 타임아웃
                        state <= ERROR;
                    end else begin
                        timer_count <= timer_count + 1;
                    end
                end

                DATA_MEASURE_HIGH : begin
                    dht_data_en   <= 0;
                    timer_count <= timer_count + 1;
                    if (dht11_data == 1'b0) begin
                        state <= DATA_PROCESS;
                    end 
                end

                // DATA_MEASURE_HIGH : begin
                //     dht_data_en <= 0;
                //     if (dht11_data == 1'b0) begin
                //         state <= DATA_PROCESS;
                //     end else begin
                //         // 이 코드는 HIGH->LOW로 바뀌는 마지막 순간에 실행되지 않아
                //         // 타이머 값이 1만큼 부족하게 측정됩니다.
                //         timer_count <= timer_count + 1;
                //     end
                // end

                DATA_PROCESS : begin
                    dht_data_en   <= 0;
                    data_buffer <= {data_buffer[38:0], (timer_count > (45 * COUNT_1US))};
                    if(bit_count == 39) begin
                        state       <= DATA_END;
                        timer_count <= 0;    
                    end else begin
                        bit_count <= bit_count + 1;
                        state <= WAIT_BIT_LOW_START;
                        timer_count <= 0;                            
                    end
                end
                //(data_buffer[39:32] + data_buffer[31:24] + data_buffer[23:16] + data_buffer[15:8]) == data_buffer[7:0]
                DATA_END : begin
                    if ((data_buffer[39:32] + data_buffer[31:24] + data_buffer[23:16] + data_buffer[15:8]) == data_buffer[7:0]) begin
                        humidity            <= data_buffer[39:32];
                        current_temperature <= data_buffer[23:16];
                    end
                    state             <= IDLE;
                    timer_count       <= 0;
                    data_buffer       <= 0;
                    bit_count         <= 0;
                    dht_data_en       <= 1;
                    dht_data_out      <= 1;          
                end
                ERROR : begin
                    state       <= IDLE; // 에러 발생 시 IDLE로 돌아가 다시 시도
                    timer_count <= 0;  
                    data_buffer <= 0;
                    bit_count   <= 0; 
                    dht_data_en <= 1;
                    dht_data_out <= 1;                    
                end
                default : state <= IDLE;                                                                                     
            endcase
        end
    end                      
endmodule


