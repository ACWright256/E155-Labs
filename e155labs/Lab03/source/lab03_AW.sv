/**
Alexa Wright
acwright@hmc.edu
9/19/22
SystemVerilog code for a keypad decoder
*/


//Top module
module top (
	input logic[3:0] row_top,
	output logic[3:0] col_top,
	output logic[6:0] seg_top,
	output logic[1:0] anode_top
	);
	logic reset;
	logic clk;
	logic int_osc;

	assign reset=0;
	//clock signal
	
	// Internal high-speed oscillator
	HSOSC #(.CLKHF_DIV(2'b11))
	hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));	
	
	
	Incrementer #(.WIDTH(15), .INCREMENT(1)) clkDivide(int_osc, clk);
	//The lab module
	MicroPsLab03 microPsLab03(clk, reset, row_top, col_top, seg_top, anode_top );
endmodule


//Micro Ps Lab
module MicroPsLab03(
	input logic clk, reset,
	input logic[3:0] row,
	output logic[3:0] col,
	output logic[6:0] seg,
	output logic[1:0] anode
	);
	
	
	logic[3:0] outRow;
	logic digEn;
	
	logic[3:0] currentDig;
	logic[3:0] digL;
	logic[3:0] digR;
	
	
	
	
	logic bounceOverflow;
	logic fsmInc;
	
	logic bounceCountReset;
	
	
	//assign row = ~notRow;
	
	//Incrementer for fsm
	
	BounceAdder #(.WIDTH(5)) bounceAdder(clk, bounceCountReset, fsmInc,  bounceOverflow);
	
	//Column select fsm
	ColSelectFSM colSelectFSM(clk, reset, bounceOverflow, row, col, outRow, digEn,fsmInc,bounceCountReset);
	
	

	
	
	//keypad comb logic
	KeyCL keyCL(digEn, col, outRow, currentDig);
	
	//Flop to right digit
	FlopER #(.WIDTH(4)) rightFlop(clk, reset, digEn, currentDig, digR);
	
	//Flop to left digit
	FlopER #(.WIDTH(4)) leftFlop(clk, reset, digEn, digR, digL);
	
	//Display module
	DisplayMux displayMux(clk, digR, digL, seg, anode);
	
endmodule

//Bounce Adder
module BounceAdder #(WIDTH=10)
	(
	input logic clk, reset,
	input logic increment,
	output logic bounceOverflow
	);
	logic [WIDTH-1:0] counter = 0;
	//Divides the clock by 2^WIDTH-1 and adds by INCREMENT. 
	always_ff @(posedge clk)
		begin
			if(reset) counter<=0;
			else counter <= counter + increment;
		end	
	//assigns the led to the counter
	assign bounceOverflow = counter[WIDTH-1];
endmodule


//Switches between columns 0 through 3
typedef enum logic [22:0] {	col0Check, col1Check, col2Check, col3Check, 
							col0En, col1En, col2En, col3En, 
							postRise0, postRise1, postRise2, postRise3,
							stableCol0, stableCol1, stableCol2, stableCol3,
							 fallingEdge} ColSelectFSMStateType;
//maybe row logic is wrong
module ColSelectFSM
	(
	input logic clk, reset,
	input logic bounceOverflow,
	input logic [3:0] inRow_ColumnSelectFSM,
	output logic [3:0] col_ColumnSelectFSM,
	output logic [3:0] outRow_ColumnSelectFSM,
	output logic valEnable,
	output logic increment,
	output logic counterReset
	);
	ColSelectFSMStateType CurrentState, NextState;
	//State Register
	always_ff @(posedge clk)
	begin
		if(reset) CurrentState<=col0Check;
		else CurrentState<=NextState;	
		outRow_ColumnSelectFSM<=inRow_ColumnSelectFSM;
	end
	//Next State Logic
	always_comb
		case(CurrentState)
			col0Check: 	if(inRow_ColumnSelectFSM == 4'b0000) NextState = col1Check;
							else NextState = col0En;
			col1Check: 	if(inRow_ColumnSelectFSM == 4'b0000) NextState = col2Check;
							else NextState = col1En;
			col2Check: 	if(inRow_ColumnSelectFSM == 4'b0000) NextState = col3Check;
							else NextState = col2En;
			col3Check: 	if(inRow_ColumnSelectFSM == 4'b0000) NextState = col0Check;
							else NextState = col3En;
			col0En:		NextState = postRise0;
			col1En:		NextState = postRise1;
			col2En:		NextState = postRise2;
			col3En:		NextState = postRise3;
			postRise0:
						if(bounceOverflow) NextState = stableCol0;
						else NextState = postRise0;
			postRise1:
						if(bounceOverflow) NextState = stableCol1;
						else NextState = postRise1;							
			postRise2:
						if(bounceOverflow) NextState = stableCol2;
						else NextState = postRise2;
			postRise3:
						if(bounceOverflow) NextState = stableCol3;
						else NextState = postRise3;						
			stableCol0:if(inRow_ColumnSelectFSM == 4'b0000) NextState = fallingEdge;
						else NextState = stableCol0;									
			stableCol1:if(inRow_ColumnSelectFSM == 4'b0000) NextState = fallingEdge;
						else NextState = stableCol1;	
			stableCol2:if(inRow_ColumnSelectFSM == 4'b0000) NextState = fallingEdge;
						else NextState = stableCol2;	
			stableCol3:if(inRow_ColumnSelectFSM == 4'b0000) NextState = fallingEdge;
						else NextState = stableCol3;								
			
			fallingEdge:if(bounceOverflow) NextState = col0Check;
						else NextState = fallingEdge;
			default: NextState = col0Check;
		endcase
		
		//TWO DIFFERENT COLUMN OUTputs
	//Output Logic
	assign counterReset = (	CurrentState == col0En || 
							CurrentState == col1En || 
							CurrentState == col2En || 
							CurrentState == col3En || 
							CurrentState == stableCol0||
							CurrentState == stableCol1||
							CurrentState == stableCol2||
							CurrentState == stableCol3);
	//Column output states
	assign col_ColumnSelectFSM[0] = (	CurrentState == col0En 		|| 
										CurrentState == postRise0 		|| 
										CurrentState == stableCol0 		|| 
										CurrentState == col0Check);
	assign col_ColumnSelectFSM[1] = (	CurrentState == col1En 		|| 
										CurrentState == postRise1 		|| 
										CurrentState == stableCol1 		|| 
										CurrentState == col1Check);
	assign col_ColumnSelectFSM[2] = (	CurrentState == col2En 		|| 
										CurrentState == postRise2 		|| 
										CurrentState == stableCol2 		|| 
										CurrentState == col2Check);
	assign col_ColumnSelectFSM[3] = (	CurrentState == col3En 		|| 
										CurrentState == postRise3 		|| 
										CurrentState == stableCol3 		|| 
										CurrentState == col3Check);
	assign valEnable = (CurrentState == col0En || 
						CurrentState == col1En || 
						CurrentState == col2En || 
						CurrentState == col3En );
	assign increment = (CurrentState==postRise0	|| 
						CurrentState==postRise1	|| 
						CurrentState==postRise2	|| 
						CurrentState==postRise3	|| 
						CurrentState==fallingEdge);
endmodule
//Combinational logic for parsing rows and columns to keys
module KeyCL (
	input logic digEn,
	input logic [3:0] col,
	input logic [3:0] row,
	output logic [3:0] digit
	);
	//Digit logic
	always_comb
	begin
		if		(digEn & col[0] & row[0]) digit <= 4'b0001;
		else if	(digEn & col[1] & row[1]) digit <= 4'b0101;
		else if	(digEn & col[2] & row[2]) digit <= 4'b1001;
		else if	(digEn & col[3] & row[3]) digit <= 4'b1101;
			
		else if	(digEn & col[0] & row[1]) digit <= 4'b0100;
		else if	(digEn & col[0] & row[2]) digit <= 4'b0111;
		else if	(digEn & col[0] & row[3]) digit <= 4'b1110;
		
		else if	(digEn & col[1] & row[0]) digit <= 4'b0010;
		else if	(digEn & col[1] & row[2]) digit <= 4'b1000;
		else if	(digEn & col[1] & row[3]) digit <= 4'b0000;
			
		else if	(digEn & col[2] & row[0]) digit <= 4'b0011;
		else if	(digEn & col[2] & row[1]) digit <= 4'b0110;
		else if	(digEn & col[2] & row[3]) digit <= 4'b1111;
		
		else if	(digEn & col[3] & row[0]) digit <= 4'b1010;
		else if	(digEn & col[3] & row[1]) digit <= 4'b1011;	
		else if	(digEn & col[3] & row[2]) digit <= 4'b1100;

		else	digit <= 4'b0000;
	end
	
endmodule

//enable flip flop
module FlopER #(WIDTH=2)(
	input logic clk, reset, enable,
	input logic[WIDTH-1:0] d,
	output logic[WIDTH-1:0] q
	);
	always_ff @(posedge clk)
	begin
		if(reset) q<= 0;
		else if (enable) q<=d;
	end
endmodule

//////////// DISPLAY MULTIPLEXING MODULE ////////////
//Module from last lab puts two digit numbers to a display
module DisplayMux (
	input logic clk,
	input logic [3:0] s1,
	input logic [3:0] s2,
	output logic [6:0] seg,
	output logic [1:0] anode
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
	Incrementer #(.WIDTH(1), .INCREMENT(1))switchingSpeed(clk, sClk);
	//The anode select module 
	AnodeSelect anodeSelect(sClk, anode);
	//The switching mux
	assign switchMux =  sClk ? s1prime:s2prime; 
	//The display logic module
	DisplayLogic displayLogic (switchMux, seg);
endmodule
//synchronizer module
module Synchronizer #(WIDTH=2)
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

module Incrementer #(WIDTH=26, INCREMENT=783)
//module Incrementer #(WIDTH=2, INCREMENT=1)
	(
	input logic clk_SwitchingSpeed,
	output logic sClk_SwitchingSpeed
	);
	logic [WIDTH-1:0] counter = 0;
	//Divides the clock by 2^WIDTH-1 and adds by INCREMENT. 
	always_ff @(posedge clk_SwitchingSpeed)
		begin
			counter <= counter + INCREMENT;
		end	
	//assigns the led to the counter
	assign sClk_SwitchingSpeed = counter[WIDTH-1];
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
//////////// END DISPLAY MULTIPLEXING MODULE ////////////

//Testbench
module testbench #(parameter VECTORSIZE=8);
logic clk;
logic reset;	
logic[3:0] row;
logic[3:0] col;
logic [6:0] seg;
logic [1:0] anode;
logic[31:0] vectornum;

logic [VECTORSIZE-1:0] testvectors [1000:0];


assign reset=0;

MicroPsLab03 microPsLab03(clk, reset, row, col, seg, anode);

//Clock signal
always begin
	clk = 1; #1; clk = 0; #1;
end
//Initialize test vectors
initial begin 
		$readmemb("Lab03_AW.tv",testvectors);
		vectornum = 0;
		
		//{row} = testvectors[vectornum];
		//vectornum = vectornum +	1;
end
//Load the test vectors and increment the count
always @(posedge clk) begin	
	row = 4'b1111;
	#8;
	{row} = testvectors[vectornum];
	#8
	row = 4'b1111;
	#8
	{row} = testvectors[vectornum];
	#8
	row = 4'b1111;
	#8
	{row} = testvectors[vectornum];
	#128;
	row = 4'b1111;
	#8
	{row} = testvectors[vectornum];
	#8
	row = 4'b1111;
	#128
	
	vectornum = vectornum +	1;
	end
endmodule

