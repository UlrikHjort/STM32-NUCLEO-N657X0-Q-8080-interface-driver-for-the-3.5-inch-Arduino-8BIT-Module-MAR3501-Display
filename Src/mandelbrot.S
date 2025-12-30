/**************************************************************************
 --  STM32N6 3.5inch Arduino 8-BIT Module MAR3501 Display driver Mandelbrot set Demo
 --
 --           Copyright (C) 2025 By Ulrik Hørlyk Hjort
 --
 --  This Program is Free Software; You Can Redistribute It and/or
 --  Modify It Under The Terms of The GNU General Public License
 --  As Published By The Free Software Foundation; Either Version 2
 --  of The License, or (at Your Option) Any Later Version.
 --
 --  This Program is Distributed in The Hope That It Will Be Useful,
 --  But WITHOUT ANY WARRANTY; Without Even The Implied Warranty of
 --  MERCHANTABILITY or FITNESS for A PARTICULAR PURPOSE.  See The
 --  GNU General Public License for More Details.
 --
 -- You Should Have Received A Copy of The GNU General Public License
 -- Along with This Program; if not, See <Http://Www.Gnu.Org/Licenses/>.
***************************************************************************/
.syntax unified
    .section .text

    @ RGB565 conversion
    @ Input: r0 = r, r1 = g, r2 = b
    @ Output: r0 = RGB565 value
    .align 2
    .thumb_func
RGB565:
    and     r0, r0, #0xF8       @ r & 0xF8
    lsl     r0, r0, #8          @ shift left 8
    and     r1, r1, #0xFC       @ g & 0xFC
    lsl     r1, r1, #3          @ shift left 3
    orr     r0, r0, r1          @ combine r and g
    lsr     r2, r2, #3          @ b >> 3
    orr     r0, r0, r2          @ combine with b
    bx      lr

    @ color_map11 function
    @ Input: r0 = iter, r1 = max_iter
    @ Output: r0 = color (RGB565)
    .align 2
    .global color_map11
color_map11:
    push    {r4-r7, lr}

    @ check if iter == max_iter
    cmp     r0, r1
    bne     .Lnot_max
    movs    r0, #0              @ return black
    pop     {r4-r7, pc}

.Lnot_max:
    @ c = (255 * iter) / max_iter
    movs    r2, #255
    mul     r2, r0, r2          @ 255 * iter
    udiv    r2, r2, r1          @ divide by max_iter
    mov     r4, r2              @ save c in r4

    @ check which color range
    cmp     r4, #85
    bge     .Lrange2

    @ c < 85: r = c*3, g = 255 - c*3, b = 0
    movs    r5, #3
    mul     r0, r4, r5          @ r = c * 3
    mul     r5, r4, r5          @ c * 3
    movs    r1, #255
    sub     r2, r1, r5          @ g = 255 - c*3
    movs    r1, #0              @ b = 0
    b       .Lcall_rgb565

.Lrange2:
    cmp     r4, #170
    bge     .Lrange3

    @ 85 <= c < 170: r = 255 - (c-85)*3, g = 0, b = (c-85)*3
    sub     r4, r4, #85         @ c -= 85
    movs    r5, #3
    mul     r6, r4, r5          @ (c-85) * 3
    movs    r0, #255
    sub     r0, r0, r6          @ r = 255 - (c-85)*3
    movs    r2, #0              @ g = 0
    mul     r1, r4, r5          @ b = (c-85) * 3
    b       .Lcall_rgb565

.Lrange3:
    @ c >= 170: r = 0, g = (c-170)*3, b = 255 - (c-170)*3
    sub     r4, r4, #170        @ c -= 170
    movs    r0, #0              @ r = 0
    movs    r5, #3
    mul     r2, r4, r5          @ g = (c-170) * 3
    mul     r5, r4, r5          @ (c-170) * 3
    movs    r1, #255
    sub     r1, r1, r5          @ b = 255 - (c-170)*3

.Lcall_rgb565:
    bl      RGB565
    pop     {r4-r7, pc}

    @ mandelbrot function
    .align 2
    .global mandelbrot
	.equ LCD_HEIGHT, 320
	.equ LCD_WIDTH, 480
mandelbrot:
    push    {r4-r11, lr}
    vpush   {d8-d15}
    sub     sp, sp, #64         @ local stack space

    @ max_iter = 1000
    //movw    r4, #1000
    movw    r4, #300

    @ Load constants into FPU registers
    @ xmin = -2.0, xmax = 1.0, ymin = -1.5, ymax = 1.5
    vldr    d8, .Lxmin          @ d8 = xmin = -2.0
    vldr    d9, .Lxmax          @ d9 = xmax = 1.0
    vldr    d10, .Lymin         @ d10 = ymin = -1.5
    vldr    d11, .Lymax         @ d11 = ymax = 1.5
    vldr    d12, .Lconst_4      @ d12 = 4.0
    vldr    d13, .Lconst_2      @ d13 = 2.0

    @ xmax - xmin
    vsub.f64 d14, d9, d8        @ d14 = xmax - xmin
    @ ymax - ymin
    vsub.f64 d15, d11, d10      @ d15 = ymax - ymin

    @ lcd_clear(0x000000, LCD_WIDTH, LCD_HEIGHT)
    movs    r0, #0
    ldr     r1, =LCD_WIDTH
    ldr     r2, =LCD_HEIGHT
    bl      lcd_clear

    @ py loop: for (py = 0; py < LCD_HEIGHT; py++)
    movs    r5, #0              @ py = 0

.Lpy_loop:
    ldr     r0, =LCD_HEIGHT
    cmp     r5, r0
    bge     .Lend_mandelbrot

    @ px loop: for (px = 0; px < LCD_WIDTH; px++)
    movs    r6, #0              @ px = 0

.Lpx_loop:
    ldr     r0, =LCD_WIDTH
    cmp     r6, r0
    bge     .Lnext_py

    @ x0 = xmin + (xmax - xmin) * px / LCD_WIDTH
    vmov    s0, r6
    vcvt.f64.u32 d0, s0         @ convert px to double
    ldr     r0, =LCD_WIDTH
    vmov    s2, r0
    vcvt.f64.u32 d1, s2         @ convert LCD_WIDTH to double
    vdiv.f64 d0, d0, d1         @ px / LCD_WIDTH
    vmul.f64 d0, d14, d0        @ (xmax - xmin) * px / LCD_WIDTH
    vadd.f64 d0, d8, d0         @ x0 = xmin + ...
    vstr    d0, [sp, #0]        @ store x0

    @ y0 = ymin + (ymax - ymin) * py / LCD_HEIGHT
    vmov    s0, r5
    vcvt.f64.u32 d1, s0         @ convert py to double
    ldr     r0, =LCD_HEIGHT
    vmov    s2, r0
    vcvt.f64.u32 d2, s2         @ convert LCD_HEIGHT to double
    vdiv.f64 d1, d1, d2         @ py / LCD_HEIGHT
    vmul.f64 d1, d15, d1        @ (ymax - ymin) * py / LCD_HEIGHT
    vadd.f64 d1, d10, d1        @ y0 = ymin + ...
    vstr    d1, [sp, #8]        @ store y0

    @ x = 0.0, y = 0.0
    movs    r0, #0
    movs    r1, #0
    vmov    d2, r0, r1          @ x = 0.0
    vmov    d3, r0, r1          @ y = 0.0
    movs    r7, #0              @ iter = 0

.Liter_loop:
    @ while (x*x + y*y <= 4.0 && iter < max_iter)
    vmul.f64 d4, d2, d2         @ x*x
    vmul.f64 d5, d3, d3         @ y*y
    vadd.f64 d6, d4, d5         @ x*x + y*y
    vcmp.f64 d6, d12            @ compare with 4.0
    vmrs    APSR_nzcv, FPSCR
    bgt     .Liter_end
    cmp     r7, r4              @ compare iter with max_iter
    bge     .Liter_end

    @ xtemp = x*x - y*y + x0
    vsub.f64 d4, d4, d5         @ x*x - y*y
    vldr    d0, [sp, #0]        @ load x0
    vadd.f64 d4, d4, d0         @ xtemp = x*x - y*y + x0

    @ y = 2*x*y + y0
    vmul.f64 d5, d2, d3         @ x*y
    vmul.f64 d5, d13, d5        @ 2*x*y
    vldr    d1, [sp, #8]        @ load y0
    vadd.f64 d3, d5, d1         @ y = 2*x*y + y0

    @ x = xtemp
    vmov.f64 d2, d4

    @ iter++
    add     r7, r7, #1
    b       .Liter_loop

.Liter_end:
    @ color = color_map11(iter, max_iter)
    mov     r0, r7              @ iter
    mov     r1, r4              @ max_iter
    str     r5, [sp, #16]       @ save py
    str     r6, [sp, #20]       @ save px
    bl      color_map11
    ldr     r5, [sp, #16]       @ restore py
    ldr     r6, [sp, #20]       @ restore px
    mov     r8, r0              @ save color

    @ lcd_draw_pixel(px, py, color)
    mov     r0, r6              @ px
    mov     r1, r5              @ py
    mov     r2, r8              @ color
    bl      lcd_draw_pixel

    @ px++
    add     r6, r6, #1
    b       .Lpx_loop

.Lnext_py:
    @ py++
    add     r5, r5, #1
    b       .Lpy_loop

.Lend_mandelbrot:
    add     sp, sp, #64
    vpop    {d8-d15}
    pop     {r4-r11, pc}

    @ Constants
    .align 3
.Lxmin:
    .double -2.0
.Lxmax:
    .double 1.0
.Lymin:
    .double -1.5
.Lymax:
    .double 1.5
.Lconst_4:
    .double 4.0
.Lconst_2:
    .double 2.0

    @ External symbols
    .extern lcd_clear
    .extern lcd_draw_pixel
