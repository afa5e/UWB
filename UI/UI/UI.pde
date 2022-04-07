import processing.serial.*;
Serial serialPort;

int serialData = 0;

Rover rover = new Rover(150, 825);

void setup() {
  size(983,906);
  frameRate(60);

  printArray(Serial.list());
  serialPort = new Serial(this, Serial.list()[0], 9600);
  serialPort.bufferUntil(0xFE);

  PImage img;
  img = loadImage("bg.png");
  background(img);

  fill(0,0,255);
  ellipse(150, 825, 80, 80);
}

void draw() {

}

class Rover {
  float xpos, ypos;
  Rover (float x, float y) {
    xpos = x;
    ypos = y;
  }
  void update(float xvel, float yvel) {
    xpos = xpos + xvel;
    ypos = ypos + yvel;
    PImage img;
    img = loadImage("bg.png");
    background(img);
    fill(0,0,255);
    ellipse(xpos, ypos, 80, 80);
  }
}

void keyPressed() {
  float x, y;

  x = 0;
  y = 0;

  if (key == 'w') {
    //Forward 0xEE
    serialPort.write(0x);
    y = -1;
  } else if (key == 's') {
    //Back 0xEF
    serialPort.write(0x);
    y = 1;
  } else if (key == 'a') {
    //Left 0xDE
    serialPort.write(0x);
    x = -1;
  } else if (key == 'd') {
    //Right 0xDF
    serialPort.write(0x);
    x = 1;
  } else if (key == 'd') {
    //Arm Up 0xCE
    serialPort.write(0x);
    x = 1;
  } else if (key == 'd') {
    //Arm Down 0xCF
    serialPort.write(0x);
    x = 1;
  } else if (key == 'd') {
    //Door up 0xBE
    serialPort.write(0x);
    x = 1;
  } else if (key == 'd') {
    //Door down 0xBF
    serialPort.write(0x);
    x = 1;
  } else if (key == 'd') {
    //Brush on 0xAE
    serialPort.write(0x);
    x = 1;
  } else if (key == 'd') {
    //Brush off 0xAF
    serialPort.write(0x);
    x = 1;
  } else {
    println("invalid");
  }
  rover.update(x, y);
}

void serialEvent() {

}
