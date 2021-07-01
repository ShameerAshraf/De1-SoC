/* Copyright (C) Syed Shameer Ashraf - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Syed Shameer Ashraf <shameer.ashraf7@gmail.com>, May 2019
 */

 /* Program to display moving boxes and lines on screen */

#include <stdlib.h>
#include <stdbool.h>

void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int start_x, int start_y, int end_x, int end_y, short int line_color);
void wait_for_vsync();
void draw();
void draw_box(int id);
void draw_connect(int a, int b, short int line_color);

// object quantity, coordinates, directions, colors
#define N 6
int x_object[N], y_object[N], dx_object[N], dy_object[N];
short int color_object[N];
short int colors[] = {0x001F, 0x07E0, 0xF800, 0xFD20, 0xFFE0, 0xF81F};

volatile int pixel_buffer_start; // global variable


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables
    // initialize location and direction of rectangles

    int i;
    for (i = 0; i < N; i++) {
        dx_object[i] = ( (rand() % 2) * 2) - 1;
        dy_object[i] = ( (rand() % 2) * 2) - 1;

        color_object[i] = colors[i];  // declare array colors with N random colors

        x_object[i] = rand() % 320;
        y_object[i] = rand() % 240;
    }

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen();

    while (1)
    {
        // code for drawing the boxes and lines
        draw();

        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer

        /* Erase any boxes and lines that were drawn in the last iteration */
        clear_screen();
        
    }
}

// Draw boxes and lines drawn on screen
void draw() {
    int i, j;
    for (j = 0; j < N; j++) {
        draw_connect(j, (j+1) % N, 0x03EF);
    }

    for (i = 0; i < N; i++) {
        draw_box(i);

        // code for updating the locations of boxes
        if ( (x_object[i] + 3) == 319) { dx_object[i] = -1; }
        if ( (x_object[i] - 3) == 0) { dx_object[i] = 1; }
        if ( (y_object[i] + 2) == 239) { dy_object[i] = -1; }
        if ( (y_object[i] - 2) == 0) { dy_object[i] = 1; }

        x_object[i] += dx_object[i];
        y_object[i] += dy_object[i];
    }
}


// Draw box
void draw_box(int id) {
    int a, b;
    for (a = -3; a < 4; a++) {
        for (b = -2; b < 3; b++) {
            plot_pixel(x_object[id] + a, y_object[id] + b, color_object[id]);
        }
    }
}

// Draw connecting line
void draw_connect(int a, int b, short int line_color) {
    draw_line(x_object[a], y_object[a], x_object[b], y_object[b], line_color);
}

// Wait for S bit 0 -> 1
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
void clear_screen() {
    int x, y;
    for (x = 0; x < 320; x++) {
        for (y = 0; y < 240; y++) {
            plot_pixel(x, y, 0x0);
        }
    }
}

// Draw line using beybvhjdnvk algorithm
void draw_line(int start_x, int start_y, int end_x, int end_y, short int line_color) {

    // Check line parameters
    bool is_steep = abs(end_y - start_y) > abs(end_x - start_x);
    if (is_steep) {
        int temp;
        // Swap x0, y0
        temp = start_x;
        start_x = start_y;
        start_y = temp;
        // Swap x1, y1
        temp = end_x;
        end_x = end_y;
        end_y = temp;
    }
    if (start_x > end_x) {
        int temp;
        // Swap x0, x1
        temp = start_x;
        start_x = end_x;
        end_x = temp;
        // Swap y0, y1
        temp = start_y;
        start_y = end_y;
        end_y = temp;
    }

    // Init drawing parameters
    int deltax = end_x - start_x;
    int deltay = abs(end_y - start_y);
    int error = -(deltax / 2);
    int y = start_y;
    int y_step;
    if (start_y < end_y) {
        y_step = 1;
    }
    else {
        y_step = -1;
    }

    // Compute values of y for values of x
    int x;
    for (x = start_x; x < end_x; x++) {
        if (is_steep) {
            plot_pixel(y, x, line_color);
        }
        else {
            plot_pixel(x, y, line_color);
        }

        error = error + deltay;
        if (error >= 0) {
            y = y + y_step;
            error = error - deltax;
        }
    }

}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}
