#include <Arduino.h>
#include "MatrixMath.h"

#define PACKAGE_HEADER      0xFF
#define PACKAGE_TAIL        0xFE
#define PACKAGE_HEADER_LEN   2
#define PACKAGE_SELF_ID_LEN  2
#define PACKAGE_SEQ_LEN      1
#define PACKAGE_AMOUNT_LEN   1
#define PACKAGE_TAIL_LEN     2
#define PACKAGE_MIN_LEN      PACKAGE_HEADER_LEN+PACKAGE_SELF_ID_LEN+PACKAGE_SEQ_LEN+PACKAGE_AMOUNT_LEN+PACKAGE_TAIL_LEN
#define PACKAGE_ANCHOR_ID_LEN   2
#define PACKAGE_FLOAT_LEN       4

#define BLUETOOTH_HEADER 255
#define BLUETOOTH_TAIL 254

#define bufferSize      300
byte uartBuffer[bufferSize];
int uartBufferCursor = 0;
static double Matrix_P[3][1];

int bluetoothBuffer[bufferSize];
int bluetoothBufferCursor = 0;
byte data;
int forward, back, turn, arm, door, brush;
byte sendByte;
int xM, xCm, yM, yCm;

#define MaxObsevationNum      1
int ObservationNum;
int ObserverdID[MaxObsevationNum];
float ObservedRange[MaxObsevationNum], x, y;
uint8_t hasNewUWBdata = 0;

/*******************************************************************************/
/***Anchors' coordinates will be provided once the test environment is set up   */
/*******************************************************************************/
int AnchorNum = 4;
double AnchorXYZ[][3] = {{0,0,2},
                      {0,10,2},
                      {10,0,2},
                      {10,10,2}};    //unit: m
int AnchorID[] = {2820,2819,2816,2821};


/*******************************************************************************/

void setup() {

  /* UWb would use the only UART on UNO, However, it only uses RX pin
     you can still use Serial.print() to print information
     It is recommended to allocate UWB to another UART if Mega or other boards are applied
  */
  //USB debug
  Serial.begin(115200);

  //UWB tag
  Serial2.begin(115200);

  //HC-06 bluetooth
  Serial3.begin(9600);

  Serial.println("Ready");
  Serial.flush();
}

void loop() {
  if (hasNewUWBdata == 1) {
    hasNewUWBdata = 0;
    computeLocation();
  }
}

/**
* @brief Compute location based on UWB measurements
*/
void computeLocation() {
  double Matrix_tmp[MaxObsevationNum][4];
  int counter = 0;
  for (int i = 0; i < ObservationNum; i++) {
    //USB
    /*Serial.print(ObserverdID[i]);*///Serial.print("Raw: ");Serial.println(ObservedRange[i]);
    //Serial.print("Distance: ");Serial.println(ObservedRange[i] * 0.61 - 0.13);

    //Splitting into two bytes for m and cm
    xM = (int) ObservedRange[i];
    xCm = (int) ((ObservedRange[i] - xM) * 100);

    //Bluetooth
    byte coord[] = {0xFF, 0xFF, 0x0F, 0x0F, xM, xCm, 0xF0, 0xF0, xM, xCm, 0xFE};

    for (sendByte = 0; sendByte < sizeof(coord); sendByte = sendByte + 1) {
      Serial3.write(coord[sendByte]);
    }

    for (int j = 0; j < AnchorNum; j++) {
      if (ObserverdID[i] == AnchorID[j]) {
        Matrix_tmp[counter][0] = AnchorXYZ[j][0];  //X
        Matrix_tmp[counter][1] = AnchorXYZ[j][1];  //Y
        Matrix_tmp[counter][2] = AnchorXYZ[j][2];  //Z
        Matrix_tmp[counter][3] = ObservedRange[i]; //Range
        counter++;
      }
    }
  }

  if (counter >= 4) {
    double Matrix_P[3][1] = {{1},{1},{0}};
    double Matrix_dxyz[3][1] = {{0},{0},{0}};
    double Matrix_A[counter][3];
    double Matrix_B[counter][1];

    double Matrix_AT[3][counter];
    double Matrix_ATA[3][3];
    double Matrix_ATA_rev[3][3];
    double Matrix_ATA_rev_AT[3][counter];
    int loop = 0;
    while (loop<20) {
      Matrix.Add((double*)Matrix_P,(double*)Matrix_dxyz, 3, 1, (double*)Matrix_P);

      for (int i=0; i<counter; i++) {
        double tmpD=(pow((Matrix_tmp[i][0]-Matrix_P[0][0]),2)
                        +pow((Matrix_tmp[i][1]-Matrix_P[1][0]),2)
                        +pow((Matrix_tmp[i][2]-Matrix_P[2][0]),2));


        Matrix_A[i][0]=2*(Matrix_P[0][0]-Matrix_tmp[i][0]);
        Matrix_A[i][1]=2*(Matrix_P[1][0]-Matrix_tmp[i][1]);
        Matrix_A[i][2]=2*(Matrix_P[2][0]-Matrix_tmp[i][2]);
        Matrix_B[i][0]=pow(Matrix_tmp[i][3],2)-tmpD;

      }

      Matrix.Transpose((double*)Matrix_A, counter, 3, (double*)Matrix_AT);
      Matrix.Multiply((double*)Matrix_AT, (double*)Matrix_A, 3, (counter),3, (double*)Matrix_ATA);
      Matrix.Invert((double*)Matrix_ATA, 3);//inv
      Matrix.Multiply((double*)Matrix_ATA, (double*)Matrix_AT, 3, 3,(counter), (double*)Matrix_ATA_rev_AT);
      Matrix.Multiply((double*)Matrix_ATA_rev_AT, (double*)Matrix_B, 3, (counter),1, (double*)Matrix_dxyz);

      if (abs(Matrix_dxyz[0][0])<0.005&& abs(Matrix_dxyz[1][0])<0.005) {
        Matrix.Add((double*)Matrix_P,(double*)Matrix_dxyz, 3, 1, (double*)Matrix_P);
        break;
      }
      loop++;
    }

    if(loop < 20){
       /* USER CODE BEGIN */
      //get x and y coords
      x = Matrix_P[0][0];
      y = Matrix_P[1][0];

      //split float into meter and cm integers
      xM = (int) x;
      xCm = (int) ((x - xM) * 100);

      yM = (int) y;
      yCm = (int) ((y - yM) * 100);

      //communication protocol
      byte coord[] = {0xFF, 0xFF, 0x0F, 0x0F, xM, xCm, 0xF0, 0xF0, yM, yCm, 0xFE};

      for (sendByte = 0; sendByte < sizeof(coord); sendByte = sendByte + 1) {
        //Serial3.print(coord[sendByte]);
      }

      /* USER CODE END  */
      Serial.print("X: "); Serial.print(Matrix_P[0][0]);
      Serial.print(" Y: "); Serial.println(Matrix_P[1][0]);
      return;
    } else {
      Serial.println("Algorithm did not converge");
    }
    ObservationNum=0;
  }
  /*Serial.println("Not enough measurements");*/
  ObservationNum=0;
  return;
}

/**
* @brief Decde the UWB package after a pacakge-end is detected
*/
void decodePackage() {
  int tmpCursor = 0;
  /*ignore the data until a package header is detected*/
  while (tmpCursor <= uartBufferCursor) {
    if (uartBuffer[tmpCursor] == PACKAGE_HEADER
      && uartBuffer[tmpCursor + 1] == PACKAGE_HEADER) {
      break;
    } else {
      tmpCursor++;
    }
  }

  if (tmpCursor + PACKAGE_MIN_LEN <= uartBufferCursor) {
    ObservationNum = uartBuffer[tmpCursor + PACKAGE_HEADER_LEN + PACKAGE_SELF_ID_LEN + PACKAGE_SEQ_LEN];

    if (tmpCursor + PACKAGE_MIN_LEN + 6 * ObservationNum < uartBufferCursor) {
      /*Just return if package length is shorter than we expected */
      uartBufferCursor = 0;
      return;
    }
    /*Decode data amd prepare for location computation */
    tmpCursor += (PACKAGE_HEADER_LEN + PACKAGE_SELF_ID_LEN + PACKAGE_SEQ_LEN + PACKAGE_AMOUNT_LEN);
    for (int i = 0; i < ObservationNum; i++) {
      ObserverdID[i] = uartBuffer[tmpCursor] + (uartBuffer[tmpCursor + 1] << 8);
      memcpy(&ObservedRange[i], &uartBuffer[tmpCursor + PACKAGE_ANCHOR_ID_LEN], PACKAGE_FLOAT_LEN);
      tmpCursor += (PACKAGE_ANCHOR_ID_LEN + PACKAGE_FLOAT_LEN);
    }

    hasNewUWBdata = 1;
    uartBufferCursor = 0;
    return;
  } else {
    /*Just return if package length is shorter than we expected */
    uartBufferCursor = 0;
    return;
  }

}

//Decode bluetooth packets
void bluetoothDecode() {
  int tmpCursor = 0;
  while (tmpCursor <= bluetoothBufferCursor) {
    if (bluetoothBuffer[tmpCursor] == BLUETOOTH_HEADER && bluetoothBuffer[tmpCursor + 1] == BLUETOOTH_HEADER) {
      tmpCursor++;
      tmpCursor++; //Increments cursor to start of payload
      break;
    } else {
      tmpCursor++;
    }
  }
  int i = 0;
  while (bluetoothBuffer[tmpCursor] != BLUETOOTH_TAIL && bluetoothBuffer[tmpCursor + 1] != BLUETOOTH_TAIL) {
    i++;
    //checks for the correct command byte and extracts command data from payload
    //then converts 0-255 into -127 to 128 or 0x00 and 0xFF into boolean
    if (bluetoothBuffer[tmpCursor] == 238 && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      //drive forward/back
      data = bluetoothBuffer[tmpCursor + 2];
      forward = data - 127;
    } else if (bluetoothBuffer[tmpCursor] == 223 && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      //turn left/right
      data = bluetoothBuffer[tmpCursor + 2];
      turn = data - 127;
    } else if (bluetoothBuffer[tmpCursor] == 207 && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      //arm velocity
      data = bluetoothBuffer[tmpCursor + 2];
      arm = data - 127;
    } else if (bluetoothBuffer[tmpCursor] == 174 && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      //door position open: 0x00 and close: 0xFF
      data = bluetoothBuffer[tmpCursor + 2];
      if (data == 0) {
        door = false;
      } else if (data == 255) {
        door = true;
      } else {
        Serial.print("door error");
      }
    } else if (bluetoothBuffer[tmpCursor] == 191 && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      //brush acceleration
      data = bluetoothBuffer[tmpCursor + 2];
      brush = data - 127;
    }
    tmpCursor = tmpCursor + 3;

    //Sometimes drops the footer of the bluetooth header, this prevent trapping within the while loop as it cycles through the buffer.
    if (i > 10) {
      i = 0;
      break;
    }

    Serial.print(forward);Serial.print(", ");Serial.print(turn);Serial.print(", ");Serial.print(arm);Serial.print(", ");Serial.print(door);Serial.print(", ");Serial.println(brush);
  }
}

/**
* @brief Read UART buffer on serial event.
*/
void serialEvent2() {
  if (Serial2.available() > 0) {
    // read the incoming byte:
    uartBuffer[uartBufferCursor] = Serial2.read();
    /* check if the package tail 0xfe 0xfe is detected */
    if(uartBuffer[uartBufferCursor] == PACKAGE_TAIL && uartBufferCursor > 0) {
      decodePackage();
      return;
    }
    uartBufferCursor++;
    if (uartBufferCursor >= bufferSize) {
      uartBufferCursor = 0;
    }
  }
}

//Bluetooth serial event
void serialEvent3() {
  if (Serial3.available() > 1) {
    bluetoothBuffer[bluetoothBufferCursor] = Serial3.read();
    if(bluetoothBuffer[bluetoothBufferCursor] == 254 && bluetoothBufferCursor > 0) {
      bluetoothDecode();
      bluetoothBufferCursor = 0;
      memset(bluetoothBuffer, 0, sizeof(bluetoothBuffer));
      return;
    }
    bluetoothBufferCursor++;
    if (bluetoothBufferCursor >= bufferSize) {
      bluetoothBufferCursor = 0;
      memset(bluetoothBuffer, 0, sizeof(bluetoothBuffer));
    }
  }
  //Include PWM control from received commands in loop()?
}
