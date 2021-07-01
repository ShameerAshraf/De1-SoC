/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           
		    STR     R3, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the lisst
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list
 */
LARGE:      LDR R3, [R1]            //Load first number from current position in list
LOOP:       SUBS R0, R0, #1         //decrement number of elements remaining/to be checked
            BEQ FINAL               //If end of list, quit
            ADD R1, #4              //increment by 4 to get next in list
            LDR R2, [R1]
            CMP R3, R2              //check if value in R3 larger than R2 
            BGE LOOP                //If currently holding largest value, get next in list 
            MOV R3, R2
            B LOOP
FINAL:		MOV PC, LR

            

RESULT:     .word   0           
N:          .word   9           // number of entries in the list
NUMBERS:    .word   4, 5, 5, 6  // the data
            .word   1, 8, 2, 9
            .word   8                 

            .end                            

