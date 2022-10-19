/*
TIMConfig.h
alexa wright
acwright@hmc.edu
10/7/22
header file
*/

/////////////////// TIMCONFIG.H FILE ///////////////////
#ifndef TIMCONFIG_H
#define TIMCONFIG_H
#include <stdint.h>
#include <stdbool.h>
#include "STM32L432KC_RCC.h"
//////////////// TIMER CONFIGURATION ///////////////
#define CLKFREQ (80000000)//Base clock frequency                       
#define NOTEPPSC (4096)   //prescaler for the note length generating portion
#define NOTEFPSC (16)     //prescaler for the note period
//------------------------------------------------//
//                  DEFINITIONS                   //
//------------------------------------------------//
#define TIM6_BASE (0x40001000UL)
#define TIM2_BASE (0x40000000UL) 
typedef struct{           //Timer 6 Memory Map
  volatile uint32_t CR1;  //00-04
  volatile uint32_t CR2;  //04-08
  uint32_t RESERVED1;     //08-0C
  volatile uint32_t DIER; //0C-10
  volatile uint32_t SR;   //10-14
  volatile uint32_t EGR;  //14-18
  uint32_t RESERVED2;     //18-1C
  uint32_t RESERVED25;    //1C-20
  uint32_t RESERVED3;     //20-24
  uint16_t RESERVED4;     //24-26
  uint16_t CNT;           //26-28
  uint16_t RESERVED5;     //28-2A
  uint16_t PSC;           //2A-2C
  uint16_t RESERVED6;     //2C-2E
  volatile uint16_t ARR;  //2E-30
}TIM6_TypeDef;    

typedef struct{     //Timer 2 Memory Map
  volatile uint32_t CR1;  //00
  volatile uint32_t CR2;  //04
  volatile uint32_t SMCR; //08
  volatile uint32_t DIER; //0C
  volatile uint32_t SR;   //10
  volatile uint32_t EGR;  //14
  volatile uint32_t CCMR1;//18
  volatile uint32_t CCMR2;//1C
  volatile uint32_t CCER; //20
  volatile uint32_t CNT;  //24
  volatile uint32_t PSC;  //28
  volatile uint32_t ARR;  //2C
  uint32_t RESERVED1;     //30
  volatile uint32_t CCR1; //34
  volatile uint32_t CCR2; //38
  volatile uint32_t CCR3; //3C
  volatile uint32_t CCR4; //40
  uint32_t RESERVED2;     //44
  volatile uint32_t DCR;  //48
  volatile uint32_t DMAR; //4C
  volatile uint32_t OR1;  //50
  uint32_t RESERVED3;     //54
  uint32_t RESERVED4;     //58
  uint32_t RESERVED5;     //5C
  volatile uint32_t OR2;  //60
}TIM2_TypeDef;
#define TIM6 ((TIM6_TypeDef *) TIM6_BASE) //duration counter
#define TIM2 ((TIM2_TypeDef *) TIM2_BASE) //frequency counter
//------------------------------------------------//
//                END DEFINITIONS                 //
//------------------------------------------------//

//------------------------------------------------//
//              FUNCTION PROTOTYPES               //
//------------------------------------------------//
void initTIM();
void disableTone();
void enableTone();
void setFreq(int targFreq);
void waitDuration(int duration);
void setDelay(int durationMs);
//------------------------------------------------//
//            END FUNCTION PROTOTYPES             //
//------------------------------------------------//
////////////// END TIMER CONFIGURATION /////////////
#endif
/////////////////// END TIMCONFIG.H FILE ///////////////////