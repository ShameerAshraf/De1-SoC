/* Program that converts a binary number to baseN */
           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds N
            MOV    R0, R4       // parameter for DIVIDE goes in R0
            MOV    R1, #Divisor
            LDR    R1, [R1]
            MOV    R6, #0
            BL     DIVIDE
END:        B      END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     MOV    R2, #0
			MOV	   R3, R0		// R3 temporary location for number
CONT:	    CMP    R3, R1		// value of divisor in R1
            BLT    REMAINDER
            SUB    R3, R1
            ADD    R2, #1
            B      CONT

REMAINDER:  STRB   R3, [R5, R6]	// Store remainder
			ADD    R6, #1
			MOV    R0, R2
			CMP    R0, #0
			BEQ    END 
			B      DIVIDE


N:          .word  64         // the decimal number to be converted
Divisor:	.word  16		  // the divisor
Digits:     .space 8          // storage space for the decimal digits

            .end
