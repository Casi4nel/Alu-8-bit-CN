`timescale 1ns/1ps

module alu_8bit_tb;
    reg signed [7:0] a, b;
    reg [2:0] alu_op;
    reg cin;
  	reg clk;
    wire signed [15:0] result;
    wire cout;

    alu_8bit uut(
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .cin(cin),
        .result(result),
        .cout(cout),
        .clk(clk)
    );

    // Clock generation
    initial begin 
        clk = 0; 
        forever #5 clk = ~clk; 
    end
  	
  	// Waveform initialization
  	initial begin
        $dumpfile("waveform.vcd");  // Name of the VCD file
        $dumpvars(0, alu_8bit_tb);  // Dump everything in this module
    end

    // Inputs updated on falling edge
    initial begin
        // Reset
        a = 0; b = 0; alu_op = 0; cin = 0;
        @(negedge clk);

      	//Addition
        a = -8'sd5;    b =  8'sd3;    alu_op = 3'b000; cin = 0; @(negedge clk);
        a = -8'sd120;  b =  8'sd5;    alu_op = 3'b000; cin = 0; @(negedge clk);
        a = -8'sd45;   b =  8'sd0;    alu_op = 3'b000; cin = 0; @(negedge clk);

      	//Substraction
        a =  8'sd5;    b = -8'sd3;    alu_op = 3'b001; cin = 0; @(negedge clk);
        a =  8'sd11;   b = -8'sd20;   alu_op = 3'b001; cin = 0; @(negedge clk);
        a =  8'sd100;  b = -8'sd1;    alu_op = 3'b001; cin = 0; @(negedge clk);
        a =  8'sd110;  b = -8'sd8;    alu_op = 3'b001; cin = 0; @(negedge clk);

      	//Multiplication
        a = -8'sd4;    b =  8'sd3;    alu_op = 3'b101; cin = 0; @(negedge clk);
        a =  8'sd50;   b =  8'sd40;   alu_op = 3'b101; cin = 0; @(negedge clk);
        a =  8'sd5;    b =  8'sd3;    alu_op = 3'b101; cin = 0; @(negedge clk);
        a =  8'sd5;    b =  8'sd0;    alu_op = 3'b101; cin = 0; @(negedge clk);

      	//Division
        a = -8'sd9;    b =  8'sd2;    alu_op = 3'b110; cin = 0; @(negedge clk);
        a = -8'sd9;    b =  8'sd3;    alu_op = 3'b110; cin = 0; @(negedge clk);
        a = -8'sd9;    b =  8'sd0;    alu_op = 3'b110; cin = 0; @(negedge clk);
        a =  8'sd15;    b = -8'sd4;    alu_op = 3'b110; cin = 0; @(negedge clk);
        a = -8'sd121;  b = -8'sd1;    alu_op = 3'b110; cin = 0; @(negedge clk);

        $finish;
    end

    // Display outputs on rising edge
    always @(posedge clk) begin
      if(alu_op== 3'b110)
      $display("Time=%0t | a=%0d | b=%0d | op=%03b | cin=%b -> result=%0d | reminder=%0d |  cout=%b", 
                  $time, a, b, alu_op, cin, result, uut.div_rem , cout);
      
      else
        $display("Time=%0t | a=%0d | b=%0d | op=%03b | cin=%b -> result=%0d |  cout=%b", 
                  $time, a, b, alu_op, cin, result, cout);
      
    end

endmodule
