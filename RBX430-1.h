//******************************************************************************
//	RBX430-1.h
//
//	Author:			Paul Roper
//	Revision:		1.0		01/01/2012	RBX430-1 boards
//					1.1		11/08/2012	_430clock renumbered
//					1.2		04/15/2013	SYS_ERROR. SYS_ERRORS
//
//******************************************************************************
#ifndef RBX430_H_
#define RBX430_H_

#define REV_D	1

enum _430clock {_1MHZ, _8MHZ, _12MHZ, _16MHZ};
#define _1MHZx		0
#define _8MHZx		1
#define _12MHZx		2
#define _16MHZx		3

#define I2C_FSCL	100							// ~100kHz
//#define I2C_FSCL	200							// ~200kHz
//#define I2C_FSCL	400							// ~400kHz

//******************************************************************************
//	data types
typedef signed char int8;
typedef signed int int16;
typedef signed long int32;

typedef unsigned char uint8;
typedef unsigned int uint16;
typedef unsigned long uint32;

#define ON				1
#define OFF				0

#define TRUE			1
#define FALSE			0

//	system errors
enum SYS_ERRORS {	SYS_ERR_430init=1,		// 1  init error
					SYS_ERR_PRINT,			// 2  printf line too long
					SYS_ERR_LCD,			// 3  lcd error
					SYS_ERR_ADC,			// 4  adc error
					SYS_ERR_FRAM,			// 5  FRAM error
					SYS_ERR_XL345,			// 6  accelerometer error
					SYS_ERR_USCB_RX,		// 7  USCI timeout
					SYS_ERR_I2C_TO,			// 8  i2c timeout
					SYS_ERR_I2C_ACK,		// 9  i2c ACK timeout
					SYS_ERR_ISR,			// 10 un-initialized interrupt
					SYS_ERR_MALLOC,			// 11 malloc error
					SYS_ERR_EVENT,			// 12 event error

					SYS_ERR_ADC_TO,			// 13 adc timeout
					SYS_ERR_XL345_TO,		// 14 accelerometer timeout
					SYS_ERR_XL345ID			// 15 accelerometer ID error
				};

//******************************************************************************
//	Port 1 equates
#define SW_1		0x01			// P1.0
#define SW_2		0x02			// P1.1
#define SW_3		0x04			// P1.2
#define SW_4		0x08			// P1.3
#define ADXL345_INT	0x10			// P1.4
#define AUX_INT		0x20			// P1.5
#define SERVO_1		0x40			// P1.6
#define SERVO_2		0x80			// P1.7

//	Port 3 equates
#define LCD_A0		0x01			// P3.0
#define SDA			0x02			// P3.1 - i2c data
#define SCL			0x04			// P3.2 - i2c clock
#define LCD_RW		0x08			// P3.3
#define LED_GREEN	0x10			// P3.4
//					0x20			// P3.5
#define R_POT		0x40			// P3.6
#define L_POT		0x80			// P3.7

//	Port 4 equates
#define LED_1		0x01			// P4.0
#define LED_2		0x02			// P4.1
#define LED_3		0x04			// P4.2
#define LED_4		0x08			// P4.3
#define BK_LGT		0x10			// P4.4
#define SPKR		0x20			// P4.5
#define LED_RED		0x40			// P4.6
#define LCD_E		0x80			// P4.7

//******************************************************************************
//	LED's
#define LED_4_ON			P4OUT |= LED_4;
#define LED_4_OFF			P4OUT &= ~LED_4;
#define LED_4_TOGGLE		P4OUT ^= LED_4;

#define LED_3_ON			P4OUT |= LED_3;
#define LED_3_OFF			P4OUT &= ~LED_3;
#define LED_3_TOGGLE		P4OUT ^= LED_3;

#define LED_2_ON			P4OUT |= LED_2;
#define LED_2_OFF			P4OUT &= ~LED_2;
#define LED_2_TOGGLE		P4OUT ^= LED_2;

#define LED_1_ON			P4OUT |= LED_1;
#define LED_1_OFF			P4OUT &= ~LED_1;
#define LED_1_TOGGLE		P4OUT ^= LED_1;

#define LED_RED_ON			P4OUT |= LED_RED;
#define LED_RED_OFF			P4OUT &= ~LED_RED;
#define LED_RED_TOGGLE		P4OUT ^= LED_RED;

#define LED_GREEN_ON		P3OUT |= LED_GREEN;
#define LED_GREEN_OFF		P3OUT &= ~LED_GREEN;
#define LED_GREEN_TOGGLE	P3OUT ^= LED_GREEN;

//******************************************************************************
//
#define SPEAKER_ON			P4OUT |= SPKR;
#define SPEAKER_OFF			P4OUT &= ~SPKR;
#define SPEAKER_TOGGLE		P4OUT ^= SPKR;

#define BACKLIGHT_ON		P4OUT |= BK_LGT;	// turn on backlight
#define BACKLIGHT_OFF		P4OUT &= ~BK_LGT;	// turn off backlight
#define BACKLIGHT_TOGGLE	P4OUT ^= BK_LGT;	// toggle backlight

//******************************************************************************
//	LCD
//
#define	LCD_BL_H			P4OUT |= BK_LGT;
#define LCD_BL_L			P4OUT &= ~BK_LGT;

#define LCD_A0_H			P3OUT |= LCD_A0;
#define LCD_A0_L			P3OUT &= ~LCD_A0;

#define LCD_E_H				P4OUT |= LCD_E;
#define LCD_E_L				P4OUT &= ~LCD_E;

#define LCD_RW_H			P3OUT |= LCD_RW;
#define LCD_RW_L			P3OUT &= ~LCD_RW;

//#define LCD_CS_H			P2OUT |= 0x10;
//#define LCD_CS_L			P2OUT &= ~0x10;
//#define LCD_RS_H			P4OUT |= 0x40;
//#define LCD_RS_L			P4OUT &= ~0x40;

//******************************************************************************
//	RBX430 prototypes
//
uint8 RBX430_init(enum _430clock clock);
void ERROR2(int16 error);
void SYS_ERROR(enum SYS_ERRORS);
void wait(uint16 time);

//******************************************************************************
//	ADC Prototypes
//
#define RIGHT_POT			6
#define LEFT_POT			7
#define MSP430_TEMPERATURE	10
#define MSP430_VOLTAGE		11
#define RED_LED				15

uint8 ADC_init(void);
uint16 ADC_read(uint8 channel);

//******************************************************************************
#endif /*RBX430_H_*/
