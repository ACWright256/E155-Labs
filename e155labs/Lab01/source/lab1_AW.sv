/**
Alexa Wright
acwright@hmc.edu
9/5/22
SystemVerilog code for a single 7-segment display
*/

//Top Module: Includes the internal FPGA clock and MicroPsLab01
module top(
	input 	logic [3:0] s_top,
	output 	logic [2:0] led_top,
	output 	logic [6:0] seg_top
); 
	//clock signal
	logic int_osc;
	// Internal high-speed oscillator
	HSOSC #(.CLKHF_DIV(2'b00))
	hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));	
	MicroPsLab01 microPsLab01(int_osc, s_top, led_top, seg_top);
endmodule
//MicroPsLab01: The system for lab 1
module MicroPsLab01(
	input 	logic clk,
	input 	logic [3:0] s,
	output 	logic [2:0] led,
	output 	logic [6:0] seg
	);
	logic [6:0] not_seg;
	ButtonLogic 	btnLogic(s,led[1:0]);	
	FlashLED 		flashLedLogic(clk, led[2]);
	DisplayLogic 	displayLogic(s,not_seg);
	//Inverts the 7-segment display to work with common anode configuration
	assign seg = ~not_seg;
endmodule
//FlashLED: flashes the LED at 214 * clockspeed / 2^31 hz
module FlashLED(
	input 	logic	clk_FlashLED,
	output 	logic 	led_FlashLED
	);
	logic [31:0] counter = 0;
	//Divides the clock by 2^31 and adds by 214. 
	always_ff @(posedge clk_FlashLED)
		begin
			counter <= counter + 214;
		end	
	//assigns the led to the counter
	assign led_FlashLED = counter[31];	
endmodule
//ButtonLogic: button combinational logic
module ButtonLogic (
	input 	logic [3:0] 	s_ButtonLogic,
	output 	logic [1:0]		led_ButtonLogic
	);
	//Condensed the truth tables using SOP
	assign led_ButtonLogic[0]= s_ButtonLogic[0]^ s_ButtonLogic[1];
	assign led_ButtonLogic[1]= s_ButtonLogic[2]& s_ButtonLogic[3];
endmodule
//DisplayLogic: display combinational logic
module DisplayLogic(
	input 	logic [3:0] s_DisplayLogic,
	output 	logic [6:0] seg_DisplayLogic
	);
	always_comb
		casez(s_DisplayLogic)
			//The truth table for the 7 segment display
			4'b0000: seg_DisplayLogic = 7'b0111111;
			4'b0001: seg_DisplayLogic = 7'b0000110;
			4'b0010: seg_DisplayLogic = 7'b1011011;
			4'b0011: seg_DisplayLogic = 7'b1001111;
			4'b0100: seg_DisplayLogic = 7'b1100110;
			4'b0101: seg_DisplayLogic = 7'b1101101;
			4'b0110: seg_DisplayLogic = 7'b1111101;
			4'b0111: seg_DisplayLogic = 7'b0000111;
			4'b1000: seg_DisplayLogic = 7'b1111111;
			4'b1001: seg_DisplayLogic = 7'b1100111;
			4'b1010: seg_DisplayLogic = 7'b1110111;
			4'b1011: seg_DisplayLogic = 7'b1111100;
			4'b1100: seg_DisplayLogic = 7'b0111001;	
			4'b1101: seg_DisplayLogic = 7'b1011110;
			4'b1110: seg_DisplayLogic = 7'b1111001;
			4'b1111: seg_DisplayLogic = 7'b1110001;
			default: seg_DisplayLogic = 7'b0000000;
		endcase
endmodule
