/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Program to display digit on HEX corresponding to key pressed
     using polled I/O */

          .text                   // executable code follows
          .global _start                  
_start:                             
          LDR     R0, =0xff200020   // Hex address
          LDR     R1, =0xff200050   // KEY address
          MOV     R4, #0x1          // Blank Status
     /* R2 stores buttons status, R5 stores current number */

LOOP:     LDR     R2, [R1]
          CMP     R2, #0          // No key is pressed
          BEQ     LOOP             
          
          CMP     R2, #0x8
          BEQ     BLANK           // Blank the display          

          CMP     R2, #0x2
          BEQ     INCREMENT

          CMP     R2, #0x4
          BEQ     DECREMENT

          CMP     R2, #0x1
          BEQ     LOOPZERO

          B       LOOP
          
BLANK:    LDR     R2, [R1]
          CMP     R2, #0x8
          BEQ     BLANK
          
          CMP     R4, #1          // Display already blanked
          BEQ     SETZERO
          
          MOV     R3, #0
          STR     R3, [R0]
          MOV     R4, #0x1        // Set blanked status = 1
          MOV     R5, #0
          B       LOOP

INCREMENT:LDR     R2, [R1]
          CMP     R2, #0x2
          BEQ     INCREMENT

          CMP     R4, #1
          BEQ     SETZERO

          ADD     R5, #1
          BL      SEG7_CODE
          STR     R3, [R0]
          B       LOOP

DECREMENT:LDR     R2, [R1]
          CMP     R2, #0x4
          BEQ     DECREMENT

          CMP     R4, #1
          BEQ     SETZERO

          SUB     R5, #1
          BL      SEG7_CODE
          STR     R3, [R0]
          B       LOOP
 
LOOPZERO: LDR     R2, [R1]
          CMP     R2, #0x1
          BEQ     LOOPZERO
SETZERO:  MOV     R5, #0
          BL      SEG7_CODE
          STR     R3, [R0]
          MOV     R4, #0x0
          B       LOOP

END:      B       END             

SEG7_CODE:  MOV     R6, #BIT_CODES // R5 - argument number, R3 - return pattern
            ADD     R6, R5         // index into the BIT_CODES "array"
            LDRB    R3, [R6]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

          .end                            
