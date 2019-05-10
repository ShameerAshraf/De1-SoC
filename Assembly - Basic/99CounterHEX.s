/* Program that counts to 99 and displays count on HEX [1:0] */
          .text                   // executable code follows
          .global _start                  
_start:                             
          LDR     R0, =0xff200020   // Hex address
          LDR     R1, =0xff200050   // KEY address
          LDR     R4, =0xff20005c   // Edge-capture address
     /* R2 stores buttons status, R8 stores digit, R9 stores tens, R10 tens hexcode */

          MOV     R10, #0
          MOV     R8, #0
          MOV     R9, #0
          MOV     R5, R8
          BL      SEG7_CODE
          STR     R3, [R0]
          MOV     R2, #0xf
          STR     R2, [R4]

DO_DELAY: LDR     R7, =200000000
SUB_LOOP: SUBS    R7, #1
          BNE     SUB_LOOP

          LDR     R2, [R4]
          CMP     R2, #0x8
          BEQ     STOP          
          CMP     R2, #0x2
          BEQ     STOP
          CMP     R2, #0x4
          BEQ     STOP
          CMP     R2, #0x1
          BEQ     STOP

          B       INCREMENT
          B       DO_DELAY
          

INCREMENT:CMP     R8, #9
          BEQ     TENS

          ADD     R8, #1
          MOV     R5, R8
          BL      SEG7_CODE
          ORR     R3, R10
          STR     R3, [R0]
          B       DO_DELAY

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
          B       DO_DELAY

RESET:    MOV     R8, #0
          MOV     R9, #0
          MOV     R5, R8
          BL      SEG7_CODE
          LSL     R10, R3, #8
          ORR     R3, R10
          STR     R3, [R0]
          B       DO_DELAY


STOP:     MOV     R2, #0xf
          STR     R2, [R4]
          B       LOOP

LOOP:     LDR     R2, [R4]    // Loop until key-press
          CMP     R2, #0
          BEQ     LOOP
          MOV     R2, #0xf
          STR     R2, [R4]
          B       DO_DELAY

END:      B       END             

SEG7_CODE:  MOV     R6, #BIT_CODES // R5 - argument number, R3 - return pattern
            ADD     R6, R5         // index into the BIT_CODES "array"
            LDRB    R3, [R6]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

          .end                            
