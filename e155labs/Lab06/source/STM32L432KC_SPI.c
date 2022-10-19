/*STM32L432KC_SPI.c
 alexa wright
 acwright@hmc.edu
 10/7/22
 Simplifies SPI use by initializing SPI in the initSPI function, 
 and handling reading/writing in the spiSendReceive function.
*/
#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"
void initSPI(int br, int cpol, int cpha){
//Selection: SPI1
// 1. Configure GPIO for MOSI, MISO and SCK
  //////////// SETTING MODE REGISTER (aka Pinmode) ////////////  
  pinMode(PA7, GPIO_ALT);     //SPI1 MOSI PA7
  pinMode(PA6, GPIO_ALT);     //SPI1 MISO PA6  
  pinMode(PA5, GPIO_ALT);     //SPI1 SCK  PA5
  pinMode(PA8, GPIO_OUTPUT);  //SPI1 Chip Select

  //Enable SPI1 in the RCC register
  RCC->APB2ENR |= _VAL2FLD(RCC_APB2ENR_SPI1EN, 0b1);
  //////////// SELECTING ALTERNATE FUNCTIONS ////////////
  
  GPIOA->AFR[0] &= ~GPIO_AFRL_AFSEL7_Msk;               //clear bits  | SPI1 MOSI
  GPIOA->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL7, 0b0101); //set bits    | (pin A7)

  GPIOA->AFR[0] &= ~GPIO_AFRL_AFSEL6_Msk;              //clear bits  | SPI1 MISO
  GPIOA->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL6, 0b0101); //set bits    | (pin A6)

  GPIOA->AFR[0] &= ~GPIO_AFRL_AFSEL5_Msk;               //clear bits  | SPI1 SCK
  GPIOA->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL5, 0b0101);  //set bits    | (pin A5)

// 2. Write to SPI_CR1 register
//    2.a Configure serial clock baudrate BR[2:0]
      SPI1->CR1 &= ~SPI_CR1_BR_Msk;                     //clear bits
      SPI1->CR1 |= _VAL2FLD(SPI_CR1_BR, br&0b111);     //set bits 
//    2.b Configure polarity and phase CPOL CPHA
      SPI1->CR1 &= ~SPI_CR1_CPHA_Msk;                   //clear bits  | Set phase
      SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPHA, cpha&0b1);    //set bits    |
      SPI1->CR1 &= ~SPI_CR1_CPOL_Msk;                   //clear bits  | Set polarity
      SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPOL, cpol&0b1);    //set bits    |
//    3.a configure DS[3:0] to select data length for transfer
      SPI1->CR2 &= ~SPI_CR2_DS_Msk;                   //clear bits
      SPI1->CR2 |= _VAL2FLD(SPI_CR2_DS, 0b0111);      //set bits
//    3.b Configure SSOE
      SPI1->CR2 |= _VAL2FLD(SPI_CR2_SSOE, 0b1);       //disable multimaster mode
//    3.e Configure FRXTH bit
      //SPI1->CR2 &= ~SPI_CR2_FRXTH_Msk;
      SPI1->CR2 |= _VAL2FLD(SPI_CR2_FRXTH,0b1);       //Generate RXNE whenever FIFO level >= 1 byte
// 6. Set Master Configuration
      SPI1->CR1 |= _VAL2FLD(SPI_CR1_MSTR, 0b1);
// 7. Enable SPI
      SPI1->CR1 |= _VAL2FLD(SPI_CR1_SPE, 0b1);
}
//

char spiSendReceive(char send){
 //While the TXE is full, wait for room to open up
  while(!_FLD2VAL(SPI_SR_TXE ,SPI1->SR)); //Wait
  *((volatile char *) (&SPI1->DR)) = send; //My soul is in pain

  //Wait until the RX register fills (there is data to receive)
  while(!_FLD2VAL(SPI_SR_RXNE ,SPI1->SR) ){}
  //return _FLD2VAL(SPI_DR_DR ,*((volatile char *)SPI1->DR));
  return _FLD2VAL(SPI_DR_DR ,SPI1->DR);  //Now that the RXFIFO has something in it, read the data

}
