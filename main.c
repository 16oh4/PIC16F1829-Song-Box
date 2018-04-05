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

#define _XTAL_FREQ 4000000.0    /*for 4mhz*/
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

int songnum = 0;
int song[x]={C, C, G, G, A, A, G, F, F, E, E, D, D, C}; //insert notes of song in array
int song2[x]={
    D,D,D,D,
    F,F,F,F,
    G,G,G,G,
    C,C
};
int song3[x] = {
    C,D,E,F,
    G,A,B,C2,
    C,D,E,F,
    G,A
};
int song4[16] = {
    G,G,D,R,
    C,C,D,E,
    D,D,F,R,
    R,R,F,F
};
int length4[16] = {
    1,1,2,2,
    1,1,2,2,
    2,2,1,1,
    2,2,1,1
};
int song5[] = {
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
int length5[] = {
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
int length[x]={2, 2, 2, 2, 1, 1, 1, 1, 4, 4, 4, 4, 3, 3};
int length3[x]={1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}; //relative length of each note
int i;

//Global Variables 
long PWM_freq = 1000;
int TMR2PRESCALE = 1;

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

void RA5Blink(void)
{
    RA5 ^= 0x01; // Toggles the LED to help with debugging
    __delay_ms(200); 
}
void checkButton()
{
    if(!RB5)
    {
        //TRISA5 = ~TRISA5; //Toggle using bitwise not
        songnum++;
    }
}
void playSong(int beat[], int time[], int notes)
{
    for(i = 0; i < notes; i++)
    {
        PWM_Duty(beat[i]); //play note
        //ROSEMARY UART HERE
        
        //T2CON = 0b00000100;
        for(int j=0; j < time[i]; j++)
        {
            __delay_ms(25);//for length specified
        }
//        PIR1 &= 0xFF;
        //T2CON = 0b00000100;
        PWM_Duty(0); //short silence in between notes
        __delay_ms(5);
        TMR2 = 0x0;
    }
}


void main()
{
    TRISC3 = 0;
    PWM_Initialize();
    PWM_Duty(1000); //volume
    
    do
    {
//        
        //CARLOS LCD HERE
        //C
        playSong(song5, length5, 38);
        
        
//        if(songnum=4)
//        {
//            i=1;
//        }

    }
    while(1);
  
}
