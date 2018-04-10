// CONFIG1
#pragma config FOSC = INTOSC    // Oscillator Selection (INTOSC oscillator: I/O function on CLKIN pin)
#pragma config WDTE = OFF       // Watchdog Timer Enable (WDT disabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable (PWRT disabled)
#pragma config MCLRE = ON       // MCLR Pin Function Select (MCLR/VPP pin function is MCLR)
#pragma config CP = OFF         // Flash Program Memory Code Protection (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Memory Code Protection (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown-out Reset Enable (Brown-out Reset disabled)
#pragma config CLKOUTEN = OFF   // Clock Out Enable (CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin)
#pragma config IESO = OFF       // Internal/External Switchover (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enable (Fail-Safe Clock Monitor is disabled)

// CONFIG2
#pragma config WRT = OFF        // Flash Memory Self-Write Protection (Write protection off)
#pragma config PLLEN = OFF      // PLL Enable (4x PLL disabled)
#pragma config STVREN = ON      // Stack Overflow/Underflow Reset Enable (Stack Overflow or Underflow will cause a Reset)
#pragma config BORV = LO        // Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), low trip point selected.)
#pragma config LVP = OFF        // Low-Voltage Programming Enable (High-voltage on MCLR/VPP must be used for programming)

#include <stdio.h>
#include <stdlib.h>
#include <xc.h>
#include <string.h>
#include "i2c.h"
#include "i2c_LCD.h"

#define _XTAL_FREQ 4000000.0    /*for 4mhz*/
#define I2C_SLAVE 0x27	/* was 1E Channel of i2c slave depends on soldering on back of board*/
#define C 255 
#define D 227
#define E 204
#define F 191
#define G 170
#define A 153
#define B 136
#define R 0
#define C2 127
#define x 14

// Prototypes from Carlos
//void I2C_LCD_Command(unsigned char,unsigned char);
//void I2C_LCD_SWrite(unsigned char,unsigned char *, char);
//void I2C_LCD_Init(unsigned char);
//void I2C_LCD_Pos(unsigned char,unsigned char);
//unsigned char I2C_LCD_Busy(unsigned char);

void led (void);
void checkButton();
void playSong(int beat[], int time[], int notes);
const char * getNote(int f);
void dispLCD(char * msg, int loc, int size);
void clearLCD(int row);
void clearBuffers(int row);

//Global Variables 
long PWM_freq = 1000;
int TMR2PRESCALE = 1;

//for song
int i=0, songnum=0;
int pressed = 0;
int lcdflag = 0;
//for LCD
unsigned char  Sout[16];
unsigned char  Soutl[16];
unsigned char * Sptr;
int z=0, DUMMY=0;

unsigned char dispnote[16];
//SONGS
int song[]= {
    C, C, G, G, 
    A, A, G, F, 
    F, E, E, D, 
    D, C, C, C
}; //insert notes of song in array
int len[] = {
    1,1,1,1,
    1,1,1,1,
    1,1,1,1,
    1,1,1,1
};
//int song4[16] = {
//    G,G,D,R,
//    C,C,D,E,
//    D,D,F,R,
//    R,R,F,F
//};
//int len4[16] = {
//    1,1,2,2,
//    1,1,2,2,
//    2,2,1,1,
//    2,2,1,1
//};
int song4[16] = {
    G,C,C,C,
    B,C,C,C,
    B,C,C,C,
    B,C,C,C,
};
int len4[16] = {
    3,3,3,3,
    3,3,3,3,
    3,3,3,3,
    3,3,3,3,
};
int song5[38] = {
    C,C,
        D,E,
    D,D,F,
    
    R,
        D,E,
    D,D,C,
    
    R,
    
        F,F,
    G,G,D,
    
    C,
        F,F,
    G,G,D,
    
    R,
    
        D,D,
    G,G,F,
    
    C,
        D,D,
    G,G,F,R
};
int len5[38] = {
    1,1,
        2,2,
    2,2,1,
    
    1,
        
        2,2,
    2,2,1,
    
    1,
    
        2,2,
    2,2,1,
    
    1,
        2,2,
    2,2,1,
    
    1,
    
        2,2,
    2,2,1,
    
    1,
    
        2,2,
    2,2,1,1
};
int song6[36] = {
    D,E,G,R,
    D,E,G,R,
    D,E,G,R,
    
    D,E,F,R,
    D,E,F,R,
    D,E,F,R,
    
    F,E,D,R,
    F,E,D,R,
    F,E,D,R
    
};
int len6[36] = {
    1,1,1,1,
    1,1,1,1,
    1,1,1,1,
    
    1,1,1,1,
    1,1,1,1,
    1,1,1,1,
    
    1,1,1,1,
    1,1,1,1,
    1,1,1,1
};
int song7[] = {
    E,E,E,R,
    E,E,F,R,
    E,E,G,G,
    G,G,F,R,
    
    
};
int len7[] = {
    1,1,2,1,
    1,1,2,1,
    1,1,2,1,
    1,1,2,1,
    
    
};
//int* songs[3] =       {song,    song4,  song5};
//int* songlengths[3] = {len,    len4,   len5};
//const char* currentsong[3] = {"SONG1", "SONG2" , "SONG3"};


void PWM_Initialize() 
{  
//    APFCON1 = 0x01;  //Set PWM to alternative PIN RA5 (HELLO WORLD LED)
    APFCON1 = 0x00; //Set PWM to RC3
    PR2 = 0xFF;  //PR2 value needed for 1000Hz frequency
    CCP2CON = 0x0C; //Enable pwm mode pg.236
    //CCP2CON = 0b01001100;
    CCPR2L = 0x00;  //Set initial dutycycle to 0
    CCPTMRS = 0x00; //Set TMR2 to work with PWM
    PIR1 &= 0xFF;  //Clear TMR 2 int flag
    T2CON = 0b00000100; // 1:1 postscaler 1:1 prescaler on timer 2 pg.203
}


void PWM_Duty(unsigned int duty)
{
    if(duty<1023)
    {
      duty = ((float)duty/1023)*(_XTAL_FREQ/(PWM_freq*TMR2PRESCALE)); 
      //duty = ((float)duty/1023)*(_XTAL_FREQ/(PWM_freq*TMR2PRESCALE)); 
      DC2B0 = duty & 1; //Store the 0th bit
      DC2B1 = duty & 2; //Store the 1st bit
      CCPR2L = duty>>2;// Store the remaining 8 bit //shifted right to delete lower 2 bits
    }
}


void led(void)
{
    RA5 ^= 0x01; // Toggles the LED to help with debugging 
}
void checkButton()
{
    while(!RB5)
    {
            led();
            pressed = 1;
            songnum++;
            if(songnum == 5) songnum = 0;
            
            //if button pressed long enough, remove printing of NOTES
            
            __delay_ms(250);
            if(!RB5)
            {
                lcdflag = !lcdflag;
                clearLCD(0);
                if(lcdflag)
                {
                    dispLCD("Notes OFF", 0, 9);
                }
                else
                {
                    dispLCD("Notes ON", 0, 8);
                }
                
            }
            
    }
        
}
void playSong(int beat[], int time[], int notes)
{
//    char * note;
    while(pressed == 0)
    {
        
    for(i = 0; i < notes; i++)
    {
        if(pressed == 1) break; //if button pressed skip song
        
        checkButton(); //check if button is pressed
        
        PWM_Duty(beat[i]); //play note
//        note = getNote(beat[i]);
        if(lcdflag==0) dispLCD(getNote(beat[i]), 1, (i%16)+1);
        
        for(int j=0; j < time[i]; j++) //plays note for specified length
        {
            __delay_ms(25);
        }
        
        PWM_Duty(0); //short silence in between notes
        //__delay_ms(5);
        TMR2 = 0x0; //reset tmr2
    }
    }
}

const char * getNote(int f)
{
    switch(f)
    {
        case 255:
            return "C";
        case 227:
            return "D";
        case 204:
            return "E";
        case 191:
            return "F";
        case 170:
            return "G";
        case 153:
            return "A";
        case 136:
            return "B";
        case 0:
            return "R";
        default:
            return " ";
    }
}

void dispLCD(char * msg, int loc, int size)
{
    if(size==16)
    {
        clearLCD(2);
    }
    if(loc == 0)
    {
        I2C_LCD_Pos(I2C_SLAVE, 0x00);
        sprintf(Sout, msg, 0);
        I2C_LCD_SWrite(I2C_SLAVE, Sout, size);
    }
    else
    {
        I2C_LCD_Pos(I2C_SLAVE, 0x40+(size-1));
        sprintf(Soutl, msg, 0);
        I2C_LCD_SWrite(I2C_SLAVE, Soutl, size);
    }
}
void clearLCD(int row)
{
    switch(row)
    {
        case 0: //erase screen
            I2C_LCD_Command(I2C_SLAVE, 0x01);
            break;
        case 1: //erase line 1
            I2C_LCD_Pos(I2C_SLAVE, 0x00);
            clearBuffers(1); //clear line 1 buffer
            I2C_LCD_SWrite(I2C_SLAVE, Sout, 16);
            break;
        case 2: //erase line 2
            I2C_LCD_Pos(I2C_SLAVE, 0x40);
            clearBuffers(2); //clear line 2 buffer
            I2C_LCD_SWrite(I2C_SLAVE, Soutl, 16);
            break;
        default:
            break;
    }
    
}

void clearBuffers(int row)
{
    switch(row)
    {
        case 1:
            sprintf(Sout, "", 0);
            break;
        case 2:
            sprintf(Soutl, "", 0);
            break;
        default:
            break;
    }
      
}

void main()
{
    
    Sptr = Sout; //for lcd
    
    TRISA5 = 0; //output LED
    PORTA = 0x00; //reset led
    
    TRISC3 = 0; //output PWM
    TRISB5 = 1; //input button
    ANSB5 = 0; //low for digital IN
    
    PWM_Initialize();
    
    
    i2c_Init();				// Start I2C as Master 100KH
    I2C_LCD_Init(I2C_SLAVE); //pass I2C_SLAVE to the init function to create an instance
    clearLCD(0);
    
    do
    {
        switch(songnum)
        {
            case 4:
                clearLCD(0);
                pressed = 0;
                RA5 = 0;
                dispLCD("Song #1", 0, 7);
                playSong(song, len, 16);
                break;
            case 1:
                clearLCD(0);
                pressed = 0;
                RA5 = 0;
                dispLCD("Song #6", 0, 7);
                playSong(song6, len6, 36);
                break;
            case 2:
                clearLCD(0);
                pressed = 0;
                RA5 = 0;
                dispLCD("Song #3", 0, 7);
                playSong(song5, len5, 38);
                break;
            case 3:
                clearLCD(0);
                pressed = 0;
                RA5 = 0;
                dispLCD("Metronome 92 BPM", 0, 16);
                playSong(song4, len4, 16);
                break;
            case 0:
                clearLCD(0);
                pressed = 0;
                RA5 = 0;
                dispLCD("Song #7", 0, 7);
                playSong(song7, len7, 12);
                break;
            default:
                clearLCD(0);
                pressed = 0;
                RA5 = 0;
                dispLCD("Song #1", 0, 7);
                playSong(song, len, 16);
                break;
        }
        
        

    }
    while(1);
}