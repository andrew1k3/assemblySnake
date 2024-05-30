.syntax unified

/*
  main.S houses all code and data only used once at the start of run-time.
  ------------------------------------------------------------------------
*/

.set GPIOTE_INTENSET, 0x40006304
.set GPIOTE_CONFIG0, 0x40006510
.set GPIOTE_CONFIG1, 0x40006514
.set GPIOTE_CONFIG2, 0x40006518
.set NVIC_ISER0, 0xE000E100
.set NVIC_ISER1, 0xE000E104
.set NVIC_ISER2, 0xE000E108
.set SHPRC, 0xE000ED20
.set RNG_START, 0x4000D000

.global main
.type main, %function
main:
  b init
.size main, .-main

/*
  Initialise Peripherals including LEDs, SysTick, GPIOTE Buttons, and Random Number Generator.
 */
.type init, %function
init:
  // LEDs
  bl init_leds

  // SysTick
  ldr r0, =ADR_SYST_CSR
  mov r1, 0b111
  str r1, [r0]

  ldr r0, =ADR_SYST_RVR
  ldr r1, =0x2FFFFF
  str r1, [r0] 

  // GPIOTE Buttons
  ldr r0, =GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1, [r0]

  ldr r0, =GPIOTE_CONFIG1
  ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16) 
  str r1, [r0]

  ldr r0, =GPIOTE_CONFIG2
  ldr r1, =(1 | 4 << 8 | 1 << 13 | 1 << 16) 
  str r1, [r0]

  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b11
  str r1, [r0]

  ldr r0, =NVIC_ISER0
  ldr r1, =(1 << 6)
  str r1, [r0]

  ldr r0, =NVIC_ISER1
  ldr r1, =(1 << 21)
  str r1, [r0]

  // RNG
  ldr r0, =RNG_START
  ldr r1, =0b1
  str r1, [r0]  

  b start_game
.size init, .-init

.global direction, snake_length, button_clicked, is_started, apple, speed, tick, pin_data, snake
.data
direction: // 0 up, 1 right, 2 down, 3 left
  .word 0

snake_length: // length of snake
  .word 1

button_clicked: // boolean if button has already been clicked in cycle
  .word 0

is_started: // boolean if game is started 
  .word 0

apple: // location of apple 
  .word 3, 3

speed: // number of ticks needed to progress game tick. (CAN BE CHANGED, 4 = intended, greater is slower)
  .word 4

tick: // current tick (cycle from 0 to speed-1)
  .word 0

pin_data: // pin_data from LED.s (This is here because snake is an expanding list and was overwriting it)
  .word 21, 22, 15, 24, 19
  .word 28, 11, 31, 05, 30

snake: // snake positions (will expand)
  .word 3, 3
  @ .word 3, 4
  @ .word 3, 5

