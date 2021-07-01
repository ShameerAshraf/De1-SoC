/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

#include "address_map_arm.h"
#include "defines.h"
#include "interrupt_ID.h"
#include <stdlib.h>
#include <stdbool.h>

// Setting up interrupts
void set_A9_IRQ_stack(void);
void config_GIC(void);
void config_KEYs(void);
void enable_A9_interrupts(void);

// Handling interrupts
void pushbutton_ISR(void);

// Animation
void plot_pixel(int x, int y, short int line_color);
void draw_static();
void wait_for_vsync();
void draw_motion();
void draw_paper();
void reset_game();
void draw_instruction(int x);
void check_help();

// bin files
extern short FAN [30][30];
extern short PAPER [30][30];
extern short TRASH [50][50];
extern short BACKGROUND [240][320];
extern short TICK [20][22];
extern short CROSS [20][22];
extern short MISS [20][22];
extern char ENDINSTRUCTION [22];
extern char HELPSCREENONE [12];
extern char HELPSCREENTWO [13];
extern char HELPSCREENTHREE [16];
extern char HELPSCREENLEFT [4];
extern char HELPSCREENRIGHT [4];

// For use by Pushbutton interrupt handler
volatile int instruct = 0;
volatile int release = 0;
volatile int restart = 0;
volatile int reset_button = 0;

#define N 15 // Max supported on screen is 9
// paper coordinates, directions, attempts in game
int x_object, y_object, dx_object, dy_object;
int score[N];
int attempt = 0;
int x_trashcan;
volatile int pixel_buffer_start; // global variable

int main(void) {

	// Configure interrupts
	set_A9_IRQ_stack(); // initialize the stack pointer for IRQ mode
	config_GIC(); // configure the general interrupt controller
	config_KEYs(); // configure pushbutton KEYs to generate interrupts
	enable_A9_interrupts(); // enable interrupts

    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // initialize location of paper
        dx_object = ( (rand() % 2) * 2) - 1;
    	dy_object = -8;
    	y_object = 210;
    	x_object = 120 + (rand() % 130);
        x_trashcan = 150 + (rand() % 70);
    // initialize score keeping
        int i;
        for (i = 0; i < N; i ++) {
            score[i] = 0;
        }


    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    draw_static(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    draw_static();

    while (1)
    {
        draw_motion();
        check_help();
        if (reset_button == 1) reset_game();
        
        // Reached end of round
        if (attempt == 9) {
            draw_static();
            draw_motion();
            wait_for_vsync();
            pixel_buffer_start = *(pixel_ctrl_ptr + 1);
            
            // display text - press key[2] to continue
            draw_instruction(1);
            while (reset_button != 1);
            reset_game();
        }
        
        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
        draw_static();
    }
}

// Track motion/location of objects, modify if necessary
void draw_motion() {
        draw_paper();
        volatile int * sw_ptr = (int *)SW_BASE;
        int switch_status;
        switch_status = *(sw_ptr);

        if (restart == 1) {		// Restart button
        	restart = 0;
        	release = 0;
    		y_object = 210;
    		x_object = 120 + (rand() % 130);
            x_trashcan = 150 + (rand() % 70);
            attempt += 1;
            dx_object = ( (rand() % 2) * 2) - 1;
        }
        else if (release == 1) {	// Paper has been released
            y_object += dy_object;
        if (y_object < 180) x_object += dx_object;
        if (y_object < 130) x_object += dx_object;
        if (y_object < 80) x_object += dx_object;
        
        // At the end of the trajectory
        if ((y_object <= 20) || ((y_object < 100) && (x_object < 120)) || ((y_object < 100) && (x_object > 250))) {
        	release = 0; 
        	restart = 1;
            score[attempt] = -1; 
        	// and in the trash
        	if ( abs(x_trashcan - x_object) <= 20 ) {
        		score[attempt] = 1;
        	}
    	}
    	}
        else if (release == 0) {	// Move paper with Switches 1 & 0
        if ((switch_status == 0x2) && (x_object >= 110)) {  
        	x_object = x_object - 4;
        }
        if ((switch_status == 0x1) && (x_object <= 260)) { 
        	x_object = x_object + 4;
        }
        }
}

// Display help on keypress - key[3]
void check_help() {
    volatile int * keysPolled = (int *)0xFF200050;
    register int keyThree;
    keyThree = *(keysPolled);
    keyThree = keyThree & 0x8;

    if (keyThree == 0x8) {
        draw_instruction(3);
    }
    else {
        draw_instruction(4);
    }
    *(keysPolled + 3) = keyThree;
    return;
}

// Draw characters using char buffer
void draw_instruction(int x){
    volatile char * char_ctrl_ptr = (char *)0xC9000000;
    int i, j, k, l, r;
    if (x == 1) {    
    	for (i=0; i<22; i++) {
        	*(char *)(char_ctrl_ptr + (30 << 7) + (36 + i)) = ENDINSTRUCTION[i];
    	}
    }
    else if (x == 0) {
    	for (i=0; i<22; i++) {
        	*(char *)(char_ctrl_ptr + (30 << 7) + (36 + i)) = 0;
    	}
    }
    else if (x == 3) {
    	for (i = 0; i < 12; i++) {
        	*(char *)(char_ctrl_ptr + (32 << 7) + (40 + i)) = HELPSCREENONE[i];
    	}
    	for (j = 0; j < 13; j++) {
        	*(char *)(char_ctrl_ptr + (34 << 7) + (40 + j)) = HELPSCREENTWO[j];
    	}
    	for (k = 0; k < 16; k++) {
        	*(char *)(char_ctrl_ptr + (36 << 7) + (39 + k)) = HELPSCREENTHREE[k];
    	}
    	for (l = 0; l < 4; l++) {
        	*(char *)(char_ctrl_ptr + (52 << 7) + (23 + l)) = HELPSCREENLEFT[l];   
    	}
    	for (r = 0; r < 4; r++) {
        	*(char *)(char_ctrl_ptr + (52 << 7) + (67 + r)) = HELPSCREENRIGHT[r];    
    	}
    }
    else if (x == 4) {
    	for (i = 0; i < 12; i++) {
        	*(char *)(char_ctrl_ptr + (32 << 7) + (40 + i)) = 0;
    	}
    	for (j = 0; j < 13; j++) {
        	*(char *)(char_ctrl_ptr + (34 << 7) + (40 + j)) = 0;
    	}
    	for (k = 0; k < 16; k++) {
        	*(char *)(char_ctrl_ptr + (36 << 7) + (39 + k)) = 0;
    	}
    	for (l = 0; l < 4; l++) {
        	*(char *)(char_ctrl_ptr + (52 << 7) + (23 + l)) = 0;   
    	}
    	for (r = 0; r < 4; r++) {
        	*(char *)(char_ctrl_ptr + (52 << 7) + (67 + r)) = 0;    
    	}   
    }
}

void reset_game() {
    int i;
    for (i = 0; i < N; i ++) {
        score[i] = 0;
    }
    draw_instruction(0);
    reset_button = 0;
    attempt = 0;
    release = 0;
    restart = 0;
    y_object = 210;
    x_object = 120 + (rand() % 130);
    x_trashcan = 150 + (rand() % 70);
    dx_object = ( (rand() % 2) * 2) - 1;
}

// Draw box
void draw_paper() {
    int a, b;
    for (a = -15; a < 15; a++) {
        for (b = -15; b < 15; b++) {
            plot_pixel(x_object + a, y_object + b, PAPER[b+15][a+15]);
        }
    }
}

// Wait for S bit of pixel buffer 0 -> 1
void wait_for_vsync() {
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    register int status;

    *pixel_ctrl_ptr = 1;

    status = *(pixel_ctrl_ptr + 3);
    while ((status & 0x01) != 0) {
        status = *(pixel_ctrl_ptr + 3);
    }
}


// Plot black at every x and y on the screen
void draw_static() {
    int x, y, e, v, p, q, r, s, t;

    // Background - same every time
    for (x = 0; x < 320; x++) {
        for (y = 0; y < 240; y++) {
            plot_pixel(x, y, BACKGROUND[y][x]);
        }
    }

    // Trash - x coordinate randomized every round
    for (p = x_trashcan - 25; p < x_trashcan + 25; p++) {
    	for (q = 10; q < 60; q++) {
    		plot_pixel(p, q, TRASH[q-10][p- x_trashcan + 25]);
    	}
    }

    // Fan, randomize every round
    if (dx_object == 1) {
    for (e=52; e<80; e++) {
        for(v=100; v<130; v++) {
            plot_pixel(e, v, FAN[v-100][e-50]);
        }
    }
    }
    else if (dx_object == -1) {
    for (e=290; e<318; e++) {
        for(v=100; v<130; v++) {
            plot_pixel(e, v, FAN[v-100][e-290]);
        }
    }   
    }
    // Score - update every round
    int y_score = 10;
    for (r = 0; r < attempt; r++) {
    	if (score[r] == 1) {
        for (s = 12; s < 32; s++) {
            for (t = y_score; t < (y_score + 20); t++) {
                plot_pixel(s, t, TICK[t - y_score][s-10]);
            }
        }
        }
        if (score[r] == -1) {
        for (s = 12; s < 32; s++) {
            for (t = y_score; t < (y_score + 20); t++) {
                plot_pixel(s, t, CROSS[t - y_score][s-10]);
            }
        }
        }
        if (score[r] == 0) {
        for (s = 12; s < 32; s++) {
            for (t = y_score; t < (y_score + 20); t++) {
                plot_pixel(s, t, MISS[t - y_score][s-10]);
            }
        }
        }
        		y_score += 25;
    }
    // Help Screen
    if (instruct == 1) {
        draw_instruction(3);
    }
    else if (instruct == 0) {
        draw_instruction(4);
    }
}


void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

/***************************************************************************************
* Setting up receiving and processing of interrupts
****************************************************************************************/

/* setup the KEY interrupts in the FPGA */
void config_KEYs() {
volatile int * KEY_ptr = (int *)KEY_BASE; // pushbutton KEY address
*(KEY_ptr + 2) = 0xF; // enable interrupts for KEY[3-0]
}

/*
* Initialize the banked stack pointer register for IRQ mode
*/
void set_A9_IRQ_stack(void) {
int stack, mode;
stack = A9_ONCHIP_END - 7; // top of A9 onchip memory, aligned to 8 bytes
/* change processor to IRQ mode with interrupts disabled */
mode = INT_DISABLE | IRQ_MODE;
asm("msr cpsr, %[ps]" : : [ps] "r"(mode));
/* set banked stack pointer */
asm("mov sp, %[ps]" : : [ps] "r"(stack));
/* go back to SVC mode before executing subroutine return! */
mode = INT_DISABLE | SVC_MODE;
asm("msr cpsr, %[ps]" : : [ps] "r"(mode));
}

/*
* Turn on interrupts in the ARM processor
*/
void enable_A9_interrupts(void) {
int status = SVC_MODE | INT_ENABLE;
asm("msr cpsr, %[ps]" : : [ps] "r"(status));
}

/*
* Configure the Generic Interrupt Controller (GIC)
*/
void config_GIC(void) {
int address; // used to calculate register addresses
/* configure the HPS timer interrupt */
*((int *)0xFFFED8C4) = 0x01000000;
*((int *)0xFFFED118) = 0x00000080;
/* configure the FPGA interval timer and KEYs interrupts */
*((int *)0xFFFED848) = 0x00000101;
*((int *)0xFFFED108) = 0x00000300;
// Set Interrupt Priority Mask Register (ICCPMR). Enable interrupts of all
// priorities
address = MPCORE_GIC_CPUIF + ICCPMR;
*((int *)address) = 0xFFFF;
// Set CPU Interface Control Register (ICCICR). Enable signaling of
// interrupts
address = MPCORE_GIC_CPUIF + ICCICR;
*((int *)address) = ENABLE;
// Configure the Distributor Control Register (ICDDCR) to send pending
// interrupts to CPUs
address = MPCORE_GIC_DIST + ICDDCR;
*((int *)address) = ENABLE;
}

// Define the IRQ exception handler
void __attribute__((interrupt)) __cs3_isr_irq(void) {
// Read the ICCIAR from the processor interface
int address = MPCORE_GIC_CPUIF + ICCIAR;
int int_ID = *((int *)address);
if (int_ID == KEYS_IRQ) // check if interrupt is from the KEYs
pushbutton_ISR();
else
while (1); // if unexpected, then stay here
// Write to the End of Interrupt Register (ICCEOIR)
address = MPCORE_GIC_CPUIF + ICCEOIR;
*((int *)address) = int_ID;
return;
}
// Define the remaining exception handlers
void __attribute__((interrupt)) __cs3_reset(void) {
while (1);
}
void __attribute__((interrupt)) __cs3_isr_undef(void) {
while (1);
}
void __attribute__((interrupt)) __cs3_isr_swi(void) {
while (1);
}
void __attribute__((interrupt)) __cs3_isr_pabort(void) {
while (1);
}
void __attribute__((interrupt)) __cs3_isr_dabort(void) {
while (1);
}
void __attribute__((interrupt)) __cs3_isr_fiq(void) {
while (1);
}


/***************************************************************************************
* Pushbutton - Interrupt Service Routine
****************************************************************************************/
void pushbutton_ISR(void)
{
volatile int * KEY_ptr = (int *)KEY_BASE;
int press;
press = *(KEY_ptr + 3); // read the pushbutton interrupt register
*(KEY_ptr + 3) = press; // Clear the interrupt

if (press == 0x1){ release = 1;} // release value
else if (press == 0x2){ restart = 1;}
else if (press == 0x4){ reset_button = 1;}
else if (press == 0x8){ /*instruct ^= 1;*/ return;}
return;
}
