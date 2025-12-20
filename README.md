# STM32 NUCLEO-N657X0-Q 3.5 inch Arduino 8BIT Module MAR3501 Display driver
 
STM32 NUCLEO-N657X0-Q 8080 interface driver for the 3.5 inch Arduino 8BIT Module MAR3501 Display (see data-sheet for details). Driver is only partial e.g write only and landscape mode only.

Mandelbrot set demo included to show usage.

This is not a full working stm32 project. The files here are part of a STM32CUBEIDE project for STM32N657X0HXQ. Create a project for this and then replace Src and Inc in the Core directory with the Src and Inc directories here.

The gpio setup for the display match the gpio layout for the
Arduino header on the nucleo-stm32n6 board. Driver can be used for all stm32
boards with the Arduino Uno V3 header (I assume), but one will need to remap the gpios. Consult the user manual for NUCLEO-N657X0-Q and for the display in case a remapping is needed. 

Nothing have been optimized here, that will probably happen later. Specially the
drawing of the Mandelbrot set calls for some optimization. 

The data sheet for ILI9486 and the user manual for the display is also included here as pdf.