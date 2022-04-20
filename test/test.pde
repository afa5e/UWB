import processing.serial.*;
Serial serialPort;
int serialData = 0;

final int BLUETOOTH_HEADER = 255;
final int BLUETOOTH_TAIL = 254;

int bufferSize = 300;
int[] bluetoothBuffer = new int[300];
int bluetoothBufferCursor = 0;

float brushVel, count;
int door = 0;
int moveX, moveY, armVel, brushAccel;

//CHange 0.5 to any float between 0 and 1 to set max speed
int moveXMax = 0.5; //max forward/reverse speed
int turnMax = 0.5; //turn speed
int armMax = 0.5; //arm raise/lower speed
int brushMax = 0.5; //brush acceleration

final float moveMap = 255;
final float armMap = 255;
final float brushMap = 255;

float x, y;

final float moveXDeadZone = 10;
final float moveYDeadZone = 10;
final float armVelDeadZone = 10;
final float brushAccelDeadZone = 0.2;

final int startX = 150;
final int startY = 825;

Rover rover = new Rover(startX, startY);

public void setup() {
  surface.setTitle("Mars Rover");
  size(983,906);
  frameRate(120);

  printArray(Serial.list());
  serialPort = new Serial(this, Serial.list()[2], 9600);
  //serialPort.bufferUntil(254);
  println("Serial connected");

  PImage img;
  img = loadImage("bg.png");
  background(img);

  fill(0,0,255);
  ellipse(150, 825, 80, 80);

  brushVel = 0;
}

void draw() {
}

class Rover {
  float xpos, ypos;
  Rover (float x, float y) {
    xpos = x;
    ypos = y;
  }

  void update(int xvel, int yvel, int armVel, int brushAccel, int door) {
    //communication protocol 255, 255, 238, 238, xvel, 223, 223, yvel, 207, 207, armvel, 191, 191, brushaccel, 174, 174, door, 254, 254
    int coord[] = {0xFF, 0xFF, 0xEE, 0xEE, xvel, 0xDF, 0xDF, yvel, 0xCF, 0xCF, armVel, 0xBF, 0xBF, brushAccel, 0xAE, 0xAE, door, 254, 254};
    int sendByte = 0;

    for (sendByte = 0; sendByte < 19; sendByte = sendByte + 1) {
      serialPort.write(coord[sendByte]);
    }
  }

  void drawRover(float UWBxPos, float UWByPos) {
    //map UWB data to pixel coords
    xpos = map(UWBxPos, 0, 10, 0, 983);
    ypos = map(UWByPos, 0, 10, 0, 906);

    PImage img;
    img = loadImage("bg.png");
    background(img);
    fill(0,0,255);
    ellipse(xpos, ypos, 80, 80);
  }
}

void keyPressed() {
  moveX = 0;
  moveY = 0;
  armVel = 0;
  brushAccel = 0;

  if (key == 'w') {
    moveX = int(map(moveXMax, 1, -1, 0, moveMap));
    println(moveX);
  } else if (key == 's') {
    moveX = int(map(-moveXMax, 1, -1, 0, moveMap));
    println(moveX);
  } else if (key == 'a') {
    moveY = int(map(turnMax, 1, -1, 0, moveMap));
    println(moveY);
  } else if (key == 'd') {
    moveY = int(map(-turnMax, 1, -1, 0, moveMap));
    println(moveY);
  } else if (key == 'e') {
    armVel = int(map(armMax, 1, -1, 0, moveMap));
    println(armVel);
  } else if (key == 'q') {
    armVel = int(map(-armMax, 1, -1, 0, moveMap));
    println(armVel);
  } else if (key == 'r') {
    brushAccel = int(map(brushMax, 1, -1, 0, moveMap));
    println(brushAccel);
  } else if (key == 'f') {
    brushAccel = int(map(-brushMax, 1, -1, 0, moveMap));
    println(brushAccel);
  } else if (key == 't') {
    if (door == 0) {
      door = 255;
      println(door);
    } else {
      door = 0;
      println(door);
    }
  } else {

  }

  rover.update(moveX, moveY, armVel, brushAccel, door);
}

void serialEvent(Serial serialPort) {
  try {
    println("serial event");
    if (serialPort.available() > 1) {
      bluetoothBuffer[bluetoothBufferCursor] = serialPort.read();

      if (bluetoothBuffer[bluetoothBufferCursor] == BLUETOOTH_TAIL && bluetoothBufferCursor > 0) {
        bluetoothDecode();
        return;
      }
      bluetoothBufferCursor = bluetoothBufferCursor + 1;
      if (bluetoothBufferCursor >= bufferSize) {
        bluetoothBufferCursor = 0;
      }
    }
  } catch (Exception e) {
    //e.printStackTrace();
  }
}

public void bluetoothDecode() {
  println("packet found");
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

  while (bluetoothBuffer[tmpCursor] != BLUETOOTH_TAIL) {
    if (bluetoothBuffer[tmpCursor] == 0x0F && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      //X coord
      x = bluetoothBuffer[tmpCursor + 2] + bluetoothBuffer[tmpCursor + 3]/100.0;
    } else if (bluetoothBuffer[tmpCursor] == 0xF0 && bluetoothBuffer[tmpCursor] == bluetoothBuffer[tmpCursor + 1]) {
      y = bluetoothBuffer[tmpCursor + 2] + bluetoothBuffer[tmpCursor + 3]/100.0;
    }
    tmpCursor = tmpCursor + 4;
  }
  rover.drawRover(x, y);
}
