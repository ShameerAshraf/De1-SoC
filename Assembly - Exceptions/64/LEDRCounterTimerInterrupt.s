/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Displays count on LEDR and uses A9 Private Timer to display seconds upto 59:99 */
                  .section .vectors, "ax"                  
                B        _start              // reset vector
                B        SERVICE_UND         // undefined instruction vector
                B        SERVICE_SVC         // software interrupt vector
                B        SERVICE_ABT_INST    // aborted prefetch vector
                B        SERVICE_ABT_DATA    // aborted data vector
                .word    0                   // unused vector
                B        SERVICE_IRQ         // IRQ interrupt vector
                B        SERVICE_FIQ         // FIQ interrupt vector
                    
                    .text                                       
                    .global _start                              
_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */
                MOV     R0, #0b10010
                MSR     CPSR, R0
                LDR     SP, =0x20000

                MOV     R0, #0b10011
                MSR     CPSR, R0
                LDR     SP, =0x3FFFFFFC

                    BL      CONFIG_GIC          // configure the ARM generic
                                                // interrupt controller
                    BL      CONFIG_PRIV_TIMER   // configure the private timer
                    BL      CONFIG_TIMER        // configure the Interval Timer
                    BL      CONFIG_KEYS         // configure the pushbutton
                                                // KEYs port
/* Enable IRQ interrupts in the ARM processor */
                    LDR     R0, =0xFFFFFF7F             
                    MRS     R1, CPSR        // copy cpsr
                    AND     R1, R0          // modify to receive interrupts
                    MSR     CPSR, R1        // write back

                    LDR     R5, =0xFF200000     // LEDR base address
                    LDR     R6, =0xFF200020     // HEX3-0 base address
                    
LOOP:                                           
                    LDR     R4, COUNT           // global variable
                    STR     R4, [R5]            // light up the red lights

                    LDR     R4, HEX_code        // global variable
                    STR     R4, [R6]            // show the time in format
                                                // SS:DD
                    B       LOOP                


/* Configure the MPCore private timer to create interrupts every 1/100 seconds */
CONFIG_PRIV_TIMER:                              
                    LDR     R0, =0xFFFEC600
                    LDR     R1, =2000000
                    STR     R1, [R0]
                    MOV     R1, #0x7
                    STR     R1, [R0, #0x8]
                    BX      LR                  
/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:                               
                  LDR      R0, =0x7840    // 100MHz x 250msec = 25 x 10^6 in HEX
                  LDR      R2, =0x017D  // upper 16 bits
                  LDR      R1, =0xFF202000
                  STR      R0, [R1, #0x8]
                  STR      R2, [R1, #0xC]
                  MOV      R0, #0x7
                  STR      R0, [R1, #0x4]   // start is 1, cont is 1, interrupt bit is 1
                    BX      LR                  
/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
                    MOV    R0, #0xF                 // enable interrupts for all 4 keys
                    LDR      R1, =0xFF200050
                    STR      R0, [R1, #0x8]       // store to interrupt-mask register
                    BX      LR                  

/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

IRQ_HANDLER:   
                CMP      R5, #73         // check the interrupt ID for KEYS
                BLEQ     KEY_ISR
                CMP      R5, #72         // check the interrupt ID for Interval Timer
                BLEQ     TIMER_ISR            
                CMP      R5, #29
                BLEQ     MPTIMER_ISR  

/* UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here */
                
EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception

TIMER_ISR:      
                PUSH    {LR}
                LDR     R0, COUNT
                LDR     R1, RUN
                ADD     R0, R1
                STR     R0, COUNT
                LDR     R2, =0xFF202000     // clear the timer interrupt value
                MOV     R3, #0
                STR     R3, [R2]
                POP     {PC}


/* Key routine, DONT USE R4, R5 */
KEY_ISR:
                PUSH    {LR}
                LDR     R0, =0xFF200050   // Address for keys
                LDR     R1, [R0, #0xC]  // Load edge-capture from keys
        LDR   R2, =0xFF202000   // Address for timer

        CMP   R1, #0x8
        BEQ   STOPMPT

        CMP   R1, #0x4
        BEQ   HALF

        CMP   R1, #0x2
        BEQ   DOUBLE

                LDR     R3, RUN
                CMP     R3, #0
                BEQ     STOPPED
                MOV     R3, #0
                STR     R3, RUN
                STR     R1, [R0, #0xC]
                POP     {PC}

STOPPED:        MOV     R3, #1
                STR     R3, RUN
                STR     R1, [R0, #0xC]
                POP     {PC}

STOPMPT:        
                LDR     R2, =0xFFFEC600
                LDR     R3, [R2, #0x8]
                AND     R3, #0x7
                CMP     R3, #0x7
                BEQ     PAWSIT
                CMP     R3, #0x6
                BEQ     UNPAWS
                POP     {PC}

UNPAWS:         MOV     R3, #0x7
                STR     R3, [R2, #0x8]
                MOV     R3, #0x1
                STR     R3, [R2, #0xC]
                STR     R1, [R0, #0xC]
                POP   {PC}

PAWSIT:         MOV     R3, #0x6
                STR     R3, [R2, #0x8]
                MOV     R3, #0x1
                STR     R3, [R2, #0xC]
                STR     R1, [R0, #0xC]
                POP   {PC}

HALF:   
        MOV     R6, #0x8
        STR     R6, [R2, #0x4]    // Stopped

        LDR     R6, RATE
        CMP     R6, #0
        BEQ     RELOAD
        LSL     R6, #0x1
        STR     R6, RATE

        LDR     R7, =0x0000FFFF
        AND     R6, R7
        STR     R6, [R2, #0x8]
        LDR     R6, RATE
        LDR     R7, =0xFFFF0000
        AND     R6, R7
        LSR     R6, #16
        STR     R6, [R2, #0xC]

        MOV     R6, #0x7
        STR     R6, [R2, #0x4]    // Restart
        MOV     R3, #0
        STR     R3, [R2]
        STR     R1, [R0, #0xC]
        POP   {PC}

DOUBLE:
        MOV     R6, #0x8
        STR     R6, [R2, #0x4]    // Stopped

        LDR     R6, RATE
        LDR     R7, =0x017D
        CMP     R6, R7
        BLE     RELOAD
        LSR     R6, #1
        STR     R6, RATE

        LDR     R7, =0x0000FFFF
        AND     R6, R7
        STR     R6, [R2, #0x8]
        LDR     R6, RATE
        LDR     R7, =0xFFFF0000
        AND     R6, R7
        LSR     R6, #16
        STR     R6, [R2, #0xC]

        MOV     R6, #0x7
        STR     R6, [R2, #0x4]    // Restart
        MOV     R3, #0
        STR     R3, [R2]
        STR     R1, [R0, #0xC]
        POP   {PC}

RELOAD: 
        LDR     R6, ORIGINAL
        STR     R6, RATE

        LDR     R7, =0x0000FFFF
        AND     R6, R7
        STR     R6, [R2, #0x8]
        LDR     R6, RATE
        LDR     R7, =0xFFFF0000
        AND     R6, R7
        LSR     R6, #16
        STR     R6, [R2, #0xC]

        MOV     R6, #0x7
        STR     R6, [R2, #0x4]    // Restart
        MOV     R3, #0
        STR     R3, [R2]
        STR     R1, [R0, #0xC]
        POP   {PC}


MPTIMER_ISR:        
                PUSH     {LR}
                LDR      R0, =0xFFFEC600    // MPCore timer address
                
                LDR      R2, TIME
                LSR      R2, #24
                MOV      R11, R2

                LDR     R1, =0x00FF0000
                LDR     R2, TIME
                AND     R1, R2
                LSR     R1, #16
                MOV     R10, R1

                LDR     R1, =0x0000FF00
                LDR     R2, TIME
                AND     R1, R2
                LSR     R1, #8
                MOV     R9, R1

                LDR     R1, =0x000000FF
                LDR     R2, TIME
                AND     R1, R2
                MOV     R8, R1

                CMP     R8, #9
                BEQ     TENS
                ADD     R8, #1
                B       UPDATE
                
TENS:           CMP     R9, #9
                BEQ     SECOND
                MOV     R8, #0
                ADD     R9, #1
                B       UPDATE

SECOND:         CMP     R10, #9
                BEQ     TENSEC
                MOV     R8, #0
                MOV     R9, #0
                ADD     R10, #1
                B       UPDATE

TENSEC:         CMP     R11, #5
                BEQ     RESET 
                MOV     R8, #0
                MOV     R9, #0
                MOV     R10, #0
                ADD     R11, #1
                B       UPDATE
                
RESET:          MOV     R8, #0
                MOV     R9, #0
                MOV     R10, #0
                MOV     R11, #0
                B       UPDATE

UPDATE:         
                MOV       R1, R11
                LSL       R1, #24
                MOV       R2, R1

                MOV       R1, R10
                LSL       R1, #16
                ORR       R2, R1

                MOV     R1, R9
                LSL     R1, #8
                ORR     R2, R1

                MOV     R1, R8
                ORR     R2, R1
                STR     R2, TIME

                BL HEXCODE

                MOV      R1, #1
                STR      R1, [R0, #0xC]
                POP       {PC}   


HEXCODE:            PUSH    {LR}
                    LDR     R6, TIME
                    LSR     R1, R6, #24
                    BL      HEXRETURN
                    LSL     R3, #24
                    MOV     R2, R3

                    LDR     R1, =0x00FF0000
                    AND     R1, R6
                    LSR     R1, #16
                    BL      HEXRETURN
                    LSL     R3, #16
                    ORR     R2, R3

                    LDR     R1, =0x0000FF00
                    AND     R1, R6
                    LSR     R1, #8
                    BL      HEXRETURN
                    LSL     R3, #8
                    ORR     R2, R3

                    LDR     R1, =0x000000FF
                    AND     R1, R6
                    BL      HEXRETURN
                    ORR     R2, R3
                    STR     R2, HEX_code
                    POP     {PC}

/* Argument R1, return value in R3 */

HEXRETURN:          PUSH    {R4-R7}
                    CMP     R1, #5
                    BEQ     FIVEHEX
                    BGT     ABOVE
                    BLT     BELOW
FIVEHEX:            MOV     R3, #0x6D
                    POP     {R4-R7}
                    BX      LR

ABOVE:              CMP     R1, #6
                    MOVEQ   R3, #0x7D
                    CMP     R1, #7
                    MOVEQ   R3, #0x07
                    CMP     R1, #8
                    MOVEQ   R3, #0x7F
                    CMP     R1, #9
                    MOVEQ   R3, #0x6F
                    POP     {R4-R7}
                    BX      LR

BELOW:              CMP     R1, #4
                    MOVEQ   R3, #0x66
                    CMP     R1, #1
                    MOVEQ   R3, #0x06
                    CMP     R1, #2
                    MOVEQ   R3, #0x5B
                    CMP     R1, #3
                    MOVEQ   R3, #0x4F
                    CMP     R1, #0
                    MOVEQ   R3, #0x3F

                    POP     {R4-R7}
                    BX      LR

/* Global variables */
                    .global COUNT                               
COUNT:              .word   0x0       // used by timer
                    .global RUN       // used by pushbutton KEYs
RUN:                .word   0x1       // initial value to increment COUNT
                    .global TIME                                
TIME:               .word   0x0       // used for real-time clock
                    .global HEX_code                            
HEX_code:           .word   0x0       // used for 7-segment displays
                  .global  RATE
RATE:             .word    0x017D7840      // timer speed
                  .global  ORIGINAL
ORIGINAL:         .word    0x017D7840

                    
/* Undefined instructions */
SERVICE_UND:                                
                    B   SERVICE_UND         
/* Software interrupts */
SERVICE_SVC:                                
                    B   SERVICE_SVC         
/* Aborted data reads */
SERVICE_ABT_DATA:                           
                    B   SERVICE_ABT_DATA    
/* Aborted instruction fetch */
SERVICE_ABT_INST:                           
                    B   SERVICE_ABT_INST    
SERVICE_FIQ:                                
                    B   SERVICE_FIQ

             .end                                        
