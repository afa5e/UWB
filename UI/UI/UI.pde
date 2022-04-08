import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;
import g4p_controls.*;
ControlDevice cont;
ControlIO control;

float brushVel, count;
boolean Door;

Rover rover = new Rover(150, 825);

public void setup() {
  surface.setTitle("Mars Rover");
  size(983,906);
  frameRate(60);

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
  void update(float xvel, float yvel, float brushAccel) {
    xpos = xpos + xvel;
    ypos = ypos + yvel;

    brushVel = brushVel + brushAccel;

    //Arm motors may need position/velocity data depending on controller

    PImage img;
    img = loadImage("bg.png");
    background(img);
    fill(0,0,255);
    ellipse(xpos, ypos, 80, 80);
  }
}

public void getUserInput() {
  float moveX = map(cont.getSlider("MovX").getValue(), -1, 1, -5, 5);
  float moveY = map(cont.getSlider("MovY").getValue(), -1, 1, -5, 5);
  float armVel = map(cont.getSlider("Arm").getValue(), -1, 1, 10, -10);
  float brushAccel = map(cont.getSlider("Brush").getValue(), -1, 1, -10, 10);
  //debounce button input
  if (count < 15) {
    count++;
  } else if (cont.getButton("Door").pressed()) {
    count = 0;
    Door = !Door;
  }

  //Deadzones
  if (abs(moveX) < 0.2) {
    moveX = 0;
  }
  if (abs(moveY) < 0.5) {
    moveY = 0;
  }
  if (abs(armVel) < 0.7) {
    armVel = 0;
  }
  if (abs(brushAccel) < 0.0005) {
    brushAccel = 0;
  }

  rover.update(moveX, moveY, brushAccel);
}
