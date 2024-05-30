.syntax unified

/* 
  snake.S houses all core game functions for snake. Particularly for 
  manipulating the snake, snake_length, and apple data locations.
  ------------------------------------------------------------------------
*/

.set RNG_VALUE, 0x4000D508

/*
  Starts game by storing all default starting data inputs into data locations.
  Default Settings:
    is_started: False
    snake_length: 1
    snake: (3,3)
    apple: (3,3) (gets randomly generated straight away anyways)
    direction: Up
 */
.global start_game
.type start_game, %function
start_game:
  ldr r0, =is_started
  mov r1, 0
  str r1, [r0]

  ldr r0, =snake_length
  mov r1, 1
  str r1, [r0]

  ldr r0, =snake
  mov r1, 3
  str r1, [r0], #4
  str r1, [r0], #4

  ldr r0, =apple
  mov r1, 3
  str r1, [r0], #4
  str r1, [r0], #4

  ldr r0, =direction
  mov r1, 0
  str r1, [r0]

  b render_snake_and_apple
.size start_game, .-start_game

/*
  Return the next head's location as based on direction data, 
  and current head in snake.
  Example:
    direction: 0 (up)
    snake: (3,3), (3,4), (3,5), ...
    r2, r3: (3,2)
  --return--
  r2: new x coordinate of head (could be unchanged)
  r3: new y coordinate of head (could be unchanged)
 */
.global next_head
.type next_head, %function
next_head:
  push {r4-r11, lr}
  
  ldr r1, =snake
  
  ldr r2, [r1], #4
  ldr r3, [r1], #4

  bl move_head

  pop {r4-r11, lr}
  bx lr
.size next_head, .-next_head

/*
  Helper for next_head, determine what to add to which coordinate based on direction data.
  --parameters--
  r2: x coordinate of head
  r3: y coordinate of head
  --return--
  r2: new x coordinate of head (could be unchanged)
  r3: new y coordinate of head (could be unchanged)
 */
.type move_head, %function
move_head:
push {r4-r11, lr}

ldr r5, =direction
ldr r5, [r5]

//mask to see if even or odd
tst r5, 0b01

beq dir_is_even
b dir_is_odd

//if even move up or down depending on left bit
dir_is_even:
    tst r5, 0b10
    beq move_up
    b move_down

//if odd move left or right depending on right bit
dir_is_odd:
    tst r5, 0b10
    beq move_right
    b move_left

move_up:  
    sub r3, 1
    cmp r3, 0
    beq move_up_overflow
    b move_head_end
    move_up_overflow:
        mov r3, 5
        b move_head_end

move_down:
    add r3, 1
    cmp r3, 6
    beq move_down_overflow
    b move_head_end
    move_down_overflow:
        mov r3, 1
        b move_head_end

move_right:
    add r2, 1
    cmp r2, 6
    beq move_right_overflow
    b move_head_end
    move_right_overflow:
        mov r2, 1
        b move_head_end

move_left:
    sub r2, 1
    cmp r2, 0
    beq move_left_overflow
    bx lr
    move_left_overflow:
        mov r2, 5
        b move_head_end

move_head_end:
    pop {r4-r11, lr}
    bx lr
.size move_head, .-move_head

/*
  Propogate snake list down one-by-one. Each entry becomes the one before it, with the
  first element become the new head. Finally storing this new snake in memory at snake.
  Example:
    r2, r3: (3,2) (new head)
    snake: (3,3), (3,4), (3,5) -> (3,2), (3,3), (3,4)
 */
.global propogate_snake
.type propogate_snake, %function
propogate_snake:
    push {r4-r11, lr}
    mov r4, 0
    ldr r0, =snake_length
    ldr r1, =snake
    ldr r5, [r0] // length of list
    b propogate_snake_loop
    propogate_snake_loop:
        cmp r5, r4 // i < snake.length()
        beq propogate_snake_end

        // new
        mov r6, r2
        mov r7, r3

        // curr 
        ldr r2, [r1], #4
        ldr r3, [r1], #4

        // store new in curr
        sub r1, #8

        str r6, [r1], #4
        str r7, [r1], #4

        add r4, 1
        b propogate_snake_loop
    propogate_snake_end:
        pop {r4-r11, lr}
        bx lr
.size propogate_snake, .-propogate_snake

/*
  Check that the current head hasn't collided with any other parts of the snake. 
  If it has, game over animation, and restart game (using start_game).
  If not, return safely.
  Example:
    snake: (3,3), (3,4), (3,5), (3,1), (3,2), (3,3) 
    hit! (the first and last part of the snake are the same)
 */
.global check_hit
.type check_hit, %function
check_hit:
    push {r4-r11, lr}

    ldr r0, =snake
    ldr r2, [r0], #4
    ldr r3, [r0], #4

    ldr r5, =snake_length
    ldr r5, [r5]
    mov r4, 1
    b check_hit_loop
    check_hit_loop:
        cmp r5, r4
        beq check_hit_end
        add r4, 1

        ldr r6, [r0], #4
        ldr r7, [r0], #4

        cmp r2, r6
        beq if_x_same
        b check_hit_loop

        if_x_same:
            cmp r3, r7
            beq if_y_same

            b check_hit_loop
            if_y_same:
                bl game_over

                ldr r0, =snake_length
                mov r1, 1
                str r1, [r0]

                ldr r0, =snake
                mov r1, 3
                str r1, [r0], #4
                str r1, [r0], #4

                pop {r4-r11, lr}
                bx lr

    check_hit_end:
        pop {r4-r11, lr}
        bx lr
.size check_hit, .-check_hit

/*
  Check that the current head is the same location as the apple.
  If it is, increment snake_length by one, and append a copy of the current tail of the snake to the end of the snake,
    propogate_snake will then extend out this snake on the next SysTick cycle. Then, generate a new 
    apple in a new spot (that isn't currently occupied, using generate_apple_in_spare_space). 
  If not, safely.
  Example:
    snake: (3,3), (3,4), (3,5), ...
    apple: (3,3)
    hit! (snake has eaten apple)
 */
.global check_apple
.type check_apple, %function
check_apple:
    push {r4-r11, lr}
    ldr r0, =apple
    ldr r1, =snake

    ldr r2, [r1], #4
    ldr r3, [r1], #4

    mov r6, r2
    mov r7, r3

    ldr r2, [r0], #4
    ldr r3, [r0], #4

    cmp r6, r2
    beq check_apple_x
    b check_apple_catch

    check_apple_x:
        cmp r7, r3
        beq check_apple_y
        b check_apple_catch

        check_apple_y:
            bl generate_apple_in_spare_space
            bl eat_apple
            b check_apple_catch
check_apple_catch:
    pop {r4-r11, lr}
    bx lr

// increment snake_length and copy over tail and append to end of snake.
eat_apple:
    push {r4-r11, lr}
    ldr r0, =snake_length
    ldr r1, [r0]
    add r1, 1
    str r1, [r0]

    sub r1, 2
    mov r2, 8
    mul r1, r2

    ldr r0, =snake
    add r1, r0

    ldr r2, [r1], #4
    ldr r3, [r1], #4

    str r2, [r1], #4
    str r3, [r1], #4

    pop {r4-r11, lr}
    bx lr
.size check_apple, .-check_apple


/*
  Generate new location for an apple that isn't currently occupied by a snake location, using RNG. When an apple is found
  and sufficiently passes tests, it will be stored into apple data.
  Example:
    snake: (3,3), (3,4), (3,5)
    apple: (5,4) (new apple, not in snake!)
  Currently done purely by brute-force (imagine rolling a dice and checking if that coordinate exists in snake),
  so it isn't the best method, especially as snake_length grows. But it gets the job done 99% of the time, and prevents
  apples dissapearing behind the snake.
 */
.type generate_apple_in_spare_space, %function
generate_apple_in_spare_space:
    push {r4-r11, lr}
    b while_generate_apple_loop

    while_generate_apple_loop:
        bl generate_apple

        ldr r0, =apple
        str r2, [r0], #4
        str r3, [r0], #4

        ldr r1, =snake
        ldr r0, =snake_length
        ldr r0, [r0]
        mov r4, 0

        b generate_apple_loop_check
        generate_apple_loop_check:
            cmp r0, r4
            beq generate_apple_loop_found
            add r4, 1

            ldr r6, [r1], #4
            ldr r7, [r1], #4

            cmp r6, r2
            beq generate_apple_check_x
            b generate_apple_loop_check
            generate_apple_check_x:
                cmp r7, r3
                beq generate_apple_check_y
                b generate_apple_loop_check

                generate_apple_check_y:
                    b while_generate_apple_loop

            b generate_apple_loop_check

    generate_apple_loop_found:
        pop {r4-r11, lr}
        bx lr
.type generate_apple_in_spare_space, %function

/*
  Helper function for generate_apple_in_spare_space, where a new apple will be randomly generated.
  x, y, coordinates between 1-5.
  --return--
  r2: new x coordinate for apple (randomly generated from 1-5)
  r3: new y coordinate for apple (randomly generated from 1-5)
 */
 .type generate_apple_in_spare_space, %function
generate_apple:
    push {r4-r11, lr}
    mov r0, 0xfff
    bl delay

    ldr r0, =RNG_VALUE
    ldr r2, [r0]

    mov r4, 52
    udiv r2, r4
    add r2, 1

    mov r0, 0xfff
    bl delay

    ldr r0, =RNG_VALUE
    ldr r3, [r0]

    udiv r3, r4
    add r3, 1

    pop {r4-r11, lr}
    bx lr
.size generate_apple, .-generate_apple
