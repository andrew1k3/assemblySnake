.syntax unified

/* 
  render.S houses all functionality for manipulating the MicroBit's LEDs.
  ------------------------------------------------------------------------
*/

/*
  Core central game loop for rendering the snake (statically). This renders the snake
  and apple on the MicroBit's LED grid, infinitely until interuppted.
  Example:
    snake: (3,3), (3,4), (3,5), (2,5), (1,5), (1,4) 
    apple: (1,1)
    MicroBit LED grid for human eyes (in actuality each point is rendered and turned off individually VERY quickly):
        a - - - -
        - - - - -
        - - S - -
        s - s - -
        s s s - - 
    (a) = dimmer LED for apple
    (S) = head of snake
    (s) = rest of snake
 */
.global render_snake_and_apple
.type render_snake_and_apple, %function
render_snake_and_apple:
  ldr r5, =snake_length
  ldr r5, [r5]

  ldr r0, =apple
  ldr r2, [r0], #4
  ldr r3, [r0], #4
  bl render_apple

  ldr r6, =snake
  mov r4, 0
  b render_snake_loop
  render_snake_loop:
    cmp r5, r4
    beq render_snake_and_apple

    ldr r2, [r6], #4
    ldr r3, [r6], #4
    bl write_snake_pins

    ldr r0, =0xfff
    bl delay
    
    bl clear_snake_pins

    ldr r0, =0xfff
    bl delay

    add r4, 1
    b render_snake_loop
.size render_snake_and_apple, .-render_snake_and_apple

/*
  Helper function within render_snake_and_apple to render the apple with a quicker delay,
  such that the LED appears dimmer to be dicernable from the rest of the snake.
  --parameters--
  r2: x coordinate of apple to render
  r3: y coordinate of apple to render
 */
.global render_apple
.type render_apple, %function
render_apple:
    push {r4-r11, lr}

    bl write_snake_pins

    mov r0, 0xff
    bl delay

    bl clear_snake_pins

    ldr r0, =0xff
    bl delay

    pop {r4-r11,lr}
    bx lr
.size render_apple, .-render_apple

/*
  Write a portion of a snake's location into the LED peripherals. For example,
  rendering the head of a snake (3,3) will turn on the center LED.
  --parameters--
  r2: x coordinate to render
  r3: y coordinate to render
 */
.global write_snake_pins
.type write_snake_pins, %function
write_snake_pins:
    push {r4-r11,lr}

    mov r6, r2
    mov r7, r3

    mov r0, 0b100000
    lsr r0, r6
    bl write_column_pins_natural

    mov r0, 0b100000
    lsr r0, r7
    bl write_row_pins_natural

    pop {r4-r11,lr}
    bx lr
.size write_snake_pins, .-write_snake_pins

/*
  Clear all of the MicroBit's LED grid. 
 */
.global clear_snake_pins
.type clear_snake_pins, %function
clear_snake_pins:
    push {r4-r11,lr}

    mov r0, 0b00000
    bl write_row_pins_natural

    mov r0, 0b00000
    bl write_column_pins_natural

    pop {r4-r11,lr}
    bx lr
.size clear_snake_pins, .-clear_snake_pins

/*
  Render the flashing game over animation and return back safely.
  grid:
      1 1 1 1 1       0 0 0 0 0 
      1 1 1 1 1       0 0 0 0 0    
      1 1 1 1 1  -->  0 0 0 0 0   -->  (repeat)
      1 1 1 1 1       0 0 0 0 0 
      1 1 1 1 1       0 0 0 0 0  
 */
.global game_over
.type game_over, %function
game_over:
    push {r4-r11,lr}
    mov r4, 0
    mov r5, 3 // Change to increase number of cycles
game_over_loop:
    cmp r5, r4
    beq game_over_end

    mov r0, 0b11111
    bl write_row_pins_natural

    mov r0, 0b11111
    bl write_column_pins_natural

    ldr r0, =0x1fffff
    bl delay

    mov r0, 0b00000
    bl write_row_pins_natural

    mov r0, 0b00000
    bl write_column_pins_natural

    ldr r0, =0x1fffff
    bl delay

    add r4, 1
    b game_over_loop
game_over_end:
    pop {r4-r11,lr}
    bx lr
.size game_over, .-game_over