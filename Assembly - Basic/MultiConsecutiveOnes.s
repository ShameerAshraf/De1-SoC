/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV	  R7, #0
          MOV	  R5, #0
NEXTNUM:  MOV     R1, #TEST_NUM   // load the data word ...
		  LDR     R1, [R1, R7]        // into R1
          CMP	  R1, #0			//check for end of list
          BEQ	  END
          B 	  ONES

ONES:     ADD	  R7, #4
		  MOV     R0, #0          // R0 will hold the result
LOOP:     CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     ENDONES             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       LOOP
ENDONES:  CMP     R5, R0
		  BLT     STRING
		  B       NEXTNUM

STRING:	  MOV	  R5, R0		  // store at address
		  B 	  NEXTNUM

END:      B       END             

TEST_NUM: .word   0xffffffff
		  .word	  0x103fe00f
		  .word   0xf
		  .word   0x1 
		  .word   0x2
		  .word   0x3 
		  .word   0x4
		  .word   0x5
		  .word   0x6
		  .word   0xffffffff
  		  .word	  0x0

          .end                            
