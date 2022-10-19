// sort.s
// Main sort function template
// Alexa Wright, Modified from jbrake@hmc.edu
// 9/26/22

// Directives 
.syntax unified // Specify the syntax for the file
.cpu cortex-m4  // Target CPU is Cortex-M4
.fpu softvfp    // Use software libraries for floating-point operations
.thumb          // Instructions should be encoded as Thumb instructions

// Define main globally for other files to call
.global main

// Create test array of bytes. Change this for different test cases.
// This will get loaded to the RAM by the startup code
.data
arr:
  .byte 10, 10, 11, 11, 10, 0, 0, 64, 64, 127, -128, -128
.size arr, .-arr



//-128, -128, 127, 127, 64, 64, 0, 0, 10, 11, 11, 10
//1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
//-12, 81, 124, 8,-100, -37, -46, -80,  10, -70, -48,  17
//12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
//21, -66, 30, 105, 29, -96, -5, 41, 13,-60, 33, 102
.text


// The main function
.type main, %function
main:
  ldr r3, =arr // Load the base address of RAM where the array is stored
 
 
  MOV r4, #0  //r4: outer loop counter (i)
  MOV r5, #0  //r5: inner loop counter (j)
outerLoop:
  MOV r5, #0      //r5: inner loop counter (j)
  CMP r4, #11     //i (r4) <11
  BGE done        //go to end if done
  B innerLoop     //go to innerLoop
outerLoopEnd:     //after done with inner loop
  ADD r4, r4, #1  //increment counter
  B outerLoop     //go back to outer loop
innerLoop:
  MVN r6, r4        //Take 1s complement of r4 and put it in r6
  ADD r6, r6, #1    //add 1 to r6
  ADD r6, r6, #11   //set r6 to be the maximum of the inner loop
  CMP r5, r6        //j (r5)<11-i(r4)
  BGE outerLoopEnd  //go to outerLoop, outerLoopEnd
  //do swap stuff
  LDRSB r7, [r3, r5]    //put array[j] into r7
  ADD r2, r5, #1    //compute j+1, put it in r2
  LDRSB r8, [r3, r2]    //put array[j+1] into r8
  CMP r8, r7        //array[j](r7) > array[j+1](r8)
  BGE innerLoopEnd  //go to end if array[j]<array[j+1]
  //MOV r9, r7      //put array[j](r7) into r9
  STRB r8, [r3, r5]    //put array[j+1](r8) into array[j]
  STRB r7, [r3, r2]    //put array[j](r7) into array[j+1]
innerLoopEnd:
  ADD r5, r5, #1    //j(r5)++
  B innerLoop       //back to top
done:
 B outerLoop
  
  
.size main, .-main