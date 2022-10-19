/**
Alexa Wright
acwright@hmc.edu
9/12/22
SystemVerilog code for two time multiplexed 7-segment display
*/
//top module
module top (
	input logic [3:0] s1_top,
	input logic [3:0] s2_top,
	output logic [6:0] seg_top,
	output logic [1:0] anode_top,
	output logic [4:0] sum_top
	);
	//clock signal
	logic int_osc;
	// Internal high-speed oscillator
	HSOSC #(.CLKHF_DIV(2'b00))
	hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));	
	//The lab module
	MicroPsLab02 microPsLab02(int_osc, s1_top, s2_top, seg_top, anode_top, sum_top);
endmodule
//The lab module
module MicroPsLab02 (
	input logic clk,
	input logic [3:0] s1,
	input logic [3:0] s2,
	output logic [6:0] seg,
	output logic [1:0] anode,
	output logic [4:0] sum
	);
	logic[3:0] s1prime;
	logic[3:0] s2prime;
	//synchronizers for inputs
	Synchronizer #(.WIDTH(4)) sync1(clk, s1, s1prime);
	Synchronizer #(.WIDTH(4)) sync2(clk, s2, s2prime);
	//The wire(s) containing mux logic for s1 and s2
	logic[3:0] switchMux;
	//The wire containing the switching speed
	logic sClk;
	//The switching speed module
	SwitchingSpeed switchingSpeed(clk, sClk);
	//The anode select module 
	AnodeSelect anodeSelect(sClk, anode);
	//The switching mux
	assign switchMux =  sClk ? s1prime:s2prime; 
	//The display logic module
	DisplayLogic displayLogic (switchMux, seg);
	//The output sum 
	assign sum = s1prime+s2prime;
endmodule
//synchronizer module
module Synchronizer #(WIDTH=1)
			(input logic clk,
			input logic[WIDTH-1:0] d,
			output logic [WIDTH-1:0] q);
	logic[WIDTH-1:0] n1;
	always_ff @(posedge clk)
	begin
		n1<=d;
		q<=n1;	
	end
endmodule
//The module to adjust the switching speed
module SwitchingSpeed(
	input logic clk_SwitchingSpeed,
	output logic sClk_SwitchingSpeed
	);
	
	logic [28:0] counter = 0;
	//Divides the clock by 2^28 and adds by 783. 
	always_ff @(posedge clk_SwitchingSpeed)
		begin
			counter <= counter + 783;
		end	
	//assigns the led to the counter
	assign sClk_SwitchingSpeed = counter[28];
endmodule
//The module to select between common anodes
module AnodeSelect(
	input logic sClk_AnodeSelect,
	output logic [1:0] anode_AnodeSelect
	);
	assign anode_AnodeSelect[0] =  sClk_AnodeSelect;
	assign anode_AnodeSelect[1] = ~sClk_AnodeSelect;
endmodule
//DisplayLogic: display combinational logic
module DisplayLogic(
	input 	logic [3:0] s_DisplayLogic,
	output 	logic [6:0] seg_DisplayLogic
	);
	logic[6:0] not_seg;
	always_comb
		casez(s_DisplayLogic)
			//The truth table for the 7 segment display
			4'b0000: not_seg = 7'b0111111;
			4'b0001: not_seg = 7'b0000110;
			4'b0010: not_seg = 7'b1011011;
			4'b0011: not_seg = 7'b1001111;
			4'b0100: not_seg = 7'b1100110;
			4'b0101: not_seg = 7'b1101101;
			4'b0110: not_seg = 7'b1111101;
			4'b0111: not_seg = 7'b0000111;
			4'b1000: not_seg = 7'b1111111;
			4'b1001: not_seg = 7'b1100111;
			4'b1010: not_seg = 7'b1110111;
			4'b1011: not_seg = 7'b1111100;
			4'b1100: not_seg = 7'b0111001;	
			4'b1101: not_seg = 7'b1011110;
			4'b1110: not_seg = 7'b1111001;
			4'b1111: not_seg = 7'b1110001;
			default: not_seg = 7'b0000000;
		endcase
		assign seg_DisplayLogic = ~not_seg;
endmodule
/*
//Testbench
module testbench #(parameter VECTORSIZE=8);
logic clk;
logic[3:0] s1;
logic[3:0] s2;
logic [6:0] seg;
logic [1:0] anode;
logic [4:0] sum;
logic[31:0] vectornum;
logic [VECTORSIZE-1:0] testvectors [1000:0];
MicroPsLab02 microPsLab02(clk, s1, s2, seg, anode, sum);
//Clock signal
always begin
	clk = 1; #5; clk = 0; #5;
end
//Initialize test vectors
initial begin 
		$readmemb("Lab02_AW.tv",testvectors);
		vectornum = 0;
end
//Load the test vectors and increment the count
always @(posedge clk) begin
	#100;  {s1,s2} = testvectors[vectornum];
	vectornum = vectornum +	1;
	end
endmodule
*/