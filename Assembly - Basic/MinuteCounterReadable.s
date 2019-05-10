/* Program counts upto 59:99 seconds with 0.01s intervals and resets to 0 */
/* More readable code */
          .text                   // executable code follows
          .global _start                  
_start:                             
          LDR     R0, =0xff200020   // Hex address
          LDR     R4, =0xff20005c   // Edge-capture address

          MOV     R12, #0
          MOV     R8, #0
          MOV     R9, #0
          MOV     R10, #0
          MOV     R11, #0
          MOV     R3, #BIT_CODES
          LDRB    R3, [R3]
          STR     R3, [R0]			// initialize hex to 0
          MOV     R2, #0xf
          STR     R2, [R4]			// initialize edge-capture

          LDR     R6, =0xfffec600	// timer load value register
          LDR     R7, =2000000
          STR 	   R7, [R6]

          MOV     R7, #0b011
          STR     R7, [R6, #0x8]

          MOV	   R7, #0x1
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
          BL      DISPLAY
          B       DELAY

TENS:     CMP     R9, #9
          BEQ     SECOND
          MOV     R8, #0
          ADD     R9, #1
          BL      DISPLAY
          B       DELAY

SECOND:   CMP     R10, #9
		BEQ     TENSEC
		MOV     R8, #0
          MOV     R9, #0
          ADD     R10, #1
          BL      DISPLAY
          B       DELAY

TENSEC:	CMP     R11, #5
	     BEQ     RESET 
		MOV     R8, #0
		MOV	   R9, #0
		MOV 	   R10, #0
		ADD     R11, #1
		BL      DISPLAY
          B       DELAY

RESET:	MOV     R8, #0
	     MOV     R9, #0
		MOV 	  R10, #0
		MOV 	  R11, #0
		BL      DISPLAY
		B 	   DELAY


DISPLAY:  PUSH      {LR}
          MOV     R5, R11
          BL        SEG7_CODE
          LSL     R3, R3, #24
          MOV     R12, R3
          MOV     R5, R10
          BL      SEG7_CODE
          LSL     R3, R3, #16
          ORR     R12, R3
            
          MOV     R5, R9
          BL      SEG7_CODE
          LSL     R3, R3, #8
          ORR     R12, R3
          
          MOV     R5, R8
          BL      SEG7_CODE
          ORR     R3, R12
          STR     R3, [R0]
          POP       {LR}
          MOV       PC, LR
          

STOP:     MOV     R2, #0xf
          STR     R2, [R4]
          B       LOOP

LOOP:     LDR     R2, [R4]    // Loop until key-press
          CMP     R2, #0
          BEQ     LOOP
          MOV     R2, #0xf
          STR     R2, [R4]
          B       DELAY

SEG7_CODE:  MOV     R2, #BIT_CODES // R5 - argument number, R3 - return pattern
            ADD     R2, R5         // index into the BIT_CODES "array"
            LDRB    R3, [R2]       // load the bit pattern (to be returned)
            MOV     PC, LR              

END:      B       END             

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

          .end                            
