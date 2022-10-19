/*
main.c
alexa wright
acwright@hmc.edu
10/7/22
plays a Fur Elize and the among us song (i'm so sorry) using PWM
*/

/////////////////// MAIN.C FILE /////////////////// 
#include <stdio.h>
#include <stdlib.h>
#include "STM32L432KC_FLASH.h"
#include "STM32L432KC_GPIO.h"
#include "TIMConfig.h"
///////////////////////////// MUSIC NOTES /////////////////////////////

#define tempo 0.75
#define whole (500*tempo)
#define half (250*tempo)
#define quarter (125*tempo)
#define eighth (63*tempo)
#define sixteenth (32*tempo)

#define C4 262
#define C4Sharp 277
#define D4Flat 277
#define D4 294
#define D4Sharp 311
#define E4Flat 311
#define E4 330
#define F4 349
#define F4Sharp 370
#define G4Flat 370
#define G4 392
#define A4 440
#define A4Sharp 466
#define B4Flat 466
#define B4 494
#define C5 523
#define C5Sharp 554
#define D5Flat 554
#define D5 587
#define D5Sharp 622
#define E5Flat 622
#define E5 659
#define F5 698
#define F5Sharp 741
#define G5Flat 741
#define G5 784
#define G5Sharp 831
#define A5Flat 831
#define A5 880

const int notes[][2] = {

{0,         whole},
{C5,        half},
{D5Sharp,   half},
{F5,        half},
{F5Sharp,   half},
{F5,        half},
{D5Sharp,   half},
{C5,        half},
{0,         whole},
{A4Sharp,   quarter},
{D5,        quarter},
{C5,        half},
{0,         whole},
{G4,        half},
{C4,        half},
{0,         half},
{C5,        half},
{D5Sharp,   half},
{F5,        half},
{F5Sharp,   half},
{F5,        half},
{D5Sharp,   half},
{F5Sharp,   half},
{0,         half},
{0,         quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{0,         whole},
{0,         whole},
{C5,        half},
{D5Sharp,   half},
{F5,        half},
{F5Sharp,   half},
{F5,        half},
{D5Sharp,   half},
{C5,        half},
{0,         whole},
{A4Sharp,   quarter},
{D5,        quarter},
{C5,        half},
{0,         whole},
{G4,        half},
{C4,        half},
{0,         half},
{C5,        half},
{D5Sharp,   half},
{F5,        half},
{F5Sharp,   half},
{F5,        half},
{D5Sharp,   half},
{F5Sharp,   half},
{0,         half},
{0,         quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{F5,        quarter},
{D5Sharp,   quarter},
{F5Sharp,   quarter},
{0,         whole},
{0,         whole},
{0,         whole},
{0,         whole},

{659,	125},
{623,	125},
{659,	125},
{623,	125},
{659,	125},
{494,	125},
{587,	125},
{523,	125},
{440,	250},
{  0,	125},
{262,	125},
{330,	125},
{440,	125},
{494,	250},
{  0,	125},
{330,	125},
{416,	125},
{494,	125},
{523,	250},
{  0,	125},
{330,	125},
{659,	125},
{623,	125},
{659,	125},
{623,	125},
{659,	125},
{494,	125},
{587,	125},
{523,	125},
{440,	250},
{  0,	125},
{262,	125},
{330,	125},
{440,	125},
{494,	250},
{  0,	125},
{330,	125},
{523,	125},
{494,	125},
{440,	250},
{  0,	125},
{494,	125},
{523,	125},
{587,	125},
{659,	375},
{392,	125},
{699,	125},
{659,	125},
{587,	375},
{349,	125},
{659,	125},
{587,	125},
{523,	375},
{330,	125},
{587,	125},
{523,	125},
{494,	250},
{  0,	125},
{330,	125},
{659,	125},
{  0,	250},
{659,	125},
{1319,	125},
{  0,	250},
{623,	125},
{659,	125},
{  0,	250},
{623,	125},
{659,	125},
{623,	125},
{659,	125},
{623,	125},
{659,	125},
{494,	125},
{587,	125},
{523,	125},
{440,	250},
{  0,	125},
{262,	125},
{330,	125},
{440,	125},
{494,	250},
{  0,	125},
{330,	125},
{416,	125},
{494,	125},
{523,	250},
{  0,	125},
{330,	125},
{659,	125},
{623,	125},
{659,	125},
{623,	125},
{659,	125},
{494,	125},
{587,	125},
{523,	125},
{440,	250},
{  0,	125},
{262,	125},
{330,	125},
{440,	125},
{494,	250},
{  0,	125},
{330,	125},
{523,	125},
{494,	125},
{440,	500},
{  0,	0}

};

const int len = sizeof(notes) / sizeof(notes[0]);
///////////////////////////// END MUSIC NOTES /////////////////////////////


void configure (){
  initTIM();
}

void playSong(){
  for(int i = 0; i<len; i++){
    int freq = notes[i][0];
    int duration = notes[i][1];
    if(freq){
      setFreq(freq);
      enableTone();
    }
      waitDuration(duration);
      disableTone();
  }
}


int main(void) {
  configureFlash();
  configure();
  playSong();
  
}
/////////////////// END MAIN.C FILE /////////////////// 