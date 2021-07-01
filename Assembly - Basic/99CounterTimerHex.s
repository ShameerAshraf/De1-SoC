/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Program that counts to 99 using ARM A9 Private Timer and displays it on HEX[1:0] */

          .text                   // executable code follows
          .global _start                  
_start:                             
          LDR     R0, =0xff200020   // Hex address
          LDR     R4, =0xff20005c   // Edge-capture address

          MOV     R10, #0
          MOV     R8, #0
          MOV     R9, #0
          MOV     R3, #BIT_CODES
          LDRB    R3, [R3]
          STR     R3, [R0]			// initialize hex to 0
          MOV     R2, #0xf
          STR     R2, [R4]			// initialize edge-capture

          LDR     R6, =0xfffec600	// timer load value register
          LDR     R7, =50000000
          STR 	  R7, [R6]

          MOV     R7, #0b011
          STR     R7, [R6, #0x8]

          MOV	  R7, #0x1
          STR     R7, [R6, #0xc]


DELAY:    LDR     R1, [R6, #0xc]
		  CMP     R1, #0			// check if interrupt is 1
		  BEQ     DELAY
		  MOV     R1, #0
		  MOV     R7, #0x1			// reset interrupt status to 0
		  STR     R7, [R6, #0xc]

          LDR     R2, [R4]
          CMP     R2, #0x0
          BNE     STOP          
          
          B       INCREMENT
          

INCREMENT:CMP     R8, #9
          BEQ     TENS

          ADD     R8, #1
          MOV     R5, R8
          BL      SEG7_CODE
          ORR     R3, R10
          STR     R3, [R0]
          B       DELAY

TENS:     CMP     R9, #9
          BEQ     RESET

          MOV     R8, #0
          ADD     R9, #1
          MOV     R5, R9
          BL      SEG7_CODE
          LSL     R10, R3, #8
          MOV     R5, R8
          BL      SEG7_CODE
          ORR     R3, R10
          STR     R3, [R0]
          B       DELAY

RESET:    MOV     R8, #0
          MOV     R9, #0
          MOV     R5, R8
          BL      SEG7_CODE
          LSL     R10, R3, #8
          ORR     R3, R10
          STR     R3, [R0]
          B       DELAY


STOP:     MOV     R2, #0xf
          STR     R2, [R4]
          B       LOOP

LOOP:     LDR     R2, [R4]    // Loop until key-press
          CMP     R2, #0
          BEQ     LOOP
          MOV     R2, #0xf
          STR     R2, [R4]
          B       DELAY

SEG7_CODE:  MOV     R12, #BIT_CODES // R5 - argument number, R3 - return pattern
            ADD     R12, R5         // index into the BIT_CODES "array"
            LDRB    R3, [R12]       // load the bit pattern (to be returned)
            MOV     PC, LR              

END:      B       END             

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

          .end                            
