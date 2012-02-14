/**
 * Coffee Counter Arduino Sketch
 *
 * This is an axact opy of my code from 
 * http://fritzing.org/projects/rfid-reader/
 * with clean licensing info and under 
 * version control. The rename hints at a 
 * project in planning.
 * 
 * This is a simple RFID Reader based on the 
 * Grand Idea Studio Serial RFID Reader from 
 * Parallax. It uses the UART on port 0 for
 * recieving data and outputs it on port 1.
 *
 * @copyright 2009 - hairmare@purplehaze.ch - All Rights Reserved
 * @license   GPL
 */
 
// define pins
const int PIN_IN_BUTTON = 8;        // button to request a reading
const int PIN_OUT_RFID_ENABLE = 2;  // ENABLE on the Reader
 
int readerState = 0;                // initial state of the reader is off
int oldReaderState = 2;
int buttonState;
int lastButtonState = LOW;

long lastDebounceTime = 0;
long debounceDelay = 50;

long readerStartTime = 0;           // for timeing out the reader

char serialBuffer;                  // takes single chars from the reader
char tagString[] = "0123456789";    // string for tag numbers
int tagIndex = 9;                   // for addressing single chars in tagString

void setup() {
   Serial.begin(2400);
   
   pinMode(PIN_IN_BUTTON, INPUT);
   pinMode(PIN_OUT_RFID_ENABLE, OUTPUT);
   // high deactivates module, pull to low for a reading
   digitalWrite(PIN_OUT_RFID_ENABLE, HIGH); 
   
   //Serial.println('reader online');
}
 
void loop() {
  int reading;
   // initially the reader waits for a button press
   if (readerState == 0) {
     reading = digitalRead(PIN_IN_BUTTON);
     
     if (reading != lastButtonState){
       lastDebounceTime = millis();
     }
     if ((millis() - lastDebounceTime) > debounceDelay){
       buttonState = reading;
       if (buttonState == 1) {
         readerState = 1;
         if (readerState != oldReaderState) {
           Serial.println("                ");
         }
         Serial.println("reading...      ");
       }
     }
     lastButtonState = reading;
   }
   // lets read some RFID!
   if (readerState == 1) {
     if (readerStartTime == 0) {
       readerStartTime = millis();
     }
     digitalWrite(PIN_OUT_RFID_ENABLE, LOW);
     if (Serial.available() > 0) {
       serialBuffer = Serial.read();
       if (serialBuffer == 0x0A) {
         // MSB: start of tag
         tagIndex = 0;
       } else if (serialBuffer == 0x0D) {
         // LSB: end of tag, lets print
         Serial.println(tagString);
       } else {
         tagString[tagIndex++] = serialBuffer;
       }
       
         
       //Serial.print(Serial.read());
     }
     // timeout reader after some time
     if ((millis() - readerStartTime) > 1000) {
      readerState = 2;
     } 
   }
   // clean up 
   if (readerState == 2) {
     digitalWrite(PIN_OUT_RFID_ENABLE, HIGH);
     readerStartTime = 0;
     readerState = 0;
   }
   oldReaderState = readerState;
}
