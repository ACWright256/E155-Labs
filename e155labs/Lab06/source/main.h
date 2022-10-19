/*
File: main.h
Author: Alexa Wright, modified from Josh Brake
Email: acwright@hmc.edu, jbrake@hmc.edu
10/7/22
*/

#ifndef MAIN_H
#define MAIN_H

#include "STM32L432KC.h"
//ssm and ssi on
#define LED_PIN PB3 // LED pin for blinking on Port B pin 3
#define BUFF_LEN 32
#define CONFIG_BYTE 0b11101000
#endif // MAIN_H
uint16_t readTemp();