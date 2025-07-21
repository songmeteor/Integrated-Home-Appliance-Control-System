`timescale 1ns / 1ps

module tb_dht11;

    // Parameter definitions
    parameter CLK_PERIOD = 10; // Clock period (10ns -> 100MHz)
    parameter US_DELAY   = 1000;
    parameter MS_DELAY   = 1000 * 1000;

    // Testbench signal declarations
    reg   clk;
    reg   reset;
    wire [7:0] humidity;
    wire [7:0] current_temperature;
    
    // Signals for simulating the inout port
    wire  dht11_data;      // Data line from the DUT
    reg   dht11_data_tb;   // Data value controlled by the testbench
    reg   dht11_en_tb;     // Enable signal for testbench to control the data line

    // Instantiate the DUT (Device Under Test)
    dht11_controller uut (
        .clk(clk),
        .reset(reset),
        .humidity(humidity),
        .current_temperature(current_temperature),
        .dht11_data(dht11_data)
    );

    // Implement a tri-state buffer to allow the testbench to control the dht11_data line
    // When dht11_en_tb is 1, testbench writes the value; otherwise, it's in high-impedance (Z) state.
    assign dht11_data = dht11_en_tb ? dht11_data_tb : 1'bz;

    // 1. Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 2. Test Scenario (Main Block)
    initial begin
        // Simulation start message
        $display("T=%0t: << DHT11 Controller Testbench Start >>", $time);

        // Initialization
        initialize();
        
        // Wait for the DUT's start signal
        wait_for_dut_start();

        // Simulate sensor response and data transmission
        respond_and_send_data();
        
        // Check the results
        check_results();
        
        // End simulation
        $display("T=%0t: << Test Complete >>", $time);
        $finish;
    end

    // Task: Initialize
    task initialize;
    begin
        reset = 1;
        dht11_en_tb = 0; // Let the DUT control the line initially
        dht11_data_tb = 1;
        repeat(5) @(posedge clk);
        reset = 0;
        $display("T=%0t: Reset complete. Waiting for DUT to initiate communication (approx. 3 seconds).", $time);
    end
    endtask

    // Task: Wait for DUT's start signal
    task wait_for_dut_start;
    begin
        // Wait until the DUT pulls the dht11_data line LOW
        wait (dht11_data === 1'b0);
        $display("T=%0t: DUT start signal (Start Low) detected.", $time);
        
        // Wait until the DUT releases the line to High-Z (after entering START_HIGH state)
        wait (dht11_data === 1'bz);
        $display("T=%0t: DUT has released the data line. Starting sensor response.", $time);
    end
    endtask

    // Task: Respond and send data from the sensor
    task respond_and_send_data;
        // Test Data: Humidity=60% (0x3C), Temperature=28C (0x1C)
        // Checksum: 0x3C + 0x00 + 0x1C + 0x00 = 0x58
        reg [39:0] test_data;
        integer i;
        begin
        test_data = 40'h3C001C0058;
        dht11_en_tb <= 1; // Testbench starts controlling the data line

        // 1. Sensor response signal (80us LOW -> 80us HIGH)
        $display("T=%0t: Starting to send sensor response signal.", $time);
        dht11_data_tb <= 0;
        #(80 * US_DELAY);
        dht11_data_tb <= 1;
        #(80 * US_DELAY);
        $display("T=%0t: Sensor response signal sent. Starting to send data bits.", $time);

        // 2. Send 40 bits of data
        for (i = 39; i >= 0; i = i - 1) begin
            send_bit(test_data[i]);
        end
        
        // Release the line after transmission is complete
        dht11_data_tb <= 0; // Keep the line LOW after the last bit
        #(50 * US_DELAY);
        dht11_en_tb <= 0;   // Testbench stops controlling the line
        $display("T=%0t: 40-bit data transmission complete. Handing control of data line back to DUT.", $time);
    end
    endtask
    
    // Task: Send 1 bit of data
    // DHT11 Protocol:
    // - Every bit starts with a 50us LOW signal
    // - '0' : Followed by 26-28us HIGH
    // - '1' : Followed by 70us HIGH
    task send_bit;
        input bit_val;
        begin
            dht11_data_tb <= 0; // 50us LOW
            #(50 * US_DELAY);
            dht11_data_tb <= 1; // HIGH
            if (bit_val == 0) begin
                #(28 * US_DELAY); // HIGH time for a '0'
            end else begin
                #(70 * US_DELAY); // HIGH time for a '1'
            end
        end
    endtask
    
    // Task: Check results
    task check_results;
    begin
        // Give the DUT time to process the data and update its output registers
        #(200 * US_DELAY);
        
        $display("T=%0t: Checking final results...", $time);
        $display(" - Expected: Humidity=0x3C (%d), Temperature=0x1C (%d)", 8'h3C, 8'h1C);
        $display(" - Measured: Humidity=%h (%d), Temperature=%h (%d)", humidity, humidity, current_temperature, current_temperature);
        
        if (humidity === 8'h3C && current_temperature === 8'h1C) begin
            $display("SUCCESS: Measured humidity and temperature match expected values!");
        end else begin
            $error("FAILURE: Measured values do not match expected values!");
        end
    end
    endtask

endmodule