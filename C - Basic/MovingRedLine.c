/* Program to display moving line on screen, test for animation */

volatile int pixel_buffer_start; // global variable
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int start_x, int start_y, int end_x, int end_y, short int line_color);
void wait_for_vsync();

#include <stdbool.h>

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
    //try pixel_buffer_start = 0xC8000000

    /* Set backbuffer to same value as buffer */
    *(pixel_ctrl_ptr + 1) = *pixel_ctrl_ptr;

    clear_screen();
    wait_for_vsync();

    // Loop to move the line on the screen
    int y = 0;
    bool dy = 1;
    while(1) {

    	draw_line(0, y, 319, y, 0xF800); // this line is red
    	wait_for_vsync();
    	draw_line(0, y, 319, y, 0x0);	// black line to clear screen

    	if (y == 239) { dy = 0; }
    	if (y == 0) { dy = 1; }

    	if (dy) { y++; }
    	else { y--; }

    }

    return 0;
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
			// try draw_line(0, y, 239, y, 0);
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
