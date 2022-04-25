import processing.serial.*;
Serial serialPort;
int serialData = 0;

final int BLUETOOTH_HEADER = 255;
final int BLUETOOTH_TAIL = 254;

int bufferSize = 300;
int[] bluetoothBuffer = new int[300];
int bluetoothBufferCursor = 0;


import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;
import g4p_controls.*;
ControlDevice cont;
ControlIO control;

float brushVel, count;
int door = 0;

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
  serialPort = new Serial(this, Serial.list()[0], 9600);
  //serialPort.bufferUntil(254);
  println("Serial connected");

  control = ControlIO.getInstance(this);
  cont = control.getMatchedDevice("xBoxController");

  //Checks if controller is connected
  if (cont == null) {
    println("No device found");
    System.exit(-1);
  } else {
    println("Controller detected, ready.");
  }

  PImage img;
  img = loadImage("bg.png");
  background(img);

  fill(0,0,255);
  ellipse(150, 825, 80, 80);

  brushVel = 0;
}

void draw() {
  getUserInput();
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
      //println("test1");
      serialPort.write(coord[sendByte]);
      //serialPort.write(0x00);
      println(coord[sendByte]);
    }
  }

  void drawRover(float UWBxPos, float UWByPos) {
    //map UWB data to pixel coords
    xpos = map(UWBxPos, 2, 5, 0, 983);
    ypos = map(UWByPos, 5, 8, 906, 0);

    PImage img;
    img = loadImage("bg.png");
    background(img);
    fill(0,0,255);
    ellipse(xpos, ypos, 80, 80);
  }
}

public void getUserInput() {
  int moveX = int(map(cont.getSlider("forward").getValue(), 1, -1, 0, moveMap));
  int moveY = int(map(cont.getSlider("turn").getValue(), -1, 1, 0, moveMap));
  int armVel = int(map(cont.getSlider("arm").getValue(), -1, 1, 0, armMap));
  int brushAccel = int(map(cont.getSlider("brush").getValue(), 1, -1, 0, brushMap));

  //debounce door button input
  if (count < 2) {
    count++;
  } else if (cont.getButton("door").pressed()) {
    count = 0;
    if (door == 0) {
      door = 255;
    } else {
      door = 0;
    }
  }

  //Deadzones
  if (abs(moveX - 127) <= moveXDeadZone) {
    moveX = 127;
  }
  if (abs(moveY - 127) <= moveYDeadZone) {
    moveY = 127;
  }
  if (abs(armVel - 127) <= armVelDeadZone) {
    armVel = 127;
  }
  if (abs(brushAccel - 127) <= brushAccelDeadZone) {
    brushAccel = 127;
  }
  rover.update(moveX, moveY, armVel, brushAccel, door);
  println("test");
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
