/*
Alexa Wright - modified from Josh Brake
acwright@hmc.edu, jbrake@hmc.edu
10/24/22
*/
/////////////////////////////////////////////
// aes
//   Top level module with SPI interface and SPI core
/////////////////////////////////////////////


module aes_top(input logic sck,
			   input logic sdi,
			   output logic sdo,
			   input logic load,
			   output logic done);
	logic clk;
	logic int_osc;
	// Internal high-speed oscillator
	HSOSC #(.CLKHF_DIV(2'b11))
	hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));	
	aes AES(int_osc, sck, sdi, sdo, load, done);
endmodule


module aes(input  logic clk,
           input  logic sck, 
           input  logic sdi,
           output logic sdo,
           input  logic load,
           output logic done);
                    
    logic [127:0] key, plaintext, cyphertext;
            
    aes_spi spi(sck, sdi, sdo, done, key, plaintext, cyphertext);   
    aes_core core(clk, load, key, plaintext, done, cyphertext);
endmodule

/////////////////////////////////////////////
// aes_spi
//   SPI interface.  Shifts in key and plaintext
//   Captures ciphertext when done, then shifts it out
//   Tricky cases to properly change sdo on negedge clk
/////////////////////////////////////////////

module aes_spi(input  logic sck, 
               input  logic sdi,
               output logic sdo,
               input  logic done,
               output logic [127:0] key, plaintext,
               input  logic [127:0] cyphertext);

    logic         sdodelayed, wasdone;
    logic [127:0] cyphertextcaptured;
               
    // assert load
    // apply 256 sclks to shift in key and plaintext, starting with plaintext[127]
    // then deassert load, wait until done
    // then apply 128 sclks to shift out cyphertext, starting with cyphertext[127]
    // SPI mode is equivalent to cpol = 0, cpha = 0 since data is sampled on first edge and the first
    // edge is a rising edge (clock going from low in the idle state to high).
    always_ff @(posedge sck)
        if (!wasdone)  {cyphertextcaptured, plaintext, key} = {cyphertext, plaintext[126:0], key, sdi};
        else           {cyphertextcaptured, plaintext, key} = {cyphertextcaptured[126:0], plaintext, key, sdi}; 
    
    // sdo should change on the negative edge of sck
    always_ff @(negedge sck) begin
        wasdone = done;
        sdodelayed = cyphertextcaptured[126];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? cyphertext[127] : sdodelayed;
endmodule

/////////////////////////////////////////////
// aes_core
//   top level AES encryption module
//   when load is asserted, takes the current key and plaintext
//   generates cyphertext and asserts done when complete 11 cycles later
// 
//   See FIPS-197 with Nk = 4, Nb = 4, Nr = 10
//
//   The key and message are 128-bit values packed into an array of 16 bytes as
//   shown below
//        [127:120] [95:88] [63:56] [31:24]     S0,0    S0,1    S0,2    S0,3
//        [119:112] [87:80] [55:48] [23:16]     S1,0    S1,1    S1,2    S1,3
//        [111:104] [79:72] [47:40] [15:8]      S2,0    S2,1    S2,2    S2,3
//        [103:96]  [71:64] [39:32] [7:0]       S3,0    S3,1    S3,2    S3,3
//
//   Equivalently, the values are packed into four words as given
//        [127:96]  [95:64] [63:32] [31:0]      w[0]    w[1]    w[2]    w[3]
/////////////////////////////////////////////

typedef enum logic [12:0] {resetstate, round0, round1, round2, round3, round4, round5, round6, round7, round8, round9, round10, doneround} roundState;

module aes_core(input  logic         clk, 
                input  logic         load,
                input  logic [127:0] key, 
                input  logic [127:0] plaintext, 
                output logic         done, 
                output logic [127:0] cyphertext);
	logic reset;
	assign reset = 0;
	//logic [127:0] outstate;
	logic halfclk = 0;
	always_ff @(posedge clk)
	begin
		halfclk<=halfclk +1;
	end

	aes_FSM FSM(clk,halfclk, load,key, plaintext, cyphertext, done );    
endmodule

//--------------------------------------------------------------------//
//	Finite state machine for main control of AES
//--------------------------------------------------------------------//
module aes_FSM  (input logic clk, halfclk,load,
				 input  logic [127:0] key,
				 input logic  [127:0] instate,
				 output logic [127:0] out,
				 output logic done);
	roundState CurrentState, NextState;
	//TODO: USE LOAD AS RESET?
	logic [127:0] state;		//has either the initial load state, or the output of the fsm
	logic [127:0] outstateflop;	//has either the initial load state, or the output of the fsm
	logic [127:0] outstate;
	
	
	logic [127:0] inkey;		//the key being input into generate keyschedule (mux output)
	logic [127:0] flopkey;		//the key on the flip flop (into the mux)
	logic [127:0] outkey;		//the key output from genkeyschedule

	logic [7:0] inrcon[3:0];		//the rcon value being input into rcon (mux output)
	logic [7:0] floprcon[3:0];		//the rcon value  on the flip flop (into the mux)
	logic [7:0] outrcon[3:0];		//the rcon value output from rcon

	logic [7:0] rconinit[3:0];		//initial rcon value stored in logic gates

	logic [127:0] outsubbytes;		//output of subbytes module
	logic [127:0] outshiftrows;		//output of shiftrows module
	logic [127:0] outmixcols;		//output of the mixcols module
	
	logic [127:0] outsrcsel;	//output of the source select mux
	
	logic finflop;
	
		//current rcon register
	always_ff @(posedge halfclk)
	begin
		floprcon<=outrcon;
	end	
	always_ff@(posedge halfclk)
	begin
		if(CurrentState==round10) out <= outstateflop;
	end
	//current key register
	always_ff @(posedge halfclk)
	begin
		flopkey<=outkey;
	end	
	
	//output state
	always_ff @(posedge halfclk)
	begin
		if(finflop)outstate<=outstateflop;
	end	
	//state register
	always_ff @(posedge halfclk)				
	begin		
		if(load) begin
			CurrentState<=resetstate; 		
			end
		else begin 
			CurrentState<=NextState;
			end
	end	
	//Next State Logic
	always_comb
	case(CurrentState)
		resetstate: NextState=round0;
		round0: 	NextState = round1;
		round1: 	NextState = round2;
		round2: 	NextState = round3;
		round3:	 	NextState = round4;
		round4: 	NextState = round5;
		round5: 	NextState = round6;
		round6: 	NextState = round7;
		round7: 	NextState = round8;
		round8: 	NextState = round9;
		round9:		NextState = round10;
		round10: 	NextState = doneround;
		doneround: 	NextState = doneround;
		default: 	NextState = resetstate;
	endcase
	
	assign rconinit[0] = 8'h00;	//assign the initial rcon piecewise
	assign rconinit[1] = 8'h00;
	assign rconinit[2] = 8'h00;
	assign rconinit[3] = 8'h01;
	
	assign done = (CurrentState==doneround);	//assert done when currentstate is doneround
	assign inkey = (CurrentState==round0)? key: flopkey;		//mux the current round key to either input port or key on the flop
	assign inrcon = (CurrentState==round0)? rconinit : floprcon;
	assign state = 	(load)? instate: outstate;	//mux the output to the input

	
	
	assign finflop = (CurrentState!=doneround);	//disable the flop from updating if the current state is the final state
	
	
	
	gen_key_schedule keySchedule(inrcon, inkey, clk, outkey);	//generate the key schedule
	sub_bytes subBytes(state, clk, outsubbytes);		//subBytes() for rounds 1-9
	shift_rows shiftRows(outsubbytes, outshiftrows);	//shiftRows() for rounds 1-9
	mixcolumns mixCols (outshiftrows, outmixcols);		//mixCols() for rounds 1-9
	
	always_comb					
	begin				//mux the output from the sources depending on the state
		if(CurrentState == round0) outsrcsel <= instate;			
		else if(CurrentState == round10)  outsrcsel <= outshiftrows;
		else  outsrcsel <= outmixcols;
	end
	
	add_round_key addRK(outsrcsel, inkey, outstateflop);	//addRoundKey() for rounds 1-9
	 
	rcon Rcon(inrcon, outrcon);	//calculate rcon
	 

endmodule

//--------------------------------------------------------------------//
//	Performs ShiftRows from the document
//--------------------------------------------------------------------//
module shift_rows(input  logic [127:0] in_state,
				  output logic [127:0] out_state);				  
	logic [7:0] state_bytes	[3:0][3:0];
	logic [7:0] shifted_state_bytes	[3:0][3:0];
	array_to_mat arrayConverter(in_state, state_bytes); 	//Fill state_bytes with data from in_state
	//Do bit stuff
	assign shifted_state_bytes[0][0] = state_bytes[0][0];
	assign shifted_state_bytes[0][1] = state_bytes[0][1];
	assign shifted_state_bytes[0][2] = state_bytes[0][2];
	assign shifted_state_bytes[0][3] = state_bytes[0][3];
	assign shifted_state_bytes[1][0] = state_bytes[1][1];
	assign shifted_state_bytes[1][1] = state_bytes[1][2];
	assign shifted_state_bytes[1][2] = state_bytes[1][3];
	assign shifted_state_bytes[1][3] = state_bytes[1][0];
	assign shifted_state_bytes[2][0] = state_bytes[2][2];
	assign shifted_state_bytes[2][1] = state_bytes[2][3];
	assign shifted_state_bytes[2][2] = state_bytes[2][0];
	assign shifted_state_bytes[2][3] = state_bytes[2][1];
	assign shifted_state_bytes[3][0] = state_bytes[3][3];
	assign shifted_state_bytes[3][1] = state_bytes[3][0];
	assign shifted_state_bytes[3][2] = state_bytes[3][1];
	assign shifted_state_bytes[3][3] = state_bytes[3][2];
	mat_to_array matrixConverter(shifted_state_bytes, out_state);	//convert back to an array
	
	
//--------------------------------------------------------------------//
//	Convert a bit array to byte matrix 
//--------------------------------------------------------------------//
endmodule
module array_to_mat (input logic [127:0] in_wires,
					 output logic [7:0] out_wires[3:0][3:0]);
	//I know it looks ugly, but I only got 4 hours of sleep
	assign out_wires[0][0] = in_wires[127:120];
	assign out_wires[1][0] = in_wires[119:112];
	assign out_wires[2][0] = in_wires[111:104];
	assign out_wires[3][0] = in_wires[103:96];
	assign out_wires[0][1] = in_wires[95:88];
	assign out_wires[1][1] = in_wires[87:80];
	assign out_wires[2][1] = in_wires[79:72];
	assign out_wires[3][1] = in_wires[71:64];
	assign out_wires[0][2] = in_wires[63:56];
	assign out_wires[1][2] = in_wires[55:48];
	assign out_wires[2][2] = in_wires[47:40];
	assign out_wires[3][2] = in_wires[39:32];
	assign out_wires[0][3] = in_wires[31:24];
	assign out_wires[1][3] = in_wires[23:16];
	assign out_wires[2][3] = in_wires[15:8];
	assign out_wires[3][3] = in_wires[7:0];
endmodule
//--------------------------------------------------------------------//
//	Convert a byte matrix to bit array 
//--------------------------------------------------------------------//
module mat_to_array(input logic [7:0] in_wires[3:0][3:0],
					output logic [127:0] out_wires);
					
	//I know it looks ugly, but I only got 4 hours of sleep
	assign out_wires[127:120]=	in_wires[0][0];
	assign out_wires[119:112]= 	in_wires[1][0];
	assign out_wires[111:104]= 	in_wires[2][0];
	assign out_wires[103:96]= 	in_wires[3][0];
	assign out_wires[95:88]= 	in_wires[0][1];
	assign out_wires[87:80]= 	in_wires[1][1];
	assign out_wires[79:72]= 	in_wires[2][1];
	assign out_wires[71:64]= 	in_wires[3][1];
	assign out_wires[63:56]= 	in_wires[0][2];
	assign out_wires[55:48]= 	in_wires[1][2];
	assign out_wires[47:40]= 	in_wires[2][2];
	assign out_wires[39:32]= 	in_wires[3][2];
	assign out_wires[31:24]= 	in_wires[0][3];
	assign out_wires[23:16]= 	in_wires[1][3];
	assign out_wires[15:8]= 	in_wires[2][3];
	assign out_wires[7:0]= 		in_wires[3][3];
	
endmodule

//--------------------------------------------------------------------//
//	Does addition by xoring the round key(w) with the input state
//--------------------------------------------------------------------//
module add_round_key(input logic [127:0] state_in,
					 input logic [127:0] w,
					 output logic [127:0] state_out);
	assign state_out = state_in^w;	//hehe, see! my weird design choices are sometimes (maybe) for a reason
endmodule

//--------------------------------------------------------------------//
//	Rotate the bytes in the word (should synthesize to wires)
//--------------------------------------------------------------------//
module rot_word(input logic[7:0] in_word [3:0],
				output logic [7:0] out_word[3:0]);
	assign out_word[0] = in_word[1];
	assign out_word[1] = in_word[2];
	assign out_word[2] = in_word[3];
	assign out_word[3] = in_word[0];
endmodule

//--------------------------------------------------------------------//
//	Calculates Rcon (for key schedule)
//--------------------------------------------------------------------//
//TODO: figure out counter dimensions
module rcon (input logic [7:0] prevrcon [3:0],
			 output logic [7:0] out_word [3:0] );
	assign out_word[0] = 0;
	assign out_word[1] = 0;
	assign out_word[2] = 0;
	galoismult gMult(prevrcon[3], out_word[3]);
endmodule

//--------------------------------------------------------------------//
//	Performs a key expansion calculation for an iterator (i)
//	that is a multiple of 4 (beginning of each round)
//--------------------------------------------------------------------//
module mod4_ks_stage (input logic [7:0] prevrcon[3:0],
					 input logic [127:0] w_in,
					 input logic clk,
					 output logic [127:0] w_out);
	logic [7:0] w_in_mat [3:0][3:0];
	logic [7:0] w_in_col3 [3:0];
	logic [7:0] w_out_mat [3:0][3:0];	
	
	logic [7:0] out_rotw [3:0];	//output of rot_word block
	logic [7:0] out_subw [3:0]; //output of sbox_sync block
	logic [7:0] out_xor1 [3:0]; //output of the first xor gate
	logic [7:0] out_xor2 [3:0]; //output of the last xor gate
	array_to_mat arrayConverter(w_in, w_in_mat);	//convert input to matrix
	
	//assign the columns nicely
	assign w_in_col3[0] = w_in_mat[0][3];
	assign w_in_col3[1] = w_in_mat[1][3];
	assign w_in_col3[2] = w_in_mat[2][3];
	assign w_in_col3[3] = w_in_mat[3][3];
	
	//rotate work and sub word
	rot_word rotWordBlock(w_in_col3, out_rotw);
	sub_word subWordBlock(out_rotw, clk, out_subw);

	//do the first xor
	assign out_xor1[0] = prevrcon[3]^out_subw[0];
	assign out_xor1[1] = prevrcon[1]^out_subw[1];
	assign out_xor1[2] = prevrcon[2]^out_subw[2];
	assign out_xor1[3] = prevrcon[0]^out_subw[3];
	//i cannot remember the byte order to save my life. This just works man...

	//do the second xor
	assign out_xor2[0] = w_in_mat[0][0]^out_xor1[0];
	assign out_xor2[1] = w_in_mat[1][0]^out_xor1[1];
	assign out_xor2[2] = w_in_mat[2][0]^out_xor1[2];
	assign out_xor2[3] = w_in_mat[3][0]^out_xor1[3];
	//do an ungodly amount of assignments
	assign w_out_mat[0][0] = w_in_mat[0][1];
	assign w_out_mat[1][0] = w_in_mat[1][1];
	assign w_out_mat[2][0] = w_in_mat[2][1];
	assign w_out_mat[3][0] = w_in_mat[3][1];
	assign w_out_mat[0][1] = w_in_mat[0][2];
	assign w_out_mat[1][1] = w_in_mat[1][2];
	assign w_out_mat[2][1] = w_in_mat[2][2];
	assign w_out_mat[3][1] = w_in_mat[3][2];
	assign w_out_mat[0][2] = w_in_mat[0][3];
	assign w_out_mat[1][2] = w_in_mat[1][3];
	assign w_out_mat[2][2] = w_in_mat[2][3];
	assign w_out_mat[3][2] = w_in_mat[3][3];
	//set the last column to the second xor
	assign w_out_mat[0][3] = out_xor2[0];
	assign w_out_mat[1][3] = out_xor2[1];
	assign w_out_mat[2][3] = out_xor2[2];
	assign w_out_mat[3][3] = out_xor2[3];
	mat_to_array matrixConverter(w_out_mat, w_out);	//convert back to array
endmodule


//--------------------------------------------------------------------//
//	Performs a key expansion calculation for an iterator (i)
//	that is not a multiple of 4
//--------------------------------------------------------------------//
module normal_ks_stage(input logic [127:0] w_in,
					   output logic [127:0] w_out);
	logic [7:0] w_in_mat [3:0][3:0];
	logic [7:0] w_out_mat [3:0][3:0];
	logic [7:0] out_xor [3:0];
	array_to_mat arrayConverter(w_in, w_in_mat);	//convert input to matrix
	//lots of xors
	assign out_xor [0] = w_in_mat[0][0] ^ w_in_mat[0][3];
	assign out_xor [1] = w_in_mat[1][0] ^ w_in_mat[1][3];
	assign out_xor [2] = w_in_mat[2][0] ^ w_in_mat[2][3];
	assign out_xor [3] = w_in_mat[3][0] ^ w_in_mat[3][3];
	//more assignments
	assign w_out_mat[0][0] = w_in_mat[0][1];
	assign w_out_mat[1][0] = w_in_mat[1][1];
	assign w_out_mat[2][0] = w_in_mat[2][1];
	assign w_out_mat[3][0] = w_in_mat[3][1];
	assign w_out_mat[0][1] = w_in_mat[0][2];
	assign w_out_mat[1][1] = w_in_mat[1][2];
	assign w_out_mat[2][1] = w_in_mat[2][2];
	assign w_out_mat[3][1] = w_in_mat[3][2];
	assign w_out_mat[0][2] = w_in_mat[0][3];
	assign w_out_mat[1][2] = w_in_mat[1][3];
	assign w_out_mat[2][2] = w_in_mat[2][3];
	assign w_out_mat[3][2] = w_in_mat[3][3];
	assign w_out_mat[0][3] = out_xor[0];
	assign w_out_mat[1][3] = out_xor[1];
	assign w_out_mat[2][3] = out_xor[2];
	assign w_out_mat[3][3] = out_xor[3];
	mat_to_array matrixConverter(w_out_mat, w_out);	//convert back to array
endmodule

//--------------------------------------------------------------------//
//	Generates the Key schedule for a given round number
//--------------------------------------------------------------------//
module gen_key_schedule (input logic [7:0] prevrcon[3:0],
						 input logic [127:0] w_in,
						 input logic clk,
						 output logic [127:0] w_out);
	logic [127:0] stage1;
	logic [127:0] stage2;
	logic [127:0] stage3;
	mod4_ks_stage mod4Stage(prevrcon, w_in, clk, stage1);
	normal_ks_stage normalStage1(stage1, stage2);
	normal_ks_stage normalStage2(stage2, stage3);
	normal_ks_stage normalStage3(stage3, w_out);
	
endmodule


//--------------------------------------------------------------------//
//	Performs Sbox (sub 1 byte) on all word bytes
//--------------------------------------------------------------------//
module sub_word(input logic [7:0] in_word[3:0],
				input logic clk,
				output logic [7:0] out_word[3:0]);
	sbox_sync sbox1 (in_word[0], clk, out_word[0]);
	sbox_sync sbox2 (in_word[1], clk, out_word[1]);
	sbox_sync sbox3 (in_word[2], clk, out_word[2]);
	sbox_sync sbox4 (in_word[3], clk, out_word[3]);
endmodule


//--------------------------------------------------------------------//
//	Performs Sbox (sub 1 byte) on all state vectors
//--------------------------------------------------------------------//
module sub_bytes(input logic [127:0] in_state,
				 input logic clk,
				 output logic [127:0] out_state);
	logic [7:0] in_state_mat [3:0][3:0];
	logic [7:0] out_state_mat [3:0][3:0];
	array_to_mat arrayConverter(in_state, in_state_mat);	//convert input bits to matrix
	//have the synchronous sboxes run in parallel
	sbox_sync sbox1 (in_state_mat[0][0], clk, out_state_mat[0][0]);
	sbox_sync sbox2 (in_state_mat[0][1], clk, out_state_mat[0][1]);
	sbox_sync sbox3 (in_state_mat[0][2], clk, out_state_mat[0][2]);
	sbox_sync sbox4 (in_state_mat[0][3], clk, out_state_mat[0][3]);
	
	sbox_sync sbox5 (in_state_mat[1][0], clk, out_state_mat[1][0]);
	sbox_sync sbox6 (in_state_mat[1][1], clk, out_state_mat[1][1]);
	sbox_sync sbox7 (in_state_mat[1][2], clk, out_state_mat[1][2]);
	sbox_sync sbox8 (in_state_mat[1][3], clk, out_state_mat[1][3]);
	
	sbox_sync sbox9 (in_state_mat[2][0], clk, out_state_mat[2][0]);
	sbox_sync sbox10 (in_state_mat[2][1], clk, out_state_mat[2][1]);
	sbox_sync sbox11 (in_state_mat[2][2], clk, out_state_mat[2][2]);
	sbox_sync sbox12 (in_state_mat[2][3], clk, out_state_mat[2][3]);
	
	sbox_sync sbox13 (in_state_mat[3][0], clk, out_state_mat[3][0]);
	sbox_sync sbox14 (in_state_mat[3][1], clk, out_state_mat[3][1]);
	sbox_sync sbox15 (in_state_mat[3][2], clk, out_state_mat[3][2]);
	sbox_sync sbox16 (in_state_mat[3][3], clk, out_state_mat[3][3]);
	
	mat_to_array matrixConverter(out_state_mat, out_state);				//convert matrix to output bits
endmodule



/////////////////////////////////////////////
// sbox
//   Infamous AES byte substitutions with magic numbers
//   Combinational version which is mapped to LUTs (logic cells)
//   Section 5.1.1, Figure 7
/////////////////////////////////////////////
/*
module sbox(input  logic [7:0] a,
            output logic [7:0] y);
            
  // sbox implemented as a ROM
  // This module is combinational and will be inferred using LUTs (logic cells)
  logic [7:0] sbox[0:255];

  initial   $readmemh("sbox.txt", sbox);
  assign y = sbox[a];
endmodule
*/
/////////////////////////////////////////////
// sbox
//   Infamous AES byte substitutions with magic numbers
//   Synchronous version which is mapped to embedded block RAMs (EBR)
//   Section 5.1.1, Figure 7
/////////////////////////////////////////////
module sbox_sync(
	input		logic [7:0] a,
	input	 	logic 			clk,
	output 	logic [7:0] y);
            
  // sbox implemented as a ROM
  // This module is synchronous and will be inferred using BRAMs (Block RAMs)
  logic [7:0] sbox [0:255];

  initial   $readmemh("sbox.txt", sbox);
	
	// Synchronous version
	always_ff @(posedge clk) begin
		y <= sbox[a];
	end
endmodule

/////////////////////////////////////////////
// mixcolumns
//   Even funkier action on columns
//   Section 5.1.3, Figure 9
//   Same operation performed on each of four columns
/////////////////////////////////////////////

module mixcolumns(input  logic [127:0] a,
                  output logic [127:0] y);

  mixcolumn mc0(a[127:96], y[127:96]);
  mixcolumn mc1(a[95:64],  y[95:64]);
  mixcolumn mc2(a[63:32],  y[63:32]);
  mixcolumn mc3(a[31:0],   y[31:0]);
endmodule

/////////////////////////////////////////////
// mixcolumn
//   Perform Galois field operations on bytes in a column
//   See EQ(4) from E. Ahmed et al, Lightweight Mix Columns Implementation for AES, AIC09
//   for this hardware implementation
/////////////////////////////////////////////

module mixcolumn(input  logic [31:0] a,
                 output logic [31:0] y);
                      
        logic [7:0] a0, a1, a2, a3, y0, y1, y2, y3, t0, t1, t2, t3, tmp;
        
        assign {a0, a1, a2, a3} = a;
        assign tmp = a0 ^ a1 ^ a2 ^ a3;
    
        galoismult gm0(a0^a1, t0);
        galoismult gm1(a1^a2, t1);
        galoismult gm2(a2^a3, t2);
        galoismult gm3(a3^a0, t3);
        
        assign y0 = a0 ^ tmp ^ t0;
        assign y1 = a1 ^ tmp ^ t1;
        assign y2 = a2 ^ tmp ^ t2;
        assign y3 = a3 ^ tmp ^ t3;
        assign y = {y0, y1, y2, y3};    
endmodule

/////////////////////////////////////////////
// galoismult
//   Multiply by x in GF(2^8) is a left shift
//   followed by an XOR if the result overflows
//   Uses irreducible polynomial x^8+x^4+x^3+x+1 = 00011011
/////////////////////////////////////////////

module galoismult(input  logic [7:0] a,
                  output logic [7:0] y);

    logic [7:0] ashift;
    
    assign ashift = {a[6:0], 1'b0};
    assign y = a[7] ? (ashift ^ 8'b00011011) : ashift;
endmodule
