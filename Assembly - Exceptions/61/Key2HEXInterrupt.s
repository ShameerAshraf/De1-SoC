/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Program to display digits on HEX display for keys pressed */
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

                BL       CONFIG_GIC      // configure the ARM generic
                                         // interrupt controller
/* Configure the KEY pushbuttons port to generate interrupts */
                
				MOV		R2, #0xF 			    // enable interrupts for all 4 keys
				LDR		R3, =0xFF200050
				STR 	R2, [R3, #0x8]		// store to interrupt-mask register


/* Enable IRQ interrupts in the ARM processor */
				LDR     R1, =0xFFFFFF7F				
                MRS	    R2, CPSR		// copy cpsr
                AND     R2, R1		 	// modify to receive interrupts
                MSR     CPSR, R2 		// write back
IDLE:                                    
                B        IDLE            // main program simply idles

/* Define the exception service routines */

SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

KEYS_HANDLER:                       
                CMP      R5, #73         // check the interrupt ID

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here
                BL       KEY_ISR         

EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt
                                         // Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception

KEY_ISR:		
				PUSH    {LR}
				LDR		R1, =0xFF200050
				LDR		R2, [R1, #0xC]	// Load edge-capture from keys

				LDR     R3, =0xFF200020
				LDR     R0, [R3]
				CMP     R0, #0			// check if HEX already displays a number
				BNE     BLANK

				CMP     R2, #0x8
          		BNE     NEXTO
          		LDR     R6, =0x4F000000
				STR     R6, [R3]
				STR     R2, [R1, #0xC]
				POP     {PC}
          		

NEXTO:         	CMP     R2, #0x4
          		BNE     NEXTW
          		LDR     R6, =0x005B0000
				STR     R6, [R3]
				STR     R2, [R1, #0xC]
				POP     {PC}
          		
NEXTW:     		CMP     R2, #0x2
          		BNE     NEXTH
          		LDR     R6, =0x00000600
				STR     R6, [R3]
				STR     R2, [R1, #0xC]
				POP     {PC}
          		
NEXTH:    		CMP     R2, #0x1
          		BNE		BLANK
          		LDR     R6, =0x0000003F
				STR     R6, [R3]
				STR     R2, [R1, #0xC]
				POP     {PC}

BLANK:			MOV     R0, #0
				STR     R0, [R3]
				STR 	R2, [R1, #0xC]
				POP		{PC}       
                    
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
