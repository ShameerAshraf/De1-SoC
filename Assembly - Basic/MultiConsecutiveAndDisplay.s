/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

//////////////////////////////////////////////////////////////

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV	  R8, #0
          MOV	  R5, #0		// placeholder ONES result
          MOV     R6, #0		// placeholder ZEROES result
          MOV     R7, #0		// placeholder ALTERNATE result
NEXTNUM:  MOV     R12, #TEST_NUM   // load the data word ...
		  LDR     R1, [R12, R8]        // into R1
		  LDR     R3, [R12, R8]		//into R3 for ZEROES subroutine
		  LDR     R4, [R12, R8]		//into R4 for ALTERNATE subroutine
          CMP	  R1, #0			//check for end of list
          BEQ	  DISPLAY
          B 	  ONES

ONES:     ADD	  R8, #4
		  MOV     R0, #0          // R0 will hold the result
LOOP:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     ENDONES             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       LOOP
ENDONES:  CMP     R5, R0		//If R5 is less than calculated value,
		  BLT     STRING 		//replace R5 in STRING 
		  B       ZEROES
STRING:	  MOV	  R5, R0		//store in address
		  B 	  ZEROES


ZEROES:   MOV	  R0, #0		// R0 will hold the result
	      MOV     R9, #ALL_ONES
	      LDR     R9, [R9]
	      MOV     R10,#ONE_ONE
	      LDR     R10, [R10]
ZLOOP:	  CMP     R3, R9	    // Loop until all ones
          BEQ     ENDZEROES
          LSR     R2, R3, #1
          ORR     R3, R3, R2
          ORR     R3, R3, R10
          ADD     R0, #1
          B       ZLOOP
ENDZEROES:CMP     R6, R0
		  BLT     ZSTRING
		  B       ALTERNATE
ZSTRING:  MOV     R6, R0
		  B       ALTERNATE


ALTERNATE:MOV     R11, #SEQUENCE
		  LDR     R11, [R11]
		  EOR	  R11, R11, R4	// EOR R4 with SEQUENCE, store in R11
		  MOV	  R4, R11		// R4 has parameter, R7 will have longest sequence 
								// compare, higher number is answer
		  MOV     R0, #0          // R0 will hold the result of most oens
ALOOP:    CMP     R11, #0          // loop until the data contains no more 1's
          BEQ     AZEROES             
          LSR     R2, R11, #1      // perform SHIFT, followed by AND
          AND     R11, R11, R2      
          ADD     R0, #1          // count the string length so far
          B       ALOOP

AZEROES:  MOV     R3, #0		//R3 will hold the result of most zeroes
		  MOV     R9, #ALL_ONES
	      LDR     R9, [R9]
	      MOV     R10,#ONE_ONE
	      LDR     R10, [R10]
ALOOPT:   CMP     R4, R9	    // Loop until all ones
          BEQ     ENDALT
          LSR     R2, R4, #1
          ORR     R4, R4, R2
          ORR     R4, R4, R10
          ADD     R3, #1
          B       ALOOPT
ENDALT:   CMP     R0, R3
		  BLT     ASTRING	//R3 is higher than R0, compare with R7
		  CMP     R7, R0	//R0 is higher than R3, compare with R7
		  BLT     OHIGH
		  B       NEXTNUM
OHIGH:    MOV     R7, R0
		  B       NEXTNUM
ASTRING:  CMP     R7, R3
		  BLT     ZHIGH
		  B       NEXTNUM
ZHIGH:    MOV     R7, R3
		  B       NEXTNUM

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4, DISPLAY DOES NOT WORK FOR HEX ONLY DECIMAL */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
			MOV     R4, R5, LSR #4          // display R5 on HEX1-0
			LSL     R5, #28
			LSR     R5, #28
			MOV     R0, R5			//Less significant bit first
            BL      SEG7_CODE
			STR     R0, [R8]
            MOV     R9, R0          // save bit code
            MOV     R0, R4          // More significant bit later
            BL      SEG7_CODE       
            LSL     R0, #8
			ORR     R0, R0, R9
            STR     R0, [R8]
            
			LDR     R8, =0xFF200030 // base address of HEX5-HEX4
			MOV     R7, #3
			MOV     R4, R7, LSR #4          // display R5 on HEX1-0
			LSL     R7, #28
			LSR     R7, #28
			MOV     R0, R7
            BL      SEG7_CODE
			STR     R0, [R8]
            MOV     R9, R0          // save bit code
            MOV     R0, R4          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
			ORR     R0, R0, R9
            STR     R0, [R8]
			
			
			B       END
			
SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

		  
		  
END:      B       END             

ALL_ONES: .word   0xffffffff
ONE_ONE:  .word   0x80000000
SEQUENCE: .word   0xaaaaaaaa

TEST_NUM: .word   0xaaaaaaa0	//highest sequence 28/1C
		  .word	  0x103fe00f
		  .word   0xf
		  .word   0x1			//highest zeroes 31/1F
		  .word   0x2
		  .word   0x3 
		  .word   0x4
		  .word   0x5
		  .word   0x6
		  .word   0xffffffff	//highest ones 32/20
  		  .word	  0x0

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

          .end                            

