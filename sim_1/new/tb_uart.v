`timescale 1ns / 1ps

module tb_uart;

    // 파라미터 정의
    parameter CLK_PERIOD = 10; // 10ns -> 100MHz

    // 테스트벤치 신호 선언
    reg             clk;
    reg             reset;
    reg             ultrasonic_mode;
    reg     [7:0]   humidity;
    reg     [7:0]   current_temperature;
    reg     [9:0]   distance;
    
    wire            tx;

    // DUT (Device Under Test) 인스턴스화
    uart_controller uut (
        .clk(clk),
        .reset(reset),
        .ultrasonic_mode(ultrasonic_mode),
        .humidity(humidity),
        .current_temperature(current_temperature),
        .distance(distance),
        .tx(tx)
    );

    // 1. 클럭 생성
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 2. 테스트 시나리오
    initial begin
        $display(">> Testbench Started");
        
        // --- 초기화 ---
        reset = 1;
        ultrasonic_mode = 0;
        humidity = 0;
        current_temperature = 0;
        distance = 0;
        #100; // 100ns 동안 리셋 유지
        reset = 0;
        $display("[%0t ns] Reset released. Waiting for the first 1Hz trigger.", $time);
        
        // --- 시나리오 1: DHT11 모드 (온습도) 데이터 전송 ---
        $display("\n>> Scenario 1: Testing DHT11 Mode (ultrasonic_mode = 0)");
        
        // 테스트할 온습도 값 설정
        humidity <= 8'd58; // 58%
        current_temperature <= 8'd25; // 25도
        ultrasonic_mode <= 0;
        
        $display("[%0t ns] Set Humidity=58, Temperature=25. Expected UART output: 'H:58, T:25\\n\\r'", $time);
        
        // 1Hz tick이 발생하여 데이터 전송이 완료될 때까지 충분히 대기 (약 1.1초)
        #(20 * 1_000_000);
        $display("[%0t ns] Scenario 1 finished. Check waveform for UART 'tx' signal.", $time);
        
        // --- 시나리오 2: 초음파 모드 (거리) 데이터 전송 ---
        $display("\n>> Scenario 2: Testing Ultrasonic Mode (ultrasonic_mode = 1)");

        // 테스트할 거리 값 설정
        distance <= 10'd123; // 123 cm
        ultrasonic_mode <= 1;

        $display("[%0t ns] Set Distance=123. Expected UART output: 'D:123\\n\\r'", $time);
        
        // 다음 1Hz tick이 발생하여 데이터 전송이 완료될 때까지 충분히 대기 (약 1.1초)
        #(20 * 1_000_000); 
        $display("[%0t ns] Scenario 2 finished. Check waveform for UART 'tx' signal.", $time);

        // 시뮬레이션 종료
        $display("\n>> All scenarios complete. Finishing simulation.");
        $finish;
    end
    
    // 모니터링: tx 신호가 변경될 때마다 출력 (디버깅용)
    initial begin
        $monitor("[%0t ns] tx = %b", $time, tx);
    end

endmodule