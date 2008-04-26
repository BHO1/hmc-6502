// pathtest.sv
// tests path through 
// tbarr at cs dot hmc dot edu

`timescale 1 ns / 1 ps

module pathtest;
  reg ph1, ph2, reset;
  
  logic [15:0] expected_values [4095:0];
  logic [11:0]  current_expectation;
  logic [7:0]  misses;
  
  wire [7:0] data;
  
  top top(ph1, ph2, reset);
  
  always begin
    ph1 <= 1; #8; ph1 <= 0; #12;
  end
  always begin
    ph2 <= 0; #10; ph2 <= 1; #8; ph2 <= 0; #2;
  end
  
  // watch for expected address path
  always begin
    #10;
    // now, at the rising edge of ph2, compare value on address bus with
    // what we should have.
    if (top.address == expected_values[current_expectation]) begin
      $display("stepped correctly at %d after %d, moving on", 
                current_expectation, misses);
      misses = 8'd0;
      current_expectation = current_expectation + 1;
    end
    else begin
      misses = misses + 1;
      // $display("missed expectation");
      if (misses > 8'd10) begin
        $display("clocked out, failed on step %d waiting for 0x%h", 
              current_expectation, expected_values[current_expectation]);
        $stop;
      end
    end
    #10;
  end
  
  initial begin
    // init variables for expectation system
    misses = 8'd0;
    current_expectation = 12'd0;
    $readmemh("test/paths/test.path", expected_values);
    
    // init ROM
    top.mem.ROM[4093] = 8'hf0;
    top.mem.ROM[4092] = 8'h00;
    
    // path relative to this file.
    $readmemh("test/roms/PowerTest.rom", top.mem.ROM);
    
    // start test
    reset = 1;
    #100;
    reset = 0;
    #1000;
    assert (top.mem.RAM[66] == 8'hCF) $display ("PASSED Power Test");
      else $error("FAILED Power Test");
    $dumpflush;
  end
endmodule
