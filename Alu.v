`timescale 1ns/1ps

// 1-bit Full Adder Module
module full_adder (
    input  a, b, cin,
    output sum, cout
);
    wire w1, w2, w3;
    xor (w1, a, b);
    xor (sum, w1, cin);
    and (w2, a, b);
    and (w3, w1, cin);
    or  (cout, w2, w3);
endmodule

// 8-bit Booth Radix-2 Multiplication Module
module booth_multiplier (
    input  signed [7:0]  a, b,    // A: multiplicand, B: multiplier
    output signed [15:0] result    // Full 16-bit product
);
    reg signed [16:0] temp;         // [16] = Booth extra bit
    reg signed [7:0]  multiplicand;
    reg signed [7:0]  neg_multiplicand;
    integer i;

    always @* begin
        multiplicand     = a;
        neg_multiplicand = -a;
        temp = {8'b0, b, 1'b0};      // P=0, B=b, B-1=0

        for (i = 0; i < 8; i = i + 1) begin
            case (temp[1:0])
                2'b01: temp[16:1] = temp[16:1] + {multiplicand, 8'b0};     // +A<<0
                2'b10: temp[16:1] = temp[16:1] + {neg_multiplicand, 8'b0}; // –A<<0
                default: ;  // no op for 00 or 11
            endcase
            temp = $signed(temp) >>> 1;  // arithmetic shift right
        end
    end

    assign result = temp[16:1];     // top 16 bits
endmodule

// 8-bit SRT Radix-2 Division
module signed_divider (
    input  signed [7:0] a, b,
    output reg   signed [7:0] result,
    output reg   signed [7:0] rem  // New port for remainder
);
    reg [7:0] abs_a;
    reg [7:0] abs_b;
    reg signed [15:0] remainder;   // 16 bits signed for intermediate calculations
    reg signed [15:0] quotient;    // 16 bits signed for quotient accumulation
    reg signed [2:0] qi;           // Quotient digit: -1, 0, or 1
    reg sign;
    integer i;

    always @* begin
        if (b == 0) begin
            result = {8{1'bx}};  // Division by zero: indicate error (FF)
            rem    = {8{1'bx}};
        end else begin
            // Determine sign and absolute values
            sign  = a[7] ^ b[7];
            abs_a = a[7] ? -a : a;
            abs_b = b[7] ? -b : b;

            // Initialize
            remainder = 0;
            quotient  = 0;

            // Division loop (MSB to LSB)
            for (i = 7; i >= 0; i = i - 1) begin
                remainder = (remainder << 1) | ((abs_a >> i) & 1);

                // Select quotient digit
                if (remainder >= $signed({8'b0, abs_b})) begin
                    qi = 1;
                    remainder = remainder - $signed({8'b0, abs_b});
                end else if (remainder <= -$signed({8'b0, abs_b})) begin
                    qi = -1;
                    remainder = remainder + $signed({8'b0, abs_b});
                end else begin
                    qi = 0;
                    // remainder unchanged
                end

                quotient = (quotient << 1) + qi;
            end

            // Euclidean adjustment: ensure remainder is non-negative
            if (remainder < 0) begin
                remainder = remainder + $signed({8'b0, abs_b});
                quotient  = quotient - 1;
            end

            // Apply sign to quotient and output
            result = sign ? -quotient[7:0] : quotient[7:0];
            rem    = remainder[7:0]; // Optional: could force positive remainder if needed
        end
    end
endmodule


// 8-bit ALU Module (supports signed add/sub, bitwise, mul, div)
module alu_8bit (
    input  signed [7:0] a, b,
    input  [2:0]       alu_op,
    input              cin,    
  	// cin only used for cascaded add/sub; tie low for standalone
  	input clk,
    output reg signed [15:0] result,
    output reg             cout
);
    // 8-bit results for add/sub and logic
    wire [7:0] add_sub_res, and_res, or_res, xor_res;
    wire       flag_sub = (alu_op == 3'b001);
    wire [7:0] b_in = flag_sub ? ~b : b;
    wire [7:0] c_out;

    // Full ripple adder/subtractor
    full_adder fa0(.a(a[0]), .b(b_in[0]), .cin(flag_sub ? 1'b1 : cin), .sum(add_sub_res[0]), .cout(c_out[0]));
    full_adder fa1(.a(a[1]), .b(b_in[1]), .cin(c_out[0]),      .sum(add_sub_res[1]), .cout(c_out[1]));
    full_adder fa2(.a(a[2]), .b(b_in[2]), .cin(c_out[1]),      .sum(add_sub_res[2]), .cout(c_out[2]));
    full_adder fa3(.a(a[3]), .b(b_in[3]), .cin(c_out[2]),      .sum(add_sub_res[3]), .cout(c_out[3]));
    full_adder fa4(.a(a[4]), .b(b_in[4]), .cin(c_out[3]),      .sum(add_sub_res[4]), .cout(c_out[4]));
    full_adder fa5(.a(a[5]), .b(b_in[5]), .cin(c_out[4]),      .sum(add_sub_res[5]), .cout(c_out[5]));
    full_adder fa6(.a(a[6]), .b(b_in[6]), .cin(c_out[5]),      .sum(add_sub_res[6]), .cout(c_out[6]));
    full_adder fa7(.a(a[7]), .b(b_in[7]), .cin(c_out[6]),      .sum(add_sub_res[7]), .cout(c_out[7]));

    assign and_res = a & b;
    assign or_res  = a | b;
    assign xor_res = a ^ b;

    // wider extensions for outputs
    wire signed [15:0] ext_add  = {{8{add_sub_res[7]}}, add_sub_res};
    wire signed [15:0] ext_and  = {8'b0, and_res};
    wire signed [15:0] ext_or   = {8'b0, or_res};
    wire signed [15:0] ext_xor  = {8'b0, xor_res};

    // Multiply and divide units
    wire signed [15:0] mul_res;
    wire signed [7:0]  div_res, div_rem;
    booth_multiplier mul(.a(a), .b(b), .result(mul_res));
    signed_divider   div(.a(a), .b(b), .result(div_res), .rem(div_rem));

  	
  	reg signed [15:0] comb_res;
    reg               comb_cout;
    always @* begin
      	comb_cout = 0;
        case (alu_op)
            3'b000: begin comb_res = ext_add; comb_cout = c_out[7]; end  // add
            3'b001: begin comb_res = ext_add; comb_cout = c_out[7]; end  // sub
            3'b010: begin comb_res = ext_and; comb_cout = 1'b0; end
            3'b011: begin comb_res = ext_or;  comb_cout = 1'b0; end
            3'b100: begin comb_res = ext_xor; comb_cout = 1'b0; end
            3'b101: begin comb_res = mul_res; comb_cout = 1'b0; end
            3'b110: begin comb_res = {{8{div_res[7]}}, div_res}; comb_cout = 1'b0; end
            default: begin comb_res = 16'b0; comb_cout = 1'b0; end
        endcase
    end
  
  	always @* begin
        result <= comb_res;
        cout   <= comb_cout;
    end
  
endmodule
