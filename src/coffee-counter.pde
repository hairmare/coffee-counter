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
 * @copyright 2012 Lucas S. Bickel <hairmare@purplehaze.ch> All Rights Reserved
 * @license   GPL
 */
 
// define pins
const int PIN_IN_BUTTON = 8;        // button to request a reading
const int PIN_OUT_RFID_ENABLE = 2;  // ENABLE on the Reader
 
int readerState = 0;                // initial state of the reader is off
int oldReaderState = 2;             // like when after a reset
int buttonState;                    // @todo can be removed with minor refactoring
int lastButtonState = LOW;          // we don't expect a button press on 'boot'

long lastDebounceTime = 0;          // used for soft-debouncing our input
long debounceDelay = 50;            // default debounce delay

long readerStartTime = 0;           // used for timeing out the reader

char serialBuffer;                  // takes single chars from the reader
char tagString[] = "0123456789";    // string for tag numbers
int tagIndex = 9;                   // for addressing single chars in tagString

void setup() {
   Serial.begin(2400);
   
   pinMode(PIN_IN_BUTTON, INPUT);
   pinMode(PIN_OUT_RFID_ENABLE, OUTPUT);
   // high deactivates module, pull to low for a reading
   digitalWrite(PIN_OUT_RFID_ENABLE, HIGH); 
}
 
/**
 * this main loop implements a state engine
 * 
 * haz these states:
 * 0 : wait for button and debounce
 * 1 : read from serial UART until full tag is detected
 * 2 : clean up and turn off rfid reader
 *
 * @todo consider refactoring most transitions into states (see in code comments)
 */
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
         // @todo refactor this into readerState = 3 (it introduces more state than needed to GTJD)
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
     // @todo let this have its own state so is is only done when needed
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
     }
     // timeout reader after some time, also possible millis overflow :|
     // @todo does this need to be configurable?
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
