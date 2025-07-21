`timescale 1ns / 1ps

module tb_ultrasonic;

    // Testbench signal declaration
    reg clk;
    reg reset;
    wire trig;
    reg echo;
    wire [9:0] distance;

    // Instantiate the DUT (Device Under Test)
    ultrasonic_controller uut (
        .clk(clk),
        .reset(reset),
        .trig(trig),
        .echo(echo),
        .distance(distance)
    );

    // 1. Clock generation (100MHz clock, 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 2. Test scenario
    initial begin
        // --- Scenario 1: Normal Distance Measurement Test ---
        $display("-------------------------------------------");
        $display(">> Scenario 1: Normal Distance Measurement Test Start");
        
        // Initial values and reset pulse
        reset = 1;
        echo = 0;
        #20; // Hold reset for 20ns
        reset = 0;
        $display("[%0t ns] Reset complete. Waiting 500ms in IDLE state.", $time);
        
        // Wait for the state to transition from IDLE to TRIGGERING
        // by detecting the rising edge of the trig signal.
        @(posedge trig);
        $display("[%0t ns] Trig signal asserted (High). Holding for 10us.", $time);
        
        // Wait for the trig signal to go low (after 10us)
        @(negedge trig);
        $display("[%0t ns] Trig signal de-asserted (Low). Waiting for Echo signal.", $time);
        
        // Simulate the echo signal for a distance of 10cm.
        #100;
        echo = 1;
        $display("[%0t ns] Echo signal received (High). Starting distance measurement.", $time);
        
        // Hold echo high for a duration that produces a result of 10
        #584_000; 
        echo = 0;
        $display("[%0t ns] Echo signal finished (Low). Calculating distance.", $time);

        // Wait a moment for the calculation to complete
        #100;
        $display(">> Measured distance: %d", distance);
        if (distance == 10) begin
            $display(">> Result: Scenario 1 PASSED!");
        end else begin
            $display(">> Result: Scenario 1 FAILED! Measured: %d, Expected: 10", distance);
        end
        $display("-------------------------------------------\n");

        // End simulation after Scenario 1 is complete
        $display("Normal distance test complete. Finishing simulation.");
        $finish;
    end

    // Monitor: Print the distance value whenever it changes
    initial begin
        $monitor("[%0t ns] Current measured distance: %d", $time, distance);
    end

endmodule