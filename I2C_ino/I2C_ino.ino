#include <Wire.h>
#include <SPI.h>
#include "Adafruit_BLE_UART.h"

#define SLAVE_ADDRESS 0x04

#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2     // This should be an interrupt pin, on Uno thats #2 or #3
#define ADAFRUITBLE_RST 9

Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);
uint8_t buf[128];
int len;
int num = -1;
char recv_buf[64];

void setup()
{
  len = 0;
  Serial.begin(9600);
  while(!Serial);
  BTLEserial.begin();
  Wire.begin(SLAVE_ADDRESS);
  Wire.onRequest(onRequest);
  Wire.onReceive(onReceive);
}

void loop()
{
  BTLEserial.pollACI();
  aci_evt_opcode_t status = BTLEserial.getState();
  
  if(BTLEserial.available())
  {
    int i = 0;
    char c;
    while(BTLEserial.available())
    {
      c = BTLEserial.read();
      recv_buf[i++] = c;
      Serial.print(c);
    }
    Serial.println("");
    String cmd = String(recv_buf);
    if(cmd.equals("REFRESH"))
    {
      num = 0;
    }
    else
    {
      num = (int) c;
    }
  }
  
  if(Wire.available())
  {    
    char c = (char) Wire.read();
    if(c == '\0' && len > 0)
    {
      BTLEserial.write(buf, len);
      
      String EOM = "EOM";
      EOM.getBytes(buf, 20);
      BTLEserial.write(buf, EOM.length());
      
      len = 0;
      Serial.println("");
    }
    else
    {
      buf[len++] = c;
      Serial.print(c);
    }
  }
}

void onReceive(int bytes)
{}

void onRequest()
{
  Wire.write(num);
  recv_buf[0] = '\0';
  num = -1;
}
