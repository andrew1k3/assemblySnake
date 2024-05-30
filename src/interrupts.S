.syntax unified

/*
  interrupt.S houses all functions called via interrupts, particularly by
  SysTick Timers and the GPIOTE Buttons.
  ------------------------------------------------------------------------
*/

.set GPIOTE_EVENTS_IN0, 0x40006100
.set GPIOTE_EVENTS_IN1, 0x40006104

/*
  Called every SysTick and acts as an ingame timer. The code is executed if the current tick is 0 and the game 
  has started, otherwise the tick will increment up to the set speed data value (default = 4).
  On a valid SysTick the game will, create a new head, propogate the new head down the rest of the snake list, 
  and then check for any hits of snake or apples. If an apple is hit the snake_length will be incremented by 1.
 */
.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
  push {r4-r11, lr}

  // check current tick is 0 (could be between 0 to speed), skip otherwise
  ldr r0, =tick
  ldr r1, [r0]
  sub r1, 1
  cmp r1, 0
  str r1, [r0]
  bpl SysTick_Handler_End
  ldr r2, =speed
  ldr r2, [r2]
  str r2, [r0]

  // check if game has started, skip otherwise
  ldr r0, =is_started
  ldr r1, [r0]
  cmp r1, 0
  beq SysTick_Handler_End

  // reset button clicked
  ldr r0, =button_clicked
  mov r1, 0
  str r1, [r0]
  
  bl next_head
  bl propogate_snake
  bl check_hit
  bl check_apple

  b SysTick_Handler_End
SysTick_Handler_End:
  pop {r4-r11, lr}
  bx lr
.size SysTick_Handler, .-SysTick_Handler


/*
  Called every button click (left or right), and acts as an event handler for snake direction changes.
  The code isn't executed if a button has been clicked already in the current tick (via button_clicked data), otherwise
  the direction will change based on which event was called and then stored back into direction data.
 */
.global GPIOTE_IRQHandler
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler:
  push {r4-r11, lr}

  // bounce delay for button (so that we don't get double hits)
  ldr r0, =0x4fff
  bl delay

  // mark game as started (to get the snake moving)
  ldr r0, =is_started
  mov r1, 1
  str r1, [r0]

  // check if button has already been clicked this tick
  ldr r0, =button_clicked
  ldr r1, [r0]
  cmp r1, 1
  beq GPIOTE_IRQHandler_End
  mov r1, 1
  str r1, [r0]

  // direction turns
  ldr r0, =GPIOTE_EVENTS_IN0 // left button
  ldr r3, [r0]
  and r3, 0b1
  ldr r1, =GPIOTE_EVENTS_IN1 // right button
  ldr r4, [r1]
  and r4, 0b1
  ldr r2, =direction
  ldr r5, [r2]
  sub r5, r3 // turn left (subtract from direction if r3 has a 1)
  add r5, r4 // turn right (add from direction if r4 has a 1)
  and r5, 0b11 // for overflow
  str r5, [r2] // new direction

  b GPIOTE_IRQHandler_End
GPIOTE_IRQHandler_End:
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, =GPIOTE_EVENTS_IN1
  mov r4, 0
  str r4, [r0]
  str r4, [r1]

  pop {r4-r11, lr} 
  bx lr
.size GPIOTE_IRQHandler_End, .-GPIOTE_IRQHandler_End
