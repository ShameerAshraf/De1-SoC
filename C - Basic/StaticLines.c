/* Program to draw random lines on screen */

volatile int pixel_buffer_start; // global variable
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int start_x, int start_y, int end_x, int end_y, short int line_color);

#include <stdbool.h>

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    //try pixel_buffer_start = 0xC8000000

    clear_screen();
    // Specify lines to draw, drawline(starting x, y coordinate, ending x, y coordinate, color)
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
    return 0;
}

// code not shown for clear_screen() and draw_line() subroutines


// Plot black at every x and y on the screen
void clear_screen() {
	int x, y;
	for (x = 0; x < 320; x++) {
		for (y = 0; y < 240; y++) {
			plot_pixel(x, y, 0);
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
