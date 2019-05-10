/* Program to display count on LEDR, toggle RUN using KEY[0], 
increase speed using KEY[1], decrease speed using KEY[2] */
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
                  .global  _start                          
_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */
                MOV		R0, #0b10010
                MSR     CPSR, R0
                LDR     SP, =0x20000

                MOV     R0, #0b10011
                MSR     CPSR, R0
                LDR     SP, =0x3FFFFFFC


                  BL       CONFIG_GIC       // configure the ARM generic
                                            // interrupt controller
                  BL       CONFIG_TIMER     // configure the Interval Timer
                  BL       CONFIG_KEYS      // configure the pushbutton
                                            // KEYs port

/* Enable IRQ interrupts in the ARM processor */
                LDR     R0, =0xFFFFFF7F				
                MRS	    R1, CPSR		// copy cpsr
                AND     R1, R0		 	// modify to receive interrupts
                MSR     CPSR, R1 		// write back
                  

                  LDR      R5, =0xFF200000  // LEDR base address
LOOP:                                          
                  LDR      R3, COUNT        // global variable
                  STR      R3, [R5]         // write to the LEDR lights
                  B        LOOP                

/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:                             
                  LDR      R0, =0x7840	// 100MHz x 250msec = 25 x 10^6 in HEX
                  LDR      R2, =0x017D	// upper 16 bits
                  LDR      R1, =0xFF202000
                  STR      R0, [R1, #0x8]
                  STR      R2, [R1, #0xC]
                  MOV      R0, #0x7
                  STR      R0, [R1, #0x4]	// start is 1, cont is 1, interrupt bit is 1
                  BX       LR                  

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
                  MOV	   R0, #0xF 			    // enable interrupts for all 4 keys
				  LDR	   R1, =0xFF200050
				  STR 	   R0, [R1, #0x8]		// store to interrupt-mask register
                  BX       LR                  


/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

IRQ_HANDLER:   
				CMP      R5, #73         // check the interrupt ID for KEYS
                BLEQ     KEY_ISR
				CMP      R5, #72		 // check the interrupt ID for Interval Timer
				BLEQ	 TIMER_ISR	            

/* UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here */
                
EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception


/* Timer interval routine, DONT USE R4, R5 */
TIMER_ISR:		
				PUSH 	{LR}
				LDR     R0, COUNT
				LDR     R1, RUN
				ADD     R0, R1
				STR     R0, COUNT
				LDR     R2, =0xFF202000		// clear the timer interrupt value
				MOV     R3, #0
				STR     R3, [R2]
				POP     {PC}


/* Key routine, DONT USE R4, R5 */
KEY_ISR:
				PUSH 	{LR}
				LDR		R0, =0xFF200050   // Address for keys
				LDR		R1, [R0, #0xC]	// Load edge-capture from keys
        LDR   R2, =0xFF202000   // Address for timer

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
				POP		{PC}

STOPPED:MOV     R3, #1
				STR     R3, RUN
				STR     R1, [R0, #0xC]
				POP		{PC}

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
        CMP     R6, #0
        BEQ     RELOAD
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


/* Global variables */
                  .global  COUNT                           
COUNT:            .word    0x0              // used by timer
                  .global  RUN              // used by pushbutton KEYs
RUN:              .word    0x1              // initial value to increment
                                            // COUNT
                  .global  RATE
RATE:             .word    0x017D7840      // timer speed
                  .global  ORIGINAL
ORIGINAL:         .word    0x017D7840
.end                                    
                                     
