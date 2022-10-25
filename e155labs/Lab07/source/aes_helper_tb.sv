/*
Alexa Wright - modified from Josh Brake
acwright@hmc.edu, jbrake@hmc.edu
10/24/22
*/
/////////////////////////////////////////////
// add_round_key_tb
//  Module to test add_round_key module
/////////////////////////////////////////////

module add_round_key_tb();

    // Declare signals
    logic [127:0] key, plaintext, expected;
    logic [7:0] state_in_2d[3:0][3:0];
    logic [7:0] state_out_2d[3:0][3:0];
	logic [127:0] state_out;
	logic [127:0] state_in;
	logic [127:0] w;
    // Initialize inputs
    initial begin   
      // Test case from FIPS-197 Appendix A.1, B
      key       <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;
      plaintext <= 128'h3243F6A8885A308D313198A2E0370734;
      expected  <= 128'h3925841D02DC09FBDC118597196A0B32;
    end
    
    // Instantiate device under test
    add_round_key dut(.state_in(state_in), .w(w), .state_out(state_out));
    
	array_to_mat inArrayConv(state_in, state_in_2d);
	array_to_mat outArrayConv(state_out, state_out_2d);

    // Logic signal for roundkey from Appendix B
    logic [127:0] roundkey;
    assign roundkey = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
    
    // Apply signals to module and check
    initial begin 
      // Delay and then apply inputs
      #10;
      w <= key;
      state_in <= plaintext;

      // Check outputs
      #10;
      if (state_out == roundkey)
        $display("Test passed!");
      else
        $display("Test failed!");
    end

endmodule

module testclk();

	logic halfclk=0;
	logic clk;
	initial 	//generate clock
        forever begin
            clk = 1'b0; #5;
            clk = 1'b1; #5;
        end
	always_ff @(posedge clk)
	begin
		halfclk <= halfclk+1;
	end		
		
endmodule

//------------------------------------------//
// shift_rows_tb
//  Module to test shift_rows module
//------------------------------------------//

module shift_rows_tb();
    // Declare signals
    logic [127:0] expected;
	logic [7:0] expected_2d[3:0][3:0];
    logic [7:0] state_in_2d[3:0][3:0];
    logic [7:0] state_out_2d[3:0][3:0];
	logic [127:0] state_out;
	logic [127:0] state_in;
	logic [127:0] indata;
    initial begin   
      expected       <= 128'hd4e0b81ebfb441275d52119830aef1e5;
	  indata		 <= 128'hd4e0b81e27bfb44111985d52aef1e530;
    end	
	
	shift_rows dut(state_in, state_out);
    
	array_to_mat inArrayConv(state_in, state_in_2d);
	array_to_mat expectedCon(expected, expected_2d);
	array_to_mat outArrayConv(state_out, state_out_2d);

	initial begin
		#10;
		state_in<=indata;
		#10;
		if (state_out == expected)
			$display("Test passed!");
		else
			$display("Test failed!");	
	end

endmodule








//------------------------------------------//
// sub_bytes_tb
//  Module to test shift_rows module
//------------------------------------------//

module sub_bytes_tb();
	logic clk;
	logic [127:0] expected;
	logic [7:0] expected_2d[3:0][3:0];
    logic [7:0] state_in_2d[3:0][3:0];
    logic [7:0] state_out_2d[3:0][3:0];
	logic [127:0] state_out;
	logic [127:0] state_in;
	logic [127:0] indata;
	initial 	//generate clock
        forever begin
            clk = 1'b0; #5;
            clk = 1'b1; #5;
        end
	initial begin   
      expected       <= 128'hd4e0b81e27bfb44111985d52aef1e530;
	  indata		 <= 128'h19a09ae93df4c6f8e3e28d48be2b2a08;
    end	
	
	sub_bytes dut(state_in, clk, state_out);
	array_to_mat inArrayConv(state_in, state_in_2d);
	array_to_mat expectedCon(expected, expected_2d);
	array_to_mat outArrayConv(state_out, state_out_2d);
	
	initial begin
		#10;
		state_in<=indata;
		#20;
		if (state_out == expected)
			$display("Test passed!");
		else
			$display("Test failed!");	
	end
endmodule



//------------------------------------------//
// gen_key_schedule_tb
//  Module to test gen_key_schedule module
//------------------------------------------//
module gen_key_schedule_tb();
	logic [7:0] round[3:0];
	logic clk;
	logic [127:0] expected;
	logic [7:0] expected_2d[3:0][3:0];
    logic [7:0] w_in_2d[3:0][3:0];
    logic [7:0] w_out_2d[3:0][3:0];
	logic [127:0] w_out;
	logic [127:0] w_in;
	logic [127:0] indata;
	initial 	//generate clock
        forever begin
            clk = 1'b0; #5;
            clk = 1'b1; #5;
        end
	initial begin   
	  round[0] <=8'h00;
	  round[1] <=8'h00;
	  round[2] <=8'h00;
	  round[3] <=8'h01;
      expected       <= 128'ha0fafe1788542cb123a339392a6c7605;
	  indata		 <= 128'h2b7e151628aed2a6abf7158809cf4f3c;
	  
	  /*round <=1;
      expected       <= 128'hf2c295f27a96b9435935807a7359f67f;
	  indata		 <= 128'ha0fafe1788542cb123a339392a6c7605;*/
	  
	  /*round[0] <=8'h1b;
	  round[1] <=8'h00;
	  round[2] <=8'h00;
	  round[3] <=8'h00;
      expected       <= 128'hac7766f319fadc2128d12941575c006e;
	  indata		 <= 128'head27321b58dbad2312bf5607f8d292f;*/
    end			
		
	gen_key_schedule dut(round, w_in, clk, w_out);
	array_to_mat inArrayConv(w_in, w_in_2d);
	array_to_mat expectedCon(expected, expected_2d);
	array_to_mat outArrayConv(w_out, w_out_2d);
		
		
	initial begin
		#10;
		w_in<=indata;
		#20;
		if (w_out == expected)
			$display("Test passed!");
		else
			$display("Test failed!");	
	end	
endmodule



