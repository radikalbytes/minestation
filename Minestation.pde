#include <TimerOne.h>

/****************************************************/
/* Example Program For LCD6610 (NPX)                */
/* MCU      : Arduino Nano                          */
/* By       : Gravitech                             */
/* Function : Demo Interface LCD6610                */
/*            (Philips controller)                  */ 
/****************************************************/
/* Interface LCD6610 to Arduino Nano                */
/*    Nano  --> LCD6610                             */
/*    D2    --> BL                                  */
/*    D3    --> #CS                                 */
/*    D4    --> SCLK                                */
/*    D5    --> SDATA                               */
/*    D6    --> #RESEET                             */
/*    +5V   --> VCC,VBL                             */
/*    GND   --> GND                                 */
/****************************************************/

#include <avr/pgmspace.h>
#include "foto.h"
#include "fonts.h"
#include <TimerOne.h>

/* Define LCD6610 PinIO interface */
//#define BL    2      // Digital 2 --> BL
#define CS    10 //3     // Digital 3 --> #CS
#define CLK   13 // 4      // Digital 4 --> SCLK
#define SDA   11 // 5      // Digital 5 --> SDATA
#define RESET 9 // 6      // Digital 6 --> #RESET

/* Start of Define Philips(NXP):PCF8833 Header */ 
#define NOP 0x00 	// nop
#define SWRESET  0x01 	// software reset
#define BSTROFF  0x02 	// booster voltage OFF
#define BSTRON   0x03 	// booster voltage ON
#define RDDIDIF  0x04 	// read display identification
#define RDDST    0x09 	// read display status
#define SLEEPIN  0x10 	// sleep in
#define SLEEPOUT 0x11 	// sleep out
#define PTLON    0x12 	// partial display mode
#define NORON    0x13 	// display normal mode
#define INVOFF   0x20 	// inversion OFF
#define INVON    0x21 	// inversion ON
#define DALO     0x22 	// all pixel OFF
#define DAL      0x23 	// all pixel ON
#define SETCON   0x25 	// write contrast
#define DISPOFF  0x28 	// display OFF
#define DISPON   0x29 	// display ON
#define CASET    0x2A 	// column address set
#define PASET    0x2B 	// page address set
#define RAMWR    0x2C 	// memory write
#define RGBSET   0x2D 	// colour set
#define PTLAR    0x30 	// partial area
#define VSCRDEF  0x33 	// vertical scrolling definition
#define TEOFF    0x34 	// test mode
#define TEON     0x35 	// test mode
#define MADCTL   0x36 	// memory access control
#define SEP      0x37 	// vertical scrolling start address
#define IDMOFF   0x38 	// idle mode OFF
#define IDMON    0x39 	// idle mode ON
#define COLMOD   0x3A 	// interface pixel format
#define SETVOP   0xB0 	// set Vop
#define BRS      0xB4 	// bottom row swap
#define TRS      0xB6 	// top row swap
#define DISCTR   0xB9 	// display control
//#define DAOR   0xBA 	// data order(DOR)
#define TCDFE    0xBD 	// enable/disable DF temperature compensation
#define TCVOPE   0xBF 	// enable/disable Vop temp comp
#define EC       0xC0 	// internal or external oscillator
#define SETMUL   0xC2 	// set multiplication factor
#define TCVOPAB  0xC3 	// set TCVOP slopes A and B
#define TCVOPCD  0xC4 	// set TCVOP slopes c and d
#define TCDF     0xC5 	// set divider frequency
#define DF8COLOR 0xC6 	// set divider frequency 8-color mode
#define SETBS    0xC7 	// set bias system
#define RDTEMP   0xC8 	// temperature read back
#define NLI      0xC9 	// n-line inversion
#define RDID1    0xDA 	// read ID1
#define RDID2    0xDB 	// read ID2
#define RDID3    0xDC 	// read ID3

#ifdef PB1
#define LCD_CS(x)           PORTB= (x)? (PORTB|(1<<PB2)) : (PORTB&~(1<<PB2))
#define LCD_CLK(x)          PORTB= (x)? (PORTB|(1<<PB5)) : (PORTB&~(1<<PB5))
#define LCD_DATA(x)         PORTB= (x)? (PORTB|(1<<PB3)) : (PORTB&~(1<<PB3))
#define LCD_RESET(x)        PORTB= (x)? (PORTB|(1<<PB1)) : (PORTB&~(1<<PB1))
#define LCD_levelLight(x)    PORTB= (x)? (PORTB|(1<<PB0)) : (PORTB&~(1<<PB0))
#else
#define LCD_CS(x)           PORTB= (x)? (PORTB|(1<<PORTB2)) : (PORTB&~(1<<PORTB2))
#define LCD_CLK(x)          PORTB= (x)? (PORTB|(1<<PORTB5)) : (PORTB&~(1<<PORTB5))
#define LCD_DATA(x)         PORTB= (x)? (PORTB|(1<<PORTB3)) : (PORTB&~(1<<PORTB3))
#define LCD_RESET(x)        PORTB= (x)? (PORTB|(1<<PORTB1)) : (PORTB&~(1<<PORTB1))
#define LCD_levelLight(x)    PORTB= (x)? (PORTB|(1<<PORTB0)) : (PORTB&~(1<<PORTB0))
#endif

#define LCDCommand      0
#define LCDData         1

// Font sizes
#define SMALL 0
#define MEDIUM 1
#define LARGE 2

// Booleans
#define NOFILL 0
#define FILL 1

// 12-bit color definitions
// Mode color BGR ¿?¿ I don't know but works
#define WHITE 0xFFF
#define BLACK 0x000
#define RED 0x00F //0xF00
#define GREEN 0x0F0
#define BLUE 0xF00 //0x00F
#define CYAN2 0xF70
#define CYAN 0xFF0 //0x0FF
#define MAGENTA 0xF0F
#define YELLOW 0x0FF //0xFF0
#define BROWN 0x22B //0xB22
#define ORANGE 0x0AF //0xFA0
#define PINK 0xA6F //0xF6A
#define GREY 0xCCC

#define cbi(reg, bit) (reg&=~(1<<bit))
#define sbi(reg, bit) (reg|= (1<<bit))

#define CS0 cbi(PORTD,CS);
#define CS1 sbi(PORTD,CS);
#define CLK0 cbi(PORTD,CLK);
#define CLK1 sbi(PORTD,CLK);
#define SDA0 cbi(PORTD,SDA);
#define SDA1 sbi(PORTD,SDA);
#define RESET0 cbi(PORTD,RESET);
#define RESET1 sbi(PORTD,RESET);
#define BL0 cbi(PORTD,BL);
#define BL1 sbi(PORTD,BL);
/* End of Define Philips(NXP):PCF8833 Header */ 


// constants will don't change
const int contrastplus = 2;     // the number of the pushbutton contrastplus pin
const int contrastminus = 3;    // the number of the pushbutton contrastminus pin

// variables will change:
int contrastplusState = 0;      // variable for reading the pushbutton contrastplus
int contrastminusState = 0;     // variable for reading the pushbutton contrastminus
int contrast_value;          // contrast LCD value

#define long_buffer 128
#define inicio_trama '@'
#define fin_trama '#'
#define BOUNCE_DURATION 50
volatile unsigned long bounceTime=0;
char buffer[long_buffer+1]; // Allocate some space for the string
char inChar=-1; // Where to store the character read
byte index = 0; // Index into array; where to store the character
char Time_str[10]={"00:00"};
char Rain_time_str[10]={0,0,0,0,0,0,0,0,0,0};
char Thunder_time_str[10]={0,0,0,0,0,0,0,0,0,0};
char dist_to_spawn_str[10]={0,0,0,0,0,0,0,0,0,0};
char PosX_str[8]={"0.000"};
char PosY_str[8]={"0.000"};
char PosZ_str[8]={"0.000"};
char Hour_str[3]={0,0,0};
char Minute_str[3]={0,0,0};
char Day_str[3]={0,0,0};
char Month_str[3]={0,0,0};
char Year_str[5]={0,0,0,0,0};
char  Thundering_str=0x00;
char  Raining_str=0x00;
char  World_name[16]={"Minestation 1.0"};
double Time=0;
double Rain_time=0;
double Thunder_time=0;
short  Thundering=0;
short  Raining=0;
short  Sun=0;
short  Moon=0;
//float PosX=0.0;
//float PosY=0.0;
//float PosZ=0.0;
float dist_to_spawn=0.0;
int   Hour=0;
int   Minute=0;
int   Day=1;
int   Month=1;
int   Year=0;
int   modo=0;
int   stringLen=15;
int   PosXSun=64;
int   PosYSun=15;
int   hourTmp;
int   minuteTmp;
int   dayTmp;
int   levelLight=5;


/*************************************************************/
/*            Function prototypes                            */
/*************************************************************/
void sendCMD(byte);
void sendData(byte);
void shiftBits(byte);
void lcd_init();
void draw_color_bar();
void lcd_clear(uint16_t, byte, byte, byte, byte);
void LCDPutStr(char*, int, int, int, int, int);
void LCDPutChar(char, int, int, int, int, int);
void LCDSetLine(int, int, int, int, int);
void LCDSetRect(int, int, int, int, unsigned char fill, int);
void LCDSetCircle(int, int, int, int);
void LCDSetPixel(byte, byte, int);
void LCDSetXY(byte, byte);
void calculatePositionSun();
void drawStormIcon(byte,byte);
void drawRainIcon(byte, byte);
void calculateTime(long);
void drawCloud1(int,int);
void drawCloud2(int,int);
void drawSunMoon(int,int,int);
void calculatePosSunMoon();
void putBackground();

/*************************************************************/
/*            Main Code Start here                           */
/*************************************************************/
void setup() 
{ 
  contrast_value=56;  
  // initialize the pushbutton pins as inputs:
  pinMode(contrastplus, INPUT);
  pinMode(contrastminus, INPUT);
  DDRB=0x2F;
  DDRB=0x2F;
 // DDRD |= B01111100;   // Set SPI pins as output 
 // PORTD |= B01111100;  // Set SPI pins HIGH
 Serial.begin(9600);
 Serial.write("Minestation Arduino v0.0.1");
  
  lcd_init();
  delay(500);
  lcd_contrast(contrast_value);
  attachInterrupt(0, contrastPlus, RISING);
  attachInterrupt(1, contrastMinus, RISING);
  Timer1.initialize(100000);
  draw_color_bar(); 
 delay(500);
// lcd_clear(BLACK,0,0,131,131);
/* 
 LCDPutStr("Probando...",            5, 40, LARGE,  YELLOW,  BLACK);
 LCDPutStr("132X132",           20, 40, LARGE,  CYAN,    BLACK);
 LCDPutStr("Color Graphic LCD", 37, 17, SMALL,  CYAN,    BLACK);
 LCDPutStr("WWW.GRAVITECH.US",  50,  2, LARGE,  RED,     WHITE);
 LCDPutStr("SMALL GREEN",       70, 37, SMALL,  GREEN,   BLACK);
 LCDPutStr("MEDIUM BLUE",       81, 25, MEDIUM, BLUE,    BLACK);
 LCDPutStr("LARGE PINK",        90, 27, LARGE,  PINK,    BLACK);
 LCDPutStr("MEDIUM MAGENTA",   107, 12, MEDIUM, MAGENTA, BLACK);
 LCDPutStr("SMALL ORANGE",     119, 30, SMALL,  ORANGE,  BLACK);

 delay(500);
 lcd_clear(BLUE,0,0,131,131);
 
 LCDSetLine(120, 10, 120, 50, YELLOW);     // Draw Line Create Rectangle
 LCDSetLine(120, 50, 80, 50, YELLOW);
 LCDSetLine(80, 50, 80, 10, YELLOW);
 LCDSetLine(80, 10, 120, 10, YELLOW);
 LCDSetLine(120, 85, 80, 105, YELLOW);     // Draw Line Create X
 LCDSetLine(80, 85, 120, 105, YELLOW);    
 LCDSetCircle(62, 65, 20, RED);            // Draw Circle 
 LCDSetRect(5, 5, 125, 125, NOFILL, BLUE); // Draw box with no fill
 LCDSetRect(10, 10, 40, 40, FILL, PINK);   // Draw box with fill
 LCDSetRect(10, 90, 40, 120, FILL, GREEN);
 
 delay(2000);
 lcd_clear(BLUE,0,0,131,131);
 delay(2000);*/
   lcd_clear(BLACK,0,0,131,131);
   lcd_clear(WHITE,116,0,131,131);
  
  LCDSetLine(0, 65,115, 65, WHITE); // Vertical division screen
  LCDSetLine(0, 66,115, 66, WHITE); 
  LCDSetLine(17,65,17, 131, WHITE); // Clock division
  LCDSetLine(18,65,18, 131, WHITE); 
  LCDSetLine(37,65,37, 131, WHITE); // Date division
  LCDSetLine(38,65,38, 131, WHITE); 
  // Draw Atrezzo clock
  LCDSetCircle(8, 77, 7, GREEN);            // Draw Circle 
  LCDSetCircle(8, 77, 6, GREEN);            
  LCDSetLine(8, 77, 5, 77, GREEN);   // Draw hands clock
  LCDSetLine(8, 78, 5, 78, GREEN); 
  LCDSetLine(8, 77, 9, 80, GREEN); 
  LCDSetLine(8, 78, 9, 81, GREEN);
  //Draw Atrezzo calendar
  LCDSetRect(34, 69, 20, 86, NOFILL, RED);   // Draw box 
  LCDSetRect(35, 70, 21, 87, NOFILL, RED);   // Draw box  
  LCDSetPixel(35,87,BLACK);
  LCDSetPixel(20,69,BLACK);
  LCDSetLine(19, 75, 23, 75, RED);
  LCDSetLine(19, 74, 23, 74, RED);
  LCDSetLine(19, 80, 23, 80, RED);
  LCDSetLine(19, 81, 23, 81, RED);
  
  
   
  LCDSetLine(73,65,73, 131, WHITE); // Position division
  LCDSetLine(74,65,74, 131, WHITE); 
   
  LCDSetLine(0,130,130, 130, WHITE); // Date division
  LCDSetLine(0,129,130,129, WHITE); 
  
  putBackground();
} 
 
void loop() 
{
  int  px,py;
  int  dd,ee;
  char  str_tmp[16];
  int xxx,yyy;

  
  //Put World Name centered
  px=(132-(stringLen*8))/2;
  lcd_clear(WHITE,116,0,131,131);
  LCDPutStr(World_name,       116, px, LARGE,  BLACK,  WHITE);
  
  //Put Time
  if (Hour==24) Hour=0;
  sprintf(str_tmp,"%02d:%02d",Hour,Minute);
  LCDPutStr(str_tmp, 5, 95, SMALL,WHITE,BLACK);
  
  //Put Date 
  sprintf(str_tmp,"%02d", Day);
  LCDPutStr(str_tmp, 25,73,SMALL,RED,BLACK);  
  sprintf(str_tmp,"%02d/%02d", Month,Year);
  LCDPutStr(str_tmp, 25,95,SMALL,WHITE,BLACK);  
  
  //Put coordenates
  LCDPutStr("X: ",            43, 73, SMALL,  WHITE,  BLACK);
  LCDPutStr(PosX_str,         43, 86, SMALL,  WHITE,  BLACK);
  LCDPutStr("Y: ",            53, 73, SMALL, WHITE,  BLACK);
  LCDPutStr(PosY_str,         53, 86, SMALL,  WHITE,  BLACK);
  LCDPutStr("Z: ",            63, 73, SMALL, WHITE,  BLACK);
  LCDPutStr(PosZ_str,         63, 86, SMALL,  WHITE,  BLACK);  //  LCDPutStr("6x8  How'r'u?",            24, 1, SMALL,  GREEN,  BLACK);
  
  xxx=PosXSun;
  yyy=PosYSun;
  calculatePosSunMoon();
  if ((xxx!=PosXSun) | (yyy!=PosYSun)){
    if ((Hour<21) & (Hour>6)) drawSunMoon(PosXSun,PosYSun,YELLOW);
    else drawSunMoon(PosXSun,PosYSun,WHITE);
  }
 // drawCloud1(-3,12);
 // drawCloud2(23,35);
  drawStormIcon(68,77);
  if (Raining==1) {
     lcd_clear(BLACK,96,68,110,83);
     drawRainIcon(68,96);
  }
  else {
     lcd_clear(BLACK,96,68,110,83);
     lcd_clear(YELLOW,99,71,109,81);
  }
  //Put Rain time
  calculateTime(Rain_time);
  if(dayTmp>0)  sprintf(str_tmp,"%d days",dayTmp);
  else {
     if (hourTmp==24) hourTmp=0;  
     sprintf(str_tmp,"%02d:%02d  ",hourTmp,minuteTmp);
  }
  LCDPutStr(str_tmp, 102, 86, SMALL,WHITE,BLACK);
  //Put thunder time
  calculateTime(Thunder_time);
  if(dayTmp>0)  sprintf(str_tmp,"%d days",dayTmp);
  else {
     if (hourTmp==24) hourTmp=0;  
     sprintf(str_tmp,"%02d:%02d  ",hourTmp,minuteTmp);
  }
  if(Raining==1)
     LCDPutStr(str_tmp, 82, 86, SMALL,WHITE,BLACK);
  else 
     LCDPutStr(" Clear ", 82, 86, SMALL,WHITE,BLACK);
     
  recibe_trama();
  command_process();
 
 
} 




/*************************************************************/
/*            Function definitions                           */
/*************************************************************/
void putBackground(){
  lcd_clear(0xF30,0,0,114,64);
  bitmap(1,54,0);  //Put world
}

void calculatePositionSun(){
  PosXSun=0;
  PosYSun=0;
  
}

void Inicia_buffer(){
   memset(buffer, '\0', 128);
}

void contrastPlus(){
   long dd,ddd;
   static long lasttime;
   if (millis()<lasttime) lasttime=millis();
   if((lasttime+BOUNCE_DURATION)>millis()) return;
   lasttime=millis();
   contrast_value++;
   lcd_contrast(contrast_value); 
}

void contrastMinus(){
   long dd,ddd;
   static long lasttime;
   if (millis()<lasttime) lasttime=millis();
   if((lasttime+BOUNCE_DURATION)>millis()) return;
   lasttime=millis();
   contrast_value--;
   lcd_contrast(contrast_value); 
}

void drawSunMoon(int pX, int pY,int color){
   int backColor=0xF30;
   switch (levelLight){
      case 0:
        backColor=0xF30;
      break;
      case 1:
        backColor=0xE20;
      break;
      case 2:
        backColor=0xD10;
      break;
      case 3:
        backColor=0xC00;
      break;
      case 4:
        backColor=0xB00;
      break;
      case 5:
        backColor=0xA00;
      break;  
   }
   lcd_clear(backColor,0,0,53,64);
   if (pX<55) LCDSetRect(pY, pX, pY+10, pX+10, FILL, color);   // Draw sun  
   else LCDSetRect(pY, pX, pY+10, pX+64-pX, FILL, color);   
}

void drawCloud1(int pX,int pY){
  // Part white in cloud1
   unsigned char linW [64] PROGMEM ={ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8, 9,
                                      2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 5, 5, 5, 5, 5, 5, 5, 6, 7, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9};
  //Part grey in cloud1           
   unsigned char linG [64] PROGMEM ={ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7,
                                      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8};  
   byte fin=32;    
   if((pX+32)>64) fin=64-pX;
   for (int o=0 ; o<fin ; o++){
      LCDSetLine(pY+linW[o],pX,pY+linW[o+32], pX, WHITE); 
      LCDSetLine(pY+linG[o],pX,pY+linG[o+32], pX, GREY); 
      if(o==10){
         LCDSetLine(pY+7,pX,pY+9, pX, WHITE);   
         LCDSetPixel(pY+6,pX,GREY);
      }
      if(o==11){
         LCDSetLine(pY+8,pX,pY+9, pX, WHITE);   
         LCDSetLine(pY+6,pX,pY+7, pX, GREY);   
      }
      if(o==12){
         LCDSetPixel(pY+9,pX,WHITE);
         LCDSetLine(pY+7,pX,pY+8, pX, GREY);   
      }
      pX++;
   } 
}

void drawCloud2(int pX,int pY){
  // Part white in cloud1
   unsigned char linW [88] PROGMEM ={ 2, 2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 2, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,
                                      2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15};
  //Part grey in cloud1           
   unsigned char linG [88] PROGMEM ={ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,
                                      1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14};  
   byte fin=44;    
   if((pX+44)>64) fin=64-pX;
   for (int o=0 ; o<fin ; o++){
      LCDSetLine(pY+linW[o],pX,pY+linW[o+44], pX, WHITE); 
      LCDSetLine(pY+linG[o],pX,pY+linG[o+44], pX, GREY); 
      if(o==24){
         LCDSetPixel(pY+2,pX,WHITE);
         LCDSetPixel(pY+1,pX,GREY);
      }
      if(o==25){
         LCDSetLine(pY+2,pX,pY+3, pX, WHITE);   
         LCDSetLine(pY+0,pX,pY+1, pX, GREY);   
      }
      if(o==26){
         LCDSetLine(pY+2,pX,pY+4, pX, WHITE);   
         LCDSetLine(pY+0,pX,pY+1, pX, GREY);   
      }
      if(o==27){
         LCDSetLine(pY+2,pX,pY+5, pX, WHITE);   
         LCDSetLine(pY+0,pX,pY+1, pX, GREY);   
      }
      if(o==28){
         LCDSetLine(pY+2,pX,pY+6, pX, WHITE);   
         LCDSetLine(pY+0,pX,pY+1, pX, GREY);   
      }
      if(o==29){
         LCDSetLine(pY+2,pX,pY+7, pX, WHITE);   
         LCDSetLine(pY+0,pX,pY+1, pX, GREY);   
      }
      pX++;
   } 
}

void calculatePosSunMoon(){
   int www;
    www=(Hour*60)+Minute;
    //Sunshine
    if ((www>420) & (www<480)) {
       PosXSun=((www-420)/6)-10; 
       PosYSun=22-((www-420)/8); 
       if (levelLight!=5-((www-420)/12)){
         levelLight=5-((www-420)/12);
         putBackground();
       }  
    }  
    //sunrising
    else if ((www>1200) & (www<1260)) {
       PosXSun=54+((www-1200)/6);
       PosYSun=15+((www-1200)/8);
       if (((www-1200)/12)!=levelLight){
         levelLight=((www-1200)/12);
         putBackground();
       }       
    }
    
    else if ((www>480) & (www<1200)) {
       PosXSun=(www-480)/13; 
       PosYSun=15;
       if (levelLight!=0){
          levelLight=0;
          putBackground();         
       } 
    }
    //Moon down
    else if ((www>360)&(www<=420)){
       PosXSun=54+((www-360)/6);
       PosYSun=15+((www-360)/8);
    }
    //Moon up
    else if ((www>=1260)&(www<1320)){   
       PosXSun=((www-1260)/6)-10;
       PosYSun=22-((www-1260)/8);  
       if (levelLight<5){
          levelLight=5;
          putBackground();         
       }      
    }
    else if ((www>=1320)&(www<=1440)){
       PosXSun=((www-1320)/11);
       PosYSun=15;         
    }
    else if ((www>=0)&(www<=360)){
       PosXSun=11+(www/11);
       PosYSun=15;         
    }
    
}

void drawStormIcon(byte pX,byte pY){
    LCDSetLine(0+pY,7+pX,7+pY,14+pX, YELLOW);
    LCDSetLine(7+pY,14+pX,4+pY,3+pX,YELLOW);
    LCDSetLine(4+pY,3+pX,15+pY,10+pX,YELLOW);
    LCDSetLine(15+pY,10+pX,13+pY,6+pX,YELLOW);
    LCDSetLine(15+pY,10+pX,11+pY,10+pX,YELLOW);    
}

void drawRainIcon(byte pX, byte pY){
    LCDSetLine(2+pY,3+pX,4+pY,3+pX,BLUE);
    LCDSetLine(3+pY,2+pX,3+pY,4+pX,BLUE);
    
    LCDSetRect(2+pY,12+pX,3+pY,13+pX, NOFILL, BLUE);   // Draw box 
    LCDSetRect(3+pY,9+pX,4+pY,10+pX, NOFILL, BLUE);   // Draw box 
    LCDSetRect(4+pY,11+pX,5+pY,12+pX, NOFILL, BLUE);   // Draw box 
    LCDSetRect(6+pY,10+pX,7+pY,11+pX, NOFILL, CYAN);   // Draw box 
    LCDSetRect(5+pY,13+pX,6+pY,14+pX, NOFILL, CYAN);   // Draw box 
    
    LCDSetRect(8+pY,5+pX,9+pY,6+pX, NOFILL, CYAN2);   // Draw box
    LCDSetRect(9+pY,4+pX,10+pY,5+pX, NOFILL, CYAN2);   // Draw box
    LCDSetRect(9+pY,1+pX,10+pY,2+pX, NOFILL, CYAN2);   // Draw box
    LCDSetRect(10+pY,2+pX,11+pY,3+pX, NOFILL, CYAN2);   // Draw box
    LCDSetRect(11+pY,5+pX,12+pY,6+pX, NOFILL, CYAN);   // Draw box
    LCDSetRect(12+pY,3+pX,13+pY,4+pX, NOFILL, CYAN);   // Draw box
    LCDSetRect(12+pY,6+pX,13+pY,7+pX, NOFILL, CYAN);   // Draw box
    LCDSetRect(13+pY,2+pX,14+pY,3+pX, NOFILL, CYAN);   // Draw box 
}

void calculateTime(long ttt){

  hourTmp=0;
  minuteTmp=0;
  dayTmp=0;
  minuteTmp=ttt/16.6666667;

  
  if(minuteTmp>1440) {
     dayTmp=minuteTmp/1440;
     minuteTmp=0;
  }
  else {
     minuteTmp+=Minute;
     if (minuteTmp>59) {
        hourTmp+=(minuteTmp/60);
        minuteTmp=minuteTmp%60;
     }
     hourTmp+=Hour;
     if (hourTmp>24){
        dayTmp+=hourTmp/24; 
     }
  }
}

void recibe_trama(){
  byte inByte = '\0';
   while(inByte != inicio_trama) {
    while(!Serial.available());            // wait for input
    inByte = Serial.read(); // Wait for the start of the message
   } 
   
    detachInterrupt(0);    //Save from resets by overflow
    detachInterrupt(1);    //Save from resets by overflow
    Inicia_buffer();
    index=0;
    do{
      while(!Serial.available());            // wait for input
      buffer[index] = Serial.read();       // get it
     // Serial.print(buffer[index]);
      if (buffer [index] == fin_trama) break;
    } while (++index < long_buffer);
       
    buffer[index] = 0;                     // null terminate the string*/

  //Restore external interrupts
  attachInterrupt(0, contrastPlus, RISING);
  attachInterrupt(1, contrastMinus, RISING);
   
}

///////////////////////////////////////
//  Limpiar variables de string
///////////////////////////////////////
void limpia_strings(){
 int f;
 for(f=0;f<16;f++){
   if (f<3){
      Hour_str[f]=0x00;
      Minute_str[f]=0x00;
      Day_str[f]=0x00;
      Month_str[f]=0x00;      
   }
   if (f<5) Year_str[f]=0x00;
   if (f<8){ 
      PosX_str[f]=0x00;
      PosY_str[f]=0x00;
      PosZ_str[f]=0x00;
   }
   if (f<10){ 
      dist_to_spawn_str[f]=0x00;
      Time_str[f]=0x00;
      Rain_time_str[f]=0x00;
      Thunder_time_str[f]=0x00;
   }

   World_name[f]=0x00;
 }

}

/***************************************************************
** Parser del Buffer
**
**  String data format
**
**  @           //Start character
**  int <time> 
**  int <min>
**  int <hour>
**  int <day>
**  int <month>
**  int <year>
**  bool <sun?>
**  bool <moon?>
**  int <raining time left>
**  int <thundering time left>
**  bool <raining?>
**  bool <thundering?>
**  float <pos_x>
**  float <pos_y>
**  float <pos_z>
**  float <distance to spawn from player>
**  char* <name of world>
**  #          //End character
**
**
**  Data string sample:
**  @1232144,55,21,18,9,1974,1,0,12500,20000,0,0,12.6584,24.6854,-2.2359,145875,Twin Peaks#
**
****************************************************************/
void command_process(){

  int i,j;
  limpia_strings();                 //Limpiar todas las cadenas
  i=0;
   //Tiempo
   j=0;
   while (buffer[i]!=','){
      Time_str[j++]=buffer[i];
      i++;
   }
   Time=atol(Time_str);

   i++;
   //Minutos
   j=0;
   while (buffer[i]!=','){
      Minute_str[j++]=buffer[i];
      i++;
   }
   Minute=atoi(Minute_str);
   i++;
   //Horas
   j=0;
   while (buffer[i]!=','){
      Hour_str[j++]=buffer[i];
      i++;
   }
   Hour=atoi(Hour_str); 
   i++;
   //Dia
   j=0;
   while (buffer[i]!=','){
      Day_str[j++]=buffer[i];
      i++;
   }
   Day=atoi(Day_str);
   i++;
   //Mes
   j=0;
   while (buffer[i]!=','){
      Month_str[j++]=buffer[i];
      i++;
   }
   Month=atoi(Month_str);
   i++ ;  
   //Año
   j=0;
   while (buffer[i]!=','){
      Year_str[j++]=buffer[i];
      i++;
   }
   Year=atoi(Year_str);
   i++;
   //Sun FLag
   if(buffer[i]=='1') Sun=1;
   else Sun=0;
   i+=2;
   //Moon FLag
   if(buffer[i]=='1') Moon=1;
   else Moon=0;
   i+=2;
   //Rain Time
   j=0;
   while (buffer[i]!=','){
      Rain_time_str[j++]=buffer[i];
      i++;
   }
   Rain_time=atol(Rain_time_str);
   i++;
   //Thundering Time
   j=0;
   while (buffer[i]!=','){
      Thunder_time_str[j++]=buffer[i];
      i++;
   }
   Thunder_time=atol(Thunder_time_str);
   
   i++;
   //Raining FLag
   if(buffer[i]=='1') Raining=1;
   else Raining=0;
   i+=2;
   //Thundering flag
   if(buffer[i]=='1') Thundering=1;
   else Thundering=0;
   i+=2;
   //PosX
   j=0;
   while (buffer[i]!=','){
      if (j<7) PosX_str[j++]=buffer[i];
      i++;
   }
   //PosX=atof(PosX_str);
   i++;
   //PosY
   j=0;
   while (buffer[i]!=','){
      if (j<7) PosY_str[j++]=buffer[i];
      i++;
   }
   //PosY=atof(PosY_str);
   i++;
   //PosZ
   j=0;
   while (buffer[i]!=','){
      if (j<7) PosZ_str[j++]=buffer[i];
      i++;
   }
   //PosZ=atof(PosZ_str);
   i++;
   //Distance to Spawn
   j=0;
   while (buffer[i]!=','){
      dist_to_spawn_str[j++]=buffer[i];
      i++;
   }
   dist_to_spawn=atof(dist_to_spawn_str);
   i++;   
    //World Name
   j=0;
   stringLen=0;
   while (buffer[i]!='\0'){
      World_name[j++]=buffer[i];
      i++;
      stringLen++;
   }
   Inicia_buffer(); // Borro buffer.
}

/**************************************/
/*   Change LCD contrast              */
/**************************************/
void lcd_contrast(int value){
   sendCMD(SETCON);  // Set Contrast
   sendData(value); 
   Serial.print("contraste:");
 
   Serial.println(value);
   
   delay(80); 
}

/**************************************/
/*        Sending command             */
/**************************************/
void sendCMD(byte data) 
{
     byte i;

    LCD_DATA(0);                     // set up first bit as command or data 
    LCD_CS(0);                     // Enable device CS

    LCD_CLK(0);                     // Pull Clock LOW
    LCD_CLK(1);                     // Pul Clock HIGH
    
    if(data == 0x0){        // spi cannot transfer zero??
      LCD_DATA(0);
      for(i=0; i<8; i++){
      
        LCD_CLK(0);                     // Pull Clock LOW
        LCD_CLK(1);   
      }
    }
    else{
    SPCR |=0x50;                  // Enable Hardware SPI
    SPSR |= 0x1;
    SPDR = data;                   // send data
    
    while(!(SPSR & 0x80));            // wait until send complete

    }

    SPCR &=~0x50;                  // Disable Hardware SPI, this releases the SPI pins
                              // for general IO use. which is used to send the 1'st 
      LCD_CS(1);                     // disable device CS                           // bit out
 /* CS1
  CLK0
  CS0
  SDA0
  CLK1
  CLK0

  shiftBits(data);
  CLK0
  CS1*/
}
/**************************************/
/*        Sending data                */
/**************************************/
void sendData(byte data) {
   byte i;

    LCD_DATA(1);                     // set up first bit as command or data 
    LCD_CS(0);                     // Enable device CS

    LCD_CLK(0);                     // Pull Clock LOW
    LCD_CLK(1);                     // Pul Clock HIGH
    
    if(data == 0x0){        // spi cannot transfer zero??
      LCD_DATA(0);
      for(i=0; i<8; i++){
      
        LCD_CLK(0);                     // Pull Clock LOW
        LCD_CLK(1);   
      }
    }
    else{
    SPCR |=0x50;                  // Enable Hardware SPI
    SPSR |= 0x1;
    SPDR = data;                   // send data
    
    while(!(SPSR & 0x80));            // wait until send complete

    }

    SPCR &=~0x50;                  // Disable Hardware SPI, this releases the SPI pins
                              // for general IO use. which is used to send the 1'st 
      LCD_CS(1);                     // disable device CS                           // bit out  
/*  CS1
  CLK0
  CS0
  SDA1
  CLK1
  CLK0

  shiftBits(data);
  CLK0
  CS1*/
}
/**************************************/
/*        Shifting SPI bit out        */
/**************************************/
void shiftBits(byte data) 
{
  byte Bit;
  
  for (Bit = 0; Bit < 8; Bit++)     // 8 Bit Write
  {
    CLK0          // Standby SCLK
    if((data&0x80)>>7)
    {
      SDA1
    }
    else
    {
      SDA0
    }
    CLK1          // Strobe signal bit 
    data <<= 1;   // Next bit data
  }  
}
/**************************************/
/*        Initialize LCD              */
/**************************************/
void lcd_init()
{
  /* // Initial state
  CLK0
  CS1
  SDA1
  
  // Hardware Reset LCD
  RESET0
  delay(100);
  RESET1
  delay(100);*/
    LCD_CS(1);
    LCD_CLK(0);
    LCD_DATA(0);

    LCD_RESET(1);
    delay(50);
    LCD_RESET(0);
    delay(50);
    LCD_RESET(1);
    delay(50);

    LCD_CS(1);
    LCD_CLK(1);
    LCD_DATA(1);
    delay(10);
  // Sleep out (commmand 0x11)
  sendCMD(SLEEPOUT);
  
  // Inversion on (command 0x20)
  //sendCMD(INVON);    // seems to be required for this controller
  sendCMD(INVOFF); 
  
  // Color Interface Pixel Format (command 0x3A)
  sendCMD(COLMOD);
  sendData(0x03);    // 0x03 = 12 bits-per-pixel
  
  // Memory access controler (command 0x36)
  sendCMD(MADCTL);
  sendData(0b11010110); //C8); // 0xC0 = mirror x and y, reverse rgb
  
  // Write contrast (command 0x25)
  sendCMD(SETCON);
  sendData(0x3C); // contrast 0x30
  delay(1000);

  // Display On (command 0x29)
  sendCMD(DISPON);
}
/**************************************/
/*       Draw a demo color bar        */
/**************************************/
void draw_color_bar()
{
  lcd_clear(RED,0,0,131,33);
  lcd_clear(GREEN,0,34,131,66);
  lcd_clear(BLUE,0,67,131,99);
  lcd_clear(WHITE,0,100,131,131);
}
/**************************************/
/* Clear LCD from (x0,y0) to (x1,y1)  */
/**************************************/
void lcd_clear(uint16_t color, byte x0, byte y0, byte x1, byte y1)
{
  uint16_t xmin, xmax, ymin, ymax;
  uint16_t i;
  
  // best way to create a filled rectangle is to define a drawing box
  // and loop two pixels at a time
  // calculate the min and max for x and y directions
  xmin = (x0 <= x1) ? x0 : x1;
  xmax = (x0 > x1) ? x0 : x1;
  ymin = (y0 <= y1) ? y0 : y1;
  ymax = (y0 > y1) ? y0 : y1;

  // specify the controller drawing box according to those limits
  // Row address set (command 0x2B)
  sendCMD(PASET);
  sendData(xmin);
  sendData(xmax);

  // Column address set (command 0x2A)
  sendCMD(CASET);
  sendData(ymin);
  sendData(ymax);

  // WRITE MEMORY
  sendCMD(RAMWR);

  // loop on total number of pixels / 2
  for (i = 0; i < ((((xmax - xmin + 1) * (ymax - ymin + 1)) / 2) + 1); i++) 
  {
    // use the color value to output three data bytes covering two pixels
    // For some reason, it has to send blue first then green and red
    sendData((color << 4) | ((color & 0xF0) >> 4));
    sendData(((color >> 4) & 0xF0) | (color & 0x0F));
    sendData((color & 0xF0) | (color >> 8));
  }
}
// *************************************************************************************************
// LCDPutStr.c
//
// Draws a null-terminates character string at the specified (x,y) address, size and color
//
// Inputs: pString = pointer to character string to be displayed
// x = row address (0 .. 131)
// y = column address (0 .. 131)
// Size = font pitch (SMALL, MEDIUM, LARGE)
// fColor = 12-bit foreground color value rrrrggggbbbb
// bColor = 12-bit background color value rrrrggggbbbb
//
//
// Returns: nothing
//
// Notes: Here's an example to display "Hello World!" at address (20,20)
//
// LCDPutChar("Hello World!", 20, 20, LARGE, WHITE, BLACK);
//
//
// Author: James P Lynch July 7, 2007
// *************************************************************************************************
void LCDPutStr(char *pString, int x, int y, int Size, int fColor, int bColor)
{
  // loop until null-terminator is seen
  while (*pString != 0x00) 
  {
    // draw the character
    LCDPutChar(*pString++, x, y, Size, fColor, bColor);

    // advance the y position
    if (Size == SMALL)
    y = y + 6;

    else if (Size == MEDIUM)
    y = y + 8;

    else
    y = y + 8;

    // bail out if y exceeds 131
    if (y > 131) break;
  }
}
// *****************************************************************************
// LCDPutChar.c
//
// Draws an ASCII character at the specified (x,y) address and color
//
// Inputs: c = character to be displayed
// x = row address (0 .. 131)
// y = column address (0 .. 131)
// size = font pitch (SMALL, MEDIUM, LARGE)
// fcolor = 12-bit foreground color value rrrrggggbbbb
// bcolor = 12-bit background color value rrrrggggbbbb
//
//
// Returns: nothing
//
//
// Notes: Here's an example to display "E" at address (20,20)
//
// LCDPutChar('E', 20, 20, MEDIUM, WHITE, BLACK);
//
// (27,20) (27,27)
// | |
// | |
// ^ V V
// : _ # # # # # # # 0x7F
// : _ _ # # _ _ _ # 0x31
// : _ _ # # _ # _ _ 0x34
// x _ _ # # # # _ _ 0x3C
// : _ _ # # _ # _ _ 0x34
// : _ _ # # _ _ _ # 0x31
// : _ # # # # # # # 0x7F
// : _ _ _ _ _ _ _ _ 0x00
//
// ------y------->
// ^ ^
// | |
// | |
// (20,20) (20,27)
//
//
// The most efficient way to display a character is to make use of the "wrap-around" feature
// of the Philips PCF8833 LCD controller chip.
//
// Assume that we position the character at (20, 20) that's a (row, col) specification.
// With the row and column address set commands, you can specify an 8x8 box for the SMALL and MEDIUM
// characters or a 16x8 box for the LARGE characters.
//
// WriteSpiCommand(PASET); // set the row drawing limits
// WriteSpiData(20); //
// WriteSpiData(27); // limit rows to (20, 27)
//
// WriteSpiCommand(CASET); // set the column drawing limits
// WriteSpiData(20); //
// WriteSpiData(27); // limit columns to (20,27)
//
// When the algorithm completes col 27, the column address wraps back to 20
// At the same time, the row address increases by one (this is done by the controller)
//
// We walk through each row, two pixels at a time. The purpose is to create three
// data bytes representing these two pixels in the following format (as specified by Philips
// for RGB 4 : 4 : 4 format (see page 62 of PCF8833 controller manual).
//
// Data for pixel 0: RRRRGGGGBBBB
// Data for Pixel 1: RRRRGGGGBBBB
//
// WriteSpiCommand(RAMWR); // start a memory write (96 data bytes to follow)
//
// WriteSpiData(RRRRGGGG); // first pixel, red and green data
// WriteSpiData(BBBBRRRR); // first pixel, blue data; second pixel, red data
// WriteSpiData(GGGGBBBB); // second pixel, green and blue data
// :
// and so on until all pixels displayed!
// :
// WriteSpiCommand(NOP); // this will terminate the RAMWR command
//
//
// Author: James P Lynch July 7, 2007
// *****************************************************************************
void LCDPutChar(char c, int x, int y, int size, int fColor, int bColor) 
{
  int i,j;
  unsigned int  nCols;
  unsigned int  nRows;
  unsigned int  nBytes;
  unsigned char PixelRow;
  unsigned char Mask;
  unsigned int  Word0;
  unsigned int  Word1;
  unsigned char *pFont;
  unsigned char *pChar;
  unsigned char *FontTable[] = {(unsigned char *)FONT6x8,
                                (unsigned char *)FONT6x8,
                                //(unsigned char *)FONT8x8,
                                (unsigned char *)FONT8x16};

  // get pointer to the beginning of the selected font table
  pFont = (unsigned char *)FontTable[size];

  /* get the nColumns, nRows and nBytes */
  //nCols = *pFont;
  nCols  = pgm_read_byte(&*pFont);         // Array Flash
  //nRows = *(pFont + 1);
  nRows  = pgm_read_byte(&*(pFont + 1));   // Array Flash
  //nBytes = *(pFont + 2);
  nBytes = pgm_read_byte(&*(pFont + 2));   // Array Flash

  /* get pointer to the last byte of the desired character */
  //pChar = pFont + (nBytes * (c - 0x1F)) + nBytes - 1;
  pChar = pFont + (nBytes * (c - 0x1F));
  // Row address set (command 0x2B)
  sendCMD(PASET);
  sendData(x);
  sendData(x + nRows - 1);

  // Column address set (command 0x2A)
  sendCMD(CASET);
  sendData(y);
  sendData(y + nCols - 1);

  // WRITE MEMORY
  sendCMD(RAMWR);
  // loop on each row, working backwards from the bottom to the top
  for (i = nRows - 1; i >= 0; i--) 
  {
    /* copy pixel row from font table and then decrement row */
    //PixelRow = pgm_read_byte(&*pChar--);  // Array Flash
    //PixelRow = *pChar--;
    PixelRow = pgm_read_byte(&*pChar++);  // Array Flash

    // loop on each pixel in the row (left to right)
    // Note: we do two pixels each loop
    Mask = 0x80;
    for (j = 0; j < nCols; j += 2) 
	{
      // if pixel bit set, use foreground color; else use the background color
      // now get the pixel color for two successive pixels
      if ((PixelRow & Mask) == 0)
        Word0 = bColor;
      else
        Word0 = fColor;
      Mask = Mask >> 1;

      if ((PixelRow & Mask) == 0)
        Word1 = bColor;
      else
        Word1 = fColor;
      Mask = Mask >> 1;
      
      // use this information to output three data bytes
      // For some reason, it has to send blue first then green and red
      
      sendData((Word0 << 4) | ((Word0 & 0xF0) >> 4));
      sendData(((Word0 >> 4) & 0xF0) | (Word1 & 0x0F));
      sendData((Word1 & 0xF0) | (Word1 >> 8));
      
    }
  }

  // terminate the Write Memory command
  sendCMD(NOP);
}
// *************************************************************************************************
// LCDSetLine.c
//
// Draws a line in the specified color from (x0,y0) to (x1,y1)
//
// Inputs: x = row address (0 .. 131)
// y = column address (0 .. 131)
// color = 12-bit color value rrrrggggbbbb
// rrrr = 1111 full red
// :
// 0000 red is off
//
// gggg = 1111 full green
// :
// 0000 green is off
//
// bbbb = 1111 full blue
// :
// 0000 blue is off
//
// Returns: nothing
//
// Note: good write-up on this algorithm in Wikipedia (search for Bresenham's line algorithm)
// see lcd.h for some sample color settings
//
// Authors: Dr. Leonard McMillan, Associate Professor UNC
// Jack Bresenham IBM, Winthrop University (Father of this algorithm, 1962)
//
// Note: taken verbatim from Professor McMillan's presentation:
// http://www.cs.unc.edu/~mcmillan/comp136/Lecture6/Lines.html
//
// *************************************************************************************************
void LCDSetLine(int x0, int y0, int x1, int y1, int color) 
{
  int dy = y1 - y0;
  int dx = x1 - x0;
  int stepx, stepy;
  if (dy < 0) { dy = -dy; stepy = -1; } else { stepy = 1; }
  if (dx < 0) { dx = -dx; stepx = -1; } else { stepx = 1; }
  dy <<= 1; // dy is now 2*dy
  dx <<= 1; // dx is now 2*dx
  LCDSetPixel(x0, y0, color);
  if (dx > dy) 
  {
    int fraction = dy - (dx >> 1); // same as 2*dy - dx
    while (x0 != x1) 
    {
      if (fraction >= 0) 
      {
        y0 += stepy;
        fraction -= dx; // same as fraction -= 2*dx
      }
      x0 += stepx;
      fraction += dy; // same as fraction -= 2*dy
      LCDSetPixel(x0, y0, color);
    }
  } 
  else 
  {
    int fraction = dx - (dy >> 1);
    while (y0 != y1) 
	{
      if (fraction >= 0) 
	  {
        x0 += stepx;
        fraction -= dy;
      }
      y0 += stepy;
      fraction += dx;
      LCDSetPixel(x0, y0, color);
    }
  }
}
// *****************************************************************************************
// LCDSetRect.c
//
// Draws a rectangle in the specified color from (x1,y1) to (x2,y2)
// Rectangle can be filled with a color if desired
//
// Inputs: x = row address (0 .. 131)
// y = column address (0 .. 131)
// fill = 0=no fill, 1-fill entire rectangle
// color = 12-bit color value for lines rrrrggggbbbb
// rrrr = 1111 full red
// :
// 0000 red is off
//
// gggg = 1111 full green
// :
// 0000 green is off
//
// bbbb = 1111 full blue
// :
// 0000 blue is off
// Returns: nothing
//
// Notes:
//
// The best way to fill a rectangle is to take advantage of the "wrap-around" featute
// built into the Philips PCF8833 controller. By defining a drawing box, the memory can
// be simply filled by successive memory writes until all pixels have been illuminated.
//
// 1. Given the coordinates of two opposing corners (x0, y0) (x1, y1)
// calculate the minimums and maximums of the coordinates
//
// xmin = (x0 <= x1) ? x0 : x1;
// xmax = (x0 > x1) ? x0 : x1;
// ymin = (y0 <= y1) ? y0 : y1;
// ymax = (y0 > y1) ? y0 : y1;
//
// 2. Now set up the drawing box to be the desired rectangle
//
// WriteSpiCommand(PASET); // set the row boundaries
// WriteSpiData(xmin);
// WriteSpiData(xmax);
// WriteSpiCommand(CASET); // set the column boundaries
// WriteSpiData(ymin);
// WriteSpiData(ymax);
//
// 3. Calculate the number of pixels to be written divided by 2
//
// NumPixels = ((((xmax - xmin + 1) * (ymax - ymin + 1)) / 2) + 1)
//
// You may notice that I added one pixel to the formula.
// This covers the case where the number of pixels is odd and we
// would lose one pixel due to rounding error. In the case of
// odd pixels, the number of pixels is exact.
// in the case of even pixels, we have one more pixel than
// needed, but it cannot be displayed because it is outside
// the drawing box.
//
// We divide by 2 because two pixels are represented by three bytes.
// So we work through the rectangle two pixels at a time.
//
// 4. Now a simple memory write loop will fill the rectangle
//
// for (i = 0; i < ((((xmax - xmin + 1) * (ymax - ymin + 1)) / 2) + 1); i++) {
// WriteSpiData((color >> 4) & 0xFF);
// WriteSpiData(((color & 0xF) << 4) | ((color >> 8) & 0xF));
// WriteSpiData(color & 0xFF);
// }
//
// In the case of an unfilled rectangle, drawing four lines with the Bresenham line
// drawing algorithm is reasonably efficient.
//
// Author: James P Lynch July 7, 2007
// *****************************************************************************************
void LCDSetRect(int x0, int y0, int x1, int y1, unsigned char fill, int color) 
{
  int xmin, xmax, ymin, ymax;
  int i;

  // check if the rectangle is to be filled
  if (fill == FILL) 
  {
    // best way to create a filled rectangle is to define a drawing box
    // and loop two pixels at a time
    // calculate the min and max for x and y directions
    xmin = (x0 <= x1) ? x0 : x1;
    xmax = (x0 > x1) ? x0 : x1;
    ymin = (y0 <= y1) ? y0 : y1;
    ymax = (y0 > y1) ? y0 : y1;

    // specify the controller drawing box according to those limits
    // Row address set (command 0x2B)
    sendCMD(PASET);
    sendData(xmin);
    sendData(xmax);

    // Column address set (command 0x2A)
    sendCMD(CASET);
    sendData(ymin);
    sendData(ymax);

    // WRITE MEMORY
    sendCMD(RAMWR);

    // loop on total number of pixels / 2
    for (i = 0; i < ((((xmax - xmin + 1) * (ymax - ymin + 1)) / 2) + 1); i++)
    {
      // use the color value to output three data bytes covering two pixels
      // For some reason, it has to send blue first then green and red
      sendData((color << 4) | ((color & 0xF0) >> 4));
      sendData(((color >> 4) & 0xF0) | (color & 0x0F));
      sendData((color & 0xF0) | (color >> 8));  
    }
  } 
  else 
  {
    // best way to draw un unfilled rectangle is to draw four lines
    LCDSetLine(x0, y0, x1, y0, color);
    LCDSetLine(x0, y1, x1, y1, color);
    LCDSetLine(x0, y0, x0, y1, color);
    LCDSetLine(x1, y0, x1, y1, color);
  }
}

// *************************************************************************************
// LCDSetCircle.c
//
// Draws a line in the specified color at center (x0,y0) with radius
//
// Inputs: x0 = row address (0 .. 131)
// y0 = column address (0 .. 131)
// radius = radius in pixels
// color = 12-bit color value rrrrggggbbbb
//
// Returns: nothing
//
// Author: Jack Bresenham IBM, Winthrop University (Father of this algorithm, 1962)
//
// Note: taken verbatim Wikipedia article on Bresenham's line algorithm
// http://www.wikipedia.org
//
// *************************************************************************************
void LCDSetCircle(int x0, int y0, int radius, int color) 
{
  int f = 1 - radius;
  int ddF_x = 0;
  int ddF_y = -2 * radius;
  int x = 0;
  int y = radius;
  LCDSetPixel(x0, y0 + radius, color);
  LCDSetPixel(x0, y0 - radius, color);
  LCDSetPixel(x0 + radius, y0, color);
  LCDSetPixel(x0 - radius, y0, color);
  while (x < y) 
  {
    if (f >= 0) 
	{
      y--;
      ddF_y += 2;
      f += ddF_y;
    }
    x++;
    ddF_x += 2;
    f += ddF_x + 1;
    LCDSetPixel(x0 + x, y0 + y, color);
    LCDSetPixel(x0 - x, y0 + y, color);
    LCDSetPixel(x0 + x, y0 - y, color);
    LCDSetPixel(x0 - x, y0 - y, color);
    LCDSetPixel(x0 + y, y0 + x, color);
    LCDSetPixel(x0 - y, y0 + x, color);
    LCDSetPixel(x0 + y, y0 - x, color);
    LCDSetPixel(x0 - y, y0 - x, color);
   }
}
// *************************************************************************************
// LCDSetPixel.c
//
// Lights a single pixel in the specified color at the specified x and y addresses
//
// Inputs: x = row address (0 .. 131)
// y = column address (0 .. 131)
// color = 12-bit color value rrrrggggbbbb
// rrrr = 1111 full red
// :
// 0000 red is off
//
// gggg = 1111 full green
// :
// 0000 green is off
//
// bbbb = 1111 full blue
// :
// 0000 blue is off
//
// Returns: nothing
//
// Note: see lcd.h for some sample color settings
//
// Author: James P Lynch July 7, 2007
// Modified: Gravitech December 20, 2008
// *************************************************************************************
void LCDSetPixel(byte x, byte y, int color) 
{
  LCDSetXY(x, y);
  sendCMD(RAMWR);
  // For some reason, it has to send blue first then green and red
  sendData((color << 4) | ((color & 0xF0) >> 4));
  sendData(((color >> 4) & 0xF0));
  sendCMD(NOP);
}
// *****************************************************************************
// LCDSetXY.c
//
// Sets the Row and Column addresses
//
// Inputs: x = row address (0 .. 131)
// y = column address (0 .. 131)
//
//
// Returns: nothing
//
// Author: James P Lynch July 7, 2007
// Modified: Gravitech December 20, 2008
// *****************************************************************************
void LCDSetXY(byte x, byte y) 
{
  // Row address set (command 0x2B)
  sendCMD(PASET);
  sendData(x);
  sendData(x);

  // Column address set (command 0x2A)
  sendCMD(CASET);
  sendData(y);
  sendData(y);
}

void SendLcd_color(unsigned char color){
  
    LCD_DATA(LCDData);                     // set up first bit as command or data 

    LCD_CLK(0);                     // Pull Clock LOW
    LCD_CLK(1);                     // Pul Clock HIGH
    LCD_CLK(0);  
    SPCR |=0x50;                  // Enable Hardware SPI
    SPSR |=0x1;

    SPDR = color;                   // send data
    
    while(!(SPSR & 0x80));            // wait until send complete

                  // disable device CS

    SPCR &=~0x50;                  // Disable Hardware SPI, this releases the SPI pins
   
   LCD_CLK(0);                              // for general IO use. which is used to send the 1'st 
                           // bit out
}

void LCDBitmap (unsigned char start_x, unsigned char start_y, unsigned char h_size, unsigned char v_size, unsigned char *bitmap_data) 
{
   int i;
   unsigned char *pBitmap;
   // specify the controller drawing box according to those limits 
      // Row address set  (command 0x2B) 
      sendCMD(PASET); 
      sendData(start_x); 
      sendData( start_x+h_size-1); 
      // Column address set  (command 0x2A) 
      sendCMD(CASET); 
      sendData(start_y); 
      sendData(start_y+v_size-1); 
 
      // WRITE MEMORY 
      sendCMD(RAMWR); 

   pBitmap = bitmap_data;                
               
      // loop on total number of pixels / 2 
      for (i = 0; i< (h_size*v_size)>>1  ; i++) { 
         unsigned char bitmap;                  

        LCD_CS(0);
        
          bitmap = pgm_read_byte(pBitmap++);
          if (levelLight>0){
             if ((bitmap & 0b00001111)>levelLight) bitmap=bitmap-levelLight;
             else bitmap=bitmap&0b11110000;
             if ((bitmap & 0b11110000)>(levelLight<<4)) bitmap=bitmap-(levelLight<<4);
             else bitmap=bitmap & 0b00001111;
          }
          SendLcd_color(bitmap); 
          
          bitmap =pgm_read_byte(pBitmap++);
           if (levelLight>0){
             if ((bitmap & 0b00001111)>levelLight) bitmap=bitmap-levelLight;
             else bitmap=bitmap&0b11110000;
             if ((bitmap & 0b11110000)>(levelLight<<4)) bitmap=bitmap-(levelLight<<4);
             else bitmap=bitmap & 0b00001111;
          }
          SendLcd_color(bitmap); 
          
          bitmap =pgm_read_byte(pBitmap++);
           if (levelLight>0){
             if ((bitmap & 0b00001111)>levelLight) bitmap=bitmap-levelLight;
             else bitmap=bitmap&0b11110000;
             if ((bitmap & 0b11110000)>(levelLight<<4)) bitmap=bitmap-(levelLight<<4);
             else bitmap=bitmap & 0b00001111;
          }
          SendLcd_color(bitmap); 
          
          LCD_CS(1);
      } 
    sendCMD(NOP); 
}

void bitmap(int y,int x, char bmp){
  unsigned char *pbitmap;
  byte image_h, image_w;
  switch (bmp){
   case 0:
   // pbitmap=barra;
   pbitmap=image;
   break;
   case 1:
    //pbitmap=lateralizquierdo;
   break;
   case 2:
    //pbitmap=lateralderecho;
   break;    
  }
  
  image_w = pgm_read_byte(pbitmap+1);
  image_h = pgm_read_byte(pbitmap+2);

   LCDBitmap(x, y, image_w, image_h, pbitmap+5);
  
}
