/*
File: main.c
Author: Alexa Wright, modified from Josh Brake
Email: acwright@hmc.edu, jbrake@hmc.edu
10/7/22
*/


#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"
#include <stdint.h>

/////////////////////////////////////////////////////////////////
// Provided Constants and Functions
/////////////////////////////////////////////////////////////////

//Defining the web page in two chunks: everything before the current time, and everything after the current time
char* webpageStart = "<!DOCTYPE html><html><head><title>AAAAAAAAAAAAAAAAAAAAAA</title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>SPI Purgatory</h1>";
char* ledStr = "<p>LED Control:</p><form action=\"ledon\"><input type=\"submit\" value=\"Turn the LED on!\"></form>\
	<form action=\"ledoff\"><input type=\"submit\" value=\"Turn the LED off!\"></form>";
char* tempBtnStr = "<form action=\"temprefresh\"><input type=\"submit\" value=\"Get Current Temperature\"></form>";

char* webpageEnd   = "</body></html>";

//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}
int updateLEDStatus(char request[])
{
	int led_status = 0;
	// The request has been received. now process to determine whether to turn the LED on or off
	if (inString(request, "ledoff")==1) {
		digitalWrite(LED_PIN, PIO_LOW);
		led_status = 0;
	}
	else if (inString(request, "ledon")==1) {
		digitalWrite(LED_PIN, PIO_HIGH);
		led_status = 1;
	}

}
//Simplified way to pull chip select high, write the address and config, and pull it low.
//Discards any received bytes
void writeBits(char addr, char bit){
  digitalWrite(PA8, PIO_HIGH);
  spiSendReceive(addr);
  spiSendReceive(bit);
  digitalWrite(PA8, PIO_LOW);
}
//Simplified way to pull chip select high, write garbage, and pull it low.
//Returns received bytes
char readBits(char addr){
  char bitRead;
  digitalWrite(PA8, PIO_HIGH);
  spiSendReceive(addr);
  bitRead=spiSendReceive(addr);
  digitalWrite(PA8, PIO_LOW);
  return bitRead;
}



/////////////////////////////////////////////////////////////////
// Solution Functions
/////////////////////////////////////////////////////////////////


int main(void) {
  configureFlash();
  configureClock();

  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);
  
  RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
  initTIM(TIM15);
  
  USART_TypeDef * USART = initUSART(USART1_ID, 125000);
//------------------------- SPI INITIALIZATION CODE -------------------------// 
  initSPI(0b111, 0, 1);
  writeBits(0x80, CONFIG_BYTE); //configure temperature sensor
//----------------------- END SPI INITIALIZATION CODE -----------------------// 

  pinMode(LED_PIN, GPIO_OUTPUT);
  while(1) {
    //Wait for ESP8266 to send a request.
    //Requests take the form of '/REQ:<tag>\n', with TAG begin <= 10 characters.
    //Therefore the request[] array must be able to contain 18 characters.
    
//------------------------- TEMPERATURE READING CODE -------------------------//   
    uint16_t tempVal = readTemp();  //grab the temperature as a uint16 (with LSB flipped if needed)
    
    //NOTE: This has a bug that I don't want to fix. Reads out positive values for negative temperature readings. Somebody didn't use a signed integer (it was me)
    //ALSO: My brain is kind of full of wet cat food because there is a way to print floats if I had just imported another piece of code.
    int integerBits = (tempVal>>8);
    uint16_t decimalBits = tempVal&0x00FF;
    //gets the decimal bits in the form of an int (ie, 0.125 becomes 125).
    float dec= (float)((float)decimalBits/16.0);
    int dig = integerBits;
    if(integerBits>>16){
      dec=(dec-1)*-1;
      dig+=1;
    }
    int decimal = 1000*dec;
//----------------------- END TEMPERATURE READING CODE -----------------------//     

    // Receive web request from the ESP
    char request[BUFF_LEN] = "                  "; // initialize to known value
    int charIndex = 0;
  
    // Keep going until you get end of line character
    while(inString(request, "\n") == -1) {
      // Wait for a complete request to be transmitted before processing 
      //TODO conflict here with UART and SPI?
      while(!(USART->ISR & USART_ISR_RXNE));
      request[charIndex++] = readChar(USART);
    }
  
    // Update string with current LED state 
    int led_status = updateLEDStatus(request);
    


    char ledStatusStr[20];
    if (led_status == 1)
      sprintf(ledStatusStr,"LED is on!");
    else if (led_status == 0)
      sprintf(ledStatusStr,"LED is off!");

//------------------------- UPDATE TEMPERATURE STRING -------------------------//   
    char tempStatusStr[60];
    sprintf(tempStatusStr, "TEMPERATURE: %d.%d Degrees C", dig, decimal);
    char debugStatusStr[60];
    sprintf(debugStatusStr, "Cool Hex String: %x.%x and %x", integerBits, decimalBits, tempVal);
//----------------------- END UPDATE TEMPERATURE STRING -----------------------//   

    // finally, transmit the webpage over UART
    sendString(USART, webpageStart); // webpage header code
    sendString(USART, ledStr); // button for controlling LED

    sendString(USART, "<h2>LED Status</h2>");

    sendString(USART, "<p>");
    sendString(USART, ledStatusStr);
    sendString(USART, "</p>");

    sendString(USART, "<h2>The Source of My Suffering</h2>");
    sendString(USART, tempBtnStr);

//------------------------- UPDATE TEMPERATURE DISPLAY -------------------------//  
    sendString(USART, "<p>");
    sendString(USART, tempStatusStr);
    sendString(USART, "</p>");

    sendString(USART, "<p>");
    sendString(USART, debugStatusStr);
    sendString(USART, "</p>");
//----------------------- END UPDATE TEMPERATURE DISPLAY -----------------------//  

    sendString(USART, webpageEnd);
  }
}


//Seems kinda silly, but I wanna avoid arrays 
uint16_t readTemp(){
  uint16_t returnVal = (uint16_t)0;
  char MSB;
  char LSB;
  writeBits(0x80, CONFIG_BYTE); 
  //char Config=readBit(0x00);
  MSB=readBits(0x02);
  LSB=readBits(0x01)>>4; //discard the 0
  returnVal |= ((uint16_t)MSB)<<8;  //stitch it together
  returnVal |= (uint16_t)LSB;
  return returnVal;
}


/*
/////// Old Main function for testing SPI /////// 

int main(void) {
  configureFlash();
  configureClock();

  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);
  
  RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
  initTIM(TIM15);

  initSPI(0b111, 0, 1);
  writeBit(0x80, 0b11110001);


  while(1) {
    char MSB;
    char LSB;
    
    //readTemp();
    MSB=readBit(0x02);
    LSB=readBit(0x01);
    delay_millis(TIM15, 10);
    }
}
*/