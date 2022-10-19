/*
TIMConfig.c
alexa wright
acwright@hmc.edu
10/7/22
Implements PWM using clock timers
*/

/*******************************************************/
/****************** TIMCONFIG.C FILE *******************/
/*******************************************************/
#include  "TIMConfig.h"
#include "STM32L432KC_GPIO.h"
void initTIM(){
    //Configure PLL and set it to SYSCLK
    configureClock();
    RCC->AHB2ENR |= (1<<0);     //Enable clock for gpio
///////// Timer 6 configuration //////////////
    RCC->APB1ENR1 |= (1 <<4);   //Clock for TIM6
    TIM6->PSC |= (NOTEPPSC);    //Set duration prescalers
    TIM6->EGR |=(1<<0);
///////// Set pins /////////////
    pinMode(5,GPIO_ALT);        //Select the alt pin function
    GPIO->AFRL &=~(0b1111<<20); //clear bits for pin5
    GPIO->AFRL |= (0b0001<<20); //set alt function for pin5    
////////// TIMER 2 CONFIGURATION //////////
//Config OC1M for comparison mode one 110
    RCC->APB1ENR1 |= (1 <<0);   //Clock for TIM2
    TIM2->CCMR1 &= ~(0b111<<4);
    TIM2->CCMR1 |=(0b110<<4);   //pwm mode 1
    TIM2->CCMR1 |=(1<<3);       //Config OC1PE 
    TIM2->CR1   |=(1<<7);       //Config ARPE
    TIM2->EGR   |=(1<<0);       //config UG 
    TIM2->CCER  |=(1<<1);       //Config CC1P
    TIM2->CCER  |=(1<<0);       //Config CC1E 
    TIM2->PSC |= (NOTEFPSC);    //Set frequency prescaler
 }
void enableTone(){
  TIM2->CR1 |= (1<<0);        //*dies a little on the inside*
}
void disableTone(){
  //TIM2->CNT = 0;                
  TIM2->CR1 &= ~(1<<0);       //*dies slightly more on the inside*
}
void setFreq(int targFreq){
  int timARR = CLKFREQ/(targFreq*(NOTEFPSC+1)); //calculate auto reset reg
  TIM2->ARR = (uint32_t)timARR;           
  TIM2->CCR1 = ((TIM2->ARR/2)); //Set the doody cycle
  TIM2->EGR |=(1<<0);           //I dunno something something reset event stuff 
}
void setDelay(int durationMs){
  //calculate the auto reset value                
  double autoArrVal = (((double)CLKFREQ*durationMs/((double)(NOTEPPSC+1)*1000)));
  TIM6->ARR = (uint16_t)autoArrVal; //Set it            
 }
void waitDuration(int duration){ 
  TIM6->CNT = 0;              //clear count
  TIM6->CR1 |= (0b1<<0);      //enable timer
  setDelay(duration);         //*deceased internally*
  //While the count has not overflowed
  while(TIM6->SR==0)
  {
    //do nothing lmao
    __asm("nop");
  }
  //TIM6->CNT = 0; 
  TIM6->CR1 &= ~(0b1<<0);   //disable timer
  TIM6->SR =0;
}
/*******************************************************/
/**************** END TIMCONFIG.C FILE *****************/
/*******************************************************/